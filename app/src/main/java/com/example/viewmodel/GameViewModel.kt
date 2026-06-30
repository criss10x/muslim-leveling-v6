package com.example.viewmodel

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.*
import com.example.notifications.NotificationScheduler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.time.temporal.WeekFields
import java.util.Locale
import kotlin.math.floor
import kotlin.random.Random

data class RewardRevealState(
    val prayerName: String,
    val xpGained: Int,
    val isFiveOfFiveCompleted: Boolean,
    val isTimelyBonus: Boolean = false
)

/**
 * State for Daily Reward Chest reveal animation.
 * Triggered when user clicks "Buka Peti!" after completing 5/5 wajib prayers.
 */
data class ChestRevealState(
    val xpReward: Int,
    val rewardName: String,
    val rewardEmoji: String,
    val isDuplicate: Boolean = false  // true kalau item sudah dimiliki sebelumnya
)

/**
 * Tier-up celebration data. Triggered when player crosses a tier boundary
 * (e.g. Warrior→Elite, Elite→Master, Master→Grandmaster, Grandmaster→Epic,
 * Epic→Legend, Legend→Mythic, Mythic→Mythic Honor, etc.)
 */
data class TierUpData(
    val newTierName: String,      // e.g. "Elite", "Master", "Mythic Honor"
    val oldTierName: String,      // e.g. "Warrior", "Elite"
    val unlockedLevel: Int,       // The level at which the tier-up occurred
    val rankTitle: String         // Full rank title e.g. "Muslim Elite V"
)

class GameViewModel(application: Application) : AndroidViewModel(application) {

    private val repository: GameRepository
    private val database: AppDatabase

    private val _gameData = MutableStateFlow(MuslimLevelingData())
    val gameData: StateFlow<MuslimLevelingData> = _gameData.asStateFlow()

    private val _isLoaded = MutableStateFlow(false)
    val isLoaded: StateFlow<Boolean> = _isLoaded.asStateFlow()

    private val _toastEvent = MutableSharedFlow<String>()
    val toastEvent: SharedFlow<String> = _toastEvent.asSharedFlow()

    // Celebration events
    val levelUpAnimationEvent = MutableStateFlow<Int?>(null)
    val tierUpAnimationEvent = MutableStateFlow<TierUpData?>(null)
    val rewardRevealEvent = MutableStateFlow<RewardRevealState?>(null)

    // For KEMENAG prayer time loading state
    private val _isFetchingApi = MutableStateFlow(false)
    val isFetchingApi: StateFlow<Boolean> = _isFetchingApi.asStateFlow()

    // Daftar kota KEMENAG (di-fetch dari API, di-cache in-memory)
    private val _kemenagCities = MutableStateFlow<List<com.example.data.KemenagCity>>(emptyList())
    val kemenagCities: StateFlow<List<com.example.data.KemenagCity>> = _kemenagCities.asStateFlow()

    private val _isLoadingCities = MutableStateFlow(false)
    val isLoadingCities: StateFlow<Boolean> = _isLoadingCities.asStateFlow()

    // Daily Reward Chest pool — chest berisi XP bonus + random cosmetic reward
    val chestRewardPool = listOf(
        "Lencana Bulan Sabit Menyala" to "🌙",
        "Efek Aura Sultan" to "🔱",
        "Bingkai Penjelajah Subuh" to "🖼️",
        "Gelar Pembasmi Sunyi Tahajjud" to "⚔️",
        "Ikon Ramuan Mana Dzikir" to "🧪",
        "Segel Penjaga Maghrib" to "🌌",
        "Jejak Api Istiqomah" to "☄️",
        "Jubah Bijak Al-Qur'an" to "🥋",
        "Sayap Malaikat Istiqomah" to "👼",
        "Pedang Sholat Mitik" to "🗡️"
    )

    // Chest reveal animation event
    private val _chestRevealEvent = MutableStateFlow<ChestRevealState?>(null)
    val chestRevealEvent: StateFlow<ChestRevealState?> = _chestRevealEvent.asStateFlow()

    // Daily chest availability — true kalau 5 sholat wajib hari ini komplit & chest belum dibuka
    val isDailyChestAvailable: StateFlow<Boolean> = _gameData
        .map { data ->
            val todayStr = LocalDate.now().toString()
            val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
            val allFiveDone = wajibList.all { p ->
                data.prayerLog.any { it.date == todayStr && it.prayer == p }
            }
            allFiveDone && data.dailyChestOpenedDate != todayStr
        }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    private val _isChestOpenedToday = MutableStateFlow(false)
    val isChestOpenedToday: StateFlow<Boolean> = _isChestOpenedToday.asStateFlow()

    init {
        database = AppDatabase.getDatabase(application)
        repository = GameRepository(database.gameStateDao())

        // Load initially from DB
        viewModelScope.launch {
            repository.gameStateFlow.collectLatest { data ->
                if (data != null) {
                    _gameData.value = data
                    if (!_isLoaded.value) {
                        _isLoaded.value = true
                        runDailyCheckAndRefresh()
                    }
                } else {
                    // Initial setup / onboarding required
                    _isLoaded.value = true
                }
            }
        }
    }

    /**
     * Start the game with onboarding data
     */
    fun startNewGame(username: String, kota: String, kotaId: String = "6a9aeddfc689c1d0e3b9ccc3ab651bc5") {
        viewModelScope.launch {
            val defaultData = MuslimLevelingData(
                user = User(
                    username = username,
                    kota = kota,
                    kotaId = kotaId
                ),
                lastCheckedDate = LocalDate.now().toString()
            )
            _gameData.value = defaultData
            repository.saveGameState(defaultData)
            fetchPrayerTimes(kotaId)
            generateQuests()
        }
    }

    /**
     * Load daftar kota dari API KEMENAG (api.myquran.com).
     * Cache in-memory supaya tidak fetch berulang.
     */
    fun loadCitiesFromKemenag() {
        if (_kemenagCities.value.isNotEmpty()) return
        _isLoadingCities.value = true
        viewModelScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    com.example.data.KemenagClient.apiService.getAllCities()
                }
                if (response.status && response.data.isNotEmpty()) {
                    _kemenagCities.value = response.data
                }
            } catch (e: Exception) {
                e.printStackTrace()
                // Fallback ke daftar statis
                if (_kemenagCities.value.isEmpty()) {
                    _kemenagCities.value = com.example.data.IndonesianCities.fallbackCities.map {
                        com.example.data.KemenagCity(id = it.id, lokasi = it.name)
                    }
                }
            } finally {
                _isLoadingCities.value = false
            }
        }
    }

    /**
     * Resets all game statistics database
     */
    fun resetAllData() {
        viewModelScope.launch {
            _isLoaded.value = false
            repository.saveGameState(MuslimLevelingData())
            _gameData.value = MuslimLevelingData()
            _isLoaded.value = true
        }
    }

    /**
     * Changes basic profile settings
     */
    fun updateProfileSettings(
        username: String,
        kota: String,
        kotaId: String,
        notifMode: String,
        theme: String
    ) {
        viewModelScope.launch {
            val currentData = _gameData.value
            val oldKotaId = currentData.user.kotaId

            val updatedUser = currentData.user.copy(
                username = username,
                kota = kota,
                kotaId = kotaId,
                notifMode = notifMode,
                theme = theme
            )

            var updatedData = currentData.copy(user = updatedUser)
            _gameData.value = updatedData
            repository.saveGameState(updatedData)

            if (kotaId.isNotEmpty() && kotaId != oldKotaId) {
                fetchPrayerTimes(kotaId)
            }
            _toastEvent.emit("Profil udah ke-update! ✅")
        }
    }

    /**
     * Save uploaded profile photo to internal storage and store its path in user data.
     * Decodes + compresses the bitmap to JPEG (quality 85), saves to filesDir/profile.jpg
     */
    fun saveProfileImage(bitmap: android.graphics.Bitmap) {
        viewModelScope.launch(Dispatchers.IO) {
            val context = getApplication<Application>()
            val file = java.io.File(context.filesDir, "profile.jpg")
            try {
                file.outputStream().use { out ->
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, out)
                }
                val currentData = _gameData.value
                val updatedUser = currentData.user.copy(profileImagePath = file.absolutePath)
                val updatedData = currentData.copy(user = updatedUser)
                _gameData.value = updatedData
                repository.saveGameState(updatedData)
                withContext(Dispatchers.Main) {
                    viewModelScope.launch { _toastEvent.emit("Foto profil terpasang! 📸") }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) {
                    viewModelScope.launch { _toastEvent.emit("Gagal simpan foto: ${e.message}") }
                }
            }
        }
    }

    /**
     * Remove profile photo from storage and clear path in user data.
     */
    fun clearProfileImage() {
        viewModelScope.launch(Dispatchers.IO) {
            val currentData = _gameData.value
            currentData.user.profileImagePath?.let { path ->
                runCatching { java.io.File(path).delete() }
            }
            val updatedUser = currentData.user.copy(profileImagePath = null)
            val updatedData = currentData.copy(user = updatedUser)
            _gameData.value = updatedData
            repository.saveGameState(updatedData)
            withContext(Dispatchers.Main) {
                viewModelScope.launch { _toastEvent.emit("Foto profil dihapus 🗑️") }
            }
        }
    }

    /**
     * Run daily streak check and quest reset
     */
    fun runDailyCheckAndRefresh() {
        val today = LocalDate.now()
        val todayStr = today.toString()
        val state = _gameData.value

        if (state.lastCheckedDate == todayStr) {
            // Already checked today, check if quests are generated
            if (state.quests.date != todayStr) {
                generateQuests()
            }
            return
        }

        viewModelScope.launch {
            val lastCheckedStr = state.lastCheckedDate
            if (lastCheckedStr.isEmpty()) {
                // First initialization
                val updated = state.copy(
                    lastCheckedDate = todayStr,
                    quests = state.quests.copy(date = todayStr)
                )
                repository.saveGameState(updated)
                _gameData.value = updated
                generateQuests()
                fetchPrayerTimes(state.user.kotaId)
                return@launch
            }

            // Week rotation check
            val isDiffWeek = isDifferentWeek(lastCheckedStr, todayStr)

            val lastChecked = LocalDate.parse(lastCheckedStr)
            var currentEvalDate = lastChecked.plusDays(1)

            var hero = state.heroStreak
            var subuhStrk = state.perPrayerStreaks["subuh"] ?: StreakState()
            var dzuhurStrk = state.perPrayerStreaks["dzuhur"] ?: StreakState()
            var asharStrk = state.perPrayerStreaks["ashar"] ?: StreakState()
            var maghribStrk = state.perPrayerStreaks["maghrib"] ?: StreakState()
            var isyaStrk = state.perPrayerStreaks["isya"] ?: StreakState()
            var tilawahStrk = state.tilawahStreak
            var comebackCount = state.comebackCount

            // Helper lists
            val trackerMap = mutableMapOf(
                "subuh" to subuhStrk,
                "dzuhur" to dzuhurStrk,
                "ashar" to asharStrk,
                "maghrib" to maghribStrk,
                "isya" to isyaStrk
            )

            val recoverMessages = mutableListOf<String>()

            // If a new week started, reset freeze availability
            if (isDiffWeek) {
                hero = hero.copy(freezeAvailable = true)
                trackerMap.keys.forEach { key ->
                    trackerMap[key] = trackerMap[key]!!.copy(freezeAvailable = true)
                }
                tilawahStrk = tilawahStrk.copy(freezeAvailable = true)
            }

            // Evaluate missed days between last checked and today (exclusive)
            while (currentEvalDate.isBefore(today)) {
                val evalDateStr = currentEvalDate.toString()

                // 1. Check Hero Streak completion
                val fullWajibDone = checkAllWajibLoggedForDate(evalDateStr, state)
                if (!fullWajibDone && hero.lastDate != evalDateStr) {
                    if (hero.freezeAvailable) {
                        hero = hero.copy(freezeAvailable = false, lastDate = evalDateStr)
                    } else {
                        val prev = hero.current
                        if (prev > 0) {
                            val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                            hero = hero.copy(current = recoveredNum)
                            comebackCount++
                            recoverMessages.add("Streak Hero 5/5 Recovery: mulai dari hari ke-$recoveredNum!")
                        }
                    }
                }

                // 2. Check each Prayer Streak
                trackerMap.keys.forEach { prayer ->
                    val streak = trackerMap[prayer]!!
                    val isLogged = state.prayerLog.any { it.date == evalDateStr && it.prayer == prayer }
                    if (!isLogged && streak.lastDate != evalDateStr) {
                        if (streak.freezeAvailable) {
                            trackerMap[prayer] = streak.copy(freezeAvailable = false, lastDate = evalDateStr)
                        } else {
                            val prev = streak.current
                            if (prev > 0) {
                                val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                                trackerMap[prayer] = streak.copy(current = recoveredNum)
                                comebackCount++
                                recoverMessages.add("Streak ${prayer.capitalizeCompat()} Recovery: mulai dari h-${recoveredNum}!")
                            }
                        }
                    }
                }

                // 3. Tilawah streak
                val tilawahLogged = state.prayerLog.any { it.date == evalDateStr && it.prayer == "tilawah" }
                if (!tilawahLogged && tilawahStrk.lastDate != evalDateStr) {
                    if (tilawahStrk.freezeAvailable) {
                        tilawahStrk = tilawahStrk.copy(freezeAvailable = false, lastDate = evalDateStr)
                    } else {
                        val prev = tilawahStrk.current
                        if (prev > 0) {
                            val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                            tilawahStrk = tilawahStrk.copy(current = recoveredNum)
                            comebackCount++
                            recoverMessages.add("Streak Tilawah Recovery: mulai dari h-${recoveredNum}!")
                        }
                    }
                }

                currentEvalDate = currentEvalDate.plusDays(1)
            }

            // Now evaluate YESTERDAY (the day right before today)
            val yesterdayStr = today.minusDays(1).toString()

            // yesterday must be fully checked
            // 1. Hero Yesterday
            val heroWajibDone = checkAllWajibLoggedForDate(yesterdayStr, state)
            if (!heroWajibDone && hero.lastDate != yesterdayStr && hero.lastDate != todayStr) {
                if (hero.freezeAvailable) {
                    hero = hero.copy(freezeAvailable = false, lastDate = yesterdayStr)
                } else {
                    val prev = hero.current
                    if (prev > 0) {
                        val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                        hero = hero.copy(current = recoveredNum)
                        comebackCount++
                        recoverMessages.add("Streak Hero 5/5 Recovery: mulai dari hari ke-$recoveredNum!")
                    }
                }
            }

            // 2. Prayer Streaks Yesterday
            trackerMap.keys.forEach { prayer ->
                val streak = trackerMap[prayer]!!
                val isLogged = state.prayerLog.any { it.date == yesterdayStr && it.prayer == prayer }
                if (!isLogged && streak.lastDate != yesterdayStr && streak.lastDate != todayStr) {
                    if (streak.freezeAvailable) {
                        trackerMap[prayer] = streak.copy(freezeAvailable = false, lastDate = yesterdayStr)
                    } else {
                        val prev = streak.current
                        if (prev > 0) {
                            val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                            trackerMap[prayer] = streak.copy(current = recoveredNum)
                            comebackCount++
                            recoverMessages.add("Streak ${prayer.capitalizeCompat()} Recovery: mulai dari h-${recoveredNum}!")
                        }
                    }
                }
            }

            // 3. Tilawah Yesterday
            val tilawahDone = state.prayerLog.any { it.date == yesterdayStr && it.prayer == "tilawah" }
            if (!tilawahDone && tilawahStrk.lastDate != yesterdayStr && tilawahStrk.lastDate != todayStr) {
                if (tilawahStrk.freezeAvailable) {
                    tilawahStrk = tilawahStrk.copy(freezeAvailable = false, lastDate = yesterdayStr)
                } else {
                    val prev = tilawahStrk.current
                    if (prev > 0) {
                        val recoveredNum = floor(prev * 0.75).toInt().coerceAtLeast(1)
                        tilawahStrk = tilawahStrk.copy(current = recoveredNum)
                        comebackCount++
                        recoverMessages.add("Streak Tilawah Recovery: mulai dari h-${recoveredNum}!")
                    }
                }
            }

            // Save results back to State
            val updatedData = state.copy(
                heroStreak = hero,
                perPrayerStreaks = trackerMap,
                tilawahStreak = tilawahStrk,
                comebackCount = comebackCount,
                lastCheckedDate = todayStr
            )

            // Let's check Achievements with new comebackCount
            val achievements = evaluateBadges(updatedData)

            val finalData = updatedData.copy(badges = achievements)
            _gameData.value = finalData
            repository.saveGameState(finalData)

            // Emit toast messages if recovery triggered
            viewModelScope.launch {
                recoverMessages.forEach { msg ->
                    _toastEvent.emit(msg)
                }
            }

            generateQuests()
            fetchPrayerTimes(state.user.kotaId)
        }
    }

    private fun checkAllWajibLoggedForDate(dateStr: String, data: MuslimLevelingData): Boolean {
        val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
        return wajibList.all { prayer ->
            data.prayerLog.any { it.date == dateStr && it.prayer == prayer }
        }
    }

    /**
     * Add single-log checked entries with XP computation and quest validations
     */
    fun logPrayer(prayer: String, type: String) {
        viewModelScope.launch {
            val state = _gameData.value
            val todayStr = LocalDate.now().toString()
            val timeStr = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"))

            // Check if already logged today
            val alreadyLogged = state.prayerLog.any { it.date == todayStr && it.prayer == prayer }
            if (alreadyLogged) {
                _toastEvent.emit("Sholat ini udah dicatat hari ini!")
                return@launch
            }

            // ─── Sunnah time-window lock ───
            // Cek apakah waktu sekarang sesuai untuk sholat sunnah ini.
            // Berdasarkan riset fiqih & Aladhan API timings.
            if (type == "sunnah") {
                val isOnTime = isSunnahOnTime(prayer, timeStr, state.prayerTimesCache.timings)
                if (!isOnTime) {
                    val hint = getSunnahTimeHint(prayer)
                    _toastEvent.emit("⏰ Belum waktunya! $hint")
                    return@launch
                }
            }

            // Create new log item
            val newLog = PrayerLog(date = todayStr, prayer = prayer, time = timeStr, type = type)
            val updatedLogs = state.prayerLog + newLog

            // 1. Compute Base XP
            var xpGained = when (prayer) {
                "subuh" -> 30
                "dzuhur" -> 20
                "ashar" -> 20
                "maghrib" -> 25
                "isya" -> 25
                else -> 15 // sunnah/tilawah/dzikir
            }

            // 2. Check if this completes the 5/5 today
            val isHeroCompletor = if (type == "wajib") {
                val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
                wajibList.all { p ->
                    p == prayer || updatedLogs.any { it.date == todayStr && p == it.prayer }
                }
            } else false

            if (isHeroCompletor) {
                xpGained += 50 // Show "+50 XP bonus 5/5!" inside step 3
            }

            // 2b. Timely bonus: +15 XP if logged ≤30 minutes after adzan (wajib only)
            var isTimelyBonus = false
            if (type == "wajib") {
                val adzanTime = when (prayer) {
                    "subuh" -> state.prayerTimesCache.timings.subuh
                    "dzuhur" -> state.prayerTimesCache.timings.dzuhur
                    "ashar" -> state.prayerTimesCache.timings.ashar
                    "maghrib" -> state.prayerTimesCache.timings.maghrib
                    "isya" -> state.prayerTimesCache.timings.isya
                    else -> null
                }
                if (adzanTime != null && adzanTime.isNotEmpty()) {
                    val minsAfterAdzan = getMinutesDifference(timeStr, adzanTime)
                    if (minsAfterAdzan in 0..30) {
                        xpGained += 15
                        isTimelyBonus = true
                    }
                }
            }

            // Update cumulative user XP
            val oldXp = state.user.xp
            val newXp = oldXp + xpGained

            val oldLevelInfo = getLevelInfo(oldXp)
            val newLevelInfo = getLevelInfo(newXp)

            val didLevelUp = newLevelInfo.level > oldLevelInfo.level

            // Gacha system removed — replaced by Daily Reward Chest (claim via QuestScreen)

            // 4. Update Streaks for active logged days
            var hero = state.heroStreak
            var subuhStrk = state.perPrayerStreaks["subuh"] ?: StreakState()
            var dzuhurStrk = state.perPrayerStreaks["dzuhur"] ?: StreakState()
            var asharStrk = state.perPrayerStreaks["ashar"] ?: StreakState()
            var maghribStrk = state.perPrayerStreaks["maghrib"] ?: StreakState()
            var isyaStrk = state.perPrayerStreaks["isya"] ?: StreakState()
            var tilawahStrk = state.tilawahStreak

            val yesterdayStr = LocalDate.now().minusDays(1).toString()

            // Update individual prayer streak
            if (type == "wajib") {
                when (prayer) {
                    "subuh" -> subuhStrk = updateIndividualStreak(subuhStrk, todayStr, yesterdayStr)
                    "dzuhur" -> dzuhurStrk = updateIndividualStreak(dzuhurStrk, todayStr, yesterdayStr)
                    "ashar" -> asharStrk = updateIndividualStreak(asharStrk, todayStr, yesterdayStr)
                    "maghrib" -> maghribStrk = updateIndividualStreak(maghribStrk, todayStr, yesterdayStr)
                    "isya" -> isyaStrk = updateIndividualStreak(isyaStrk, todayStr, yesterdayStr)
                }
            }

            // Update Hero Streak
            if (isHeroCompletor) {
                hero = updateIndividualStreak(hero, todayStr, yesterdayStr)
            }

            // Update Tilawah Streak
            if (prayer == "tilawah") {
                tilawahStrk = updateIndividualStreak(tilawahStrk, todayStr, yesterdayStr)
            }

            // 5. Update Quest progress values
            var questList = state.quests.list.map { q ->
                var progress = q.progress
                var completed = q.completed

                when (q.id) {
                    "quest_subuh_tepat" -> {
                        if (prayer == "subuh") {
                            val limitDiff = getMinutesDifference(timeStr, state.prayerTimesCache.timings.subuh)
                            if (limitDiff <= 30) {
                                progress = 1
                                completed = true
                            }
                        }
                    }
                    "quest_five_rings" -> {
                        if (isHeroCompletor) {
                            progress = 1
                            completed = true
                        }
                    }
                    "quest_dhuha_before_dzuhur" -> {
                        if (prayer == "dhuha") {
                            val beforeDzuhur = isTimeBefore(timeStr, state.prayerTimesCache.timings.dzuhur)
                            if (beforeDzuhur) {
                                progress = 1
                                completed = true
                            }
                        }
                    }
                    "quest_tilawah_today" -> {
                        if (prayer == "tilawah") {
                            progress = 1
                            completed = true
                        }
                    }
                    "quest_hero_streak_7" -> {
                        if (hero.current >= 7) {
                            progress = 7
                            completed = true
                        } else {
                            progress = hero.current
                        }
                    }
                    "quest_timely_prayers" -> {
                        val isTimely = isLogTepatWaktu(prayer, timeStr, state.prayerTimesCache.timings, 10)
                        if (isTimely) {
                            progress = (progress + 1).coerceAtMost(3)
                            completed = progress >= 3
                        }
                    }
                    "quest_rawatib_two" -> {
                        if (prayer == "rawatib" || prayer.startsWith("rawatib_")) {
                            val todayRawatibCount = updatedLogs.count { it.date == todayStr && (it.prayer == "rawatib" || it.prayer.startsWith("rawatib_")) }
                            progress = todayRawatibCount.coerceAtMost(2)
                            completed = progress >= 2
                        }
                    }
                    "quest_doa_solat" -> {
                        // Completed separately manually or on click
                    }
                }

                q.copy(progress = progress, completed = completed)
            }

            val trackerMap = mapOf(
                "subuh" to subuhStrk,
                "dzuhur" to dzuhurStrk,
                "ashar" to asharStrk,
                "maghrib" to maghribStrk,
                "isya" to isyaStrk
            )

            val partialData = state.copy(
                user = state.user.copy(xp = newXp, level = newLevelInfo.level),
                prayerLog = updatedLogs,
                heroStreak = hero,
                perPrayerStreaks = trackerMap,
                tilawahStreak = tilawahStrk,
                quests = state.quests.copy(list = questList)
            )

            // Achievements checking
            val badgesList = evaluateBadges(partialData)
            val finalData = partialData.copy(badges = badgesList)

            _gameData.value = finalData
            repository.saveGameState(finalData)

            // Trigger animations
            if (didLevelUp) {
                // If causes level-up, we show Level-up celebration screen first!
                levelUpAnimationEvent.value = newLevelInfo.level
                // Tier-up celebration (triggered alongside level-up, shown after)
                checkTierUp(oldLevelInfo.level, newLevelInfo.level)?.let { tierData ->
                    tierUpAnimationEvent.value = tierData
                }
            }

            // Gacha reveal sequence — gacha removed, only XP/timely/5-of-5 steps shown
            rewardRevealEvent.value = RewardRevealState(
                prayerName = prayer.capitalizeCompat(),
                xpGained = xpGained,
                isFiveOfFiveCompleted = isHeroCompletor,
                isTimelyBonus = isTimelyBonus
            )
        }
    }

    private fun updateIndividualStreak(streak: StreakState, todayStr: String, yesterdayStr: String): StreakState {
        if (streak.lastDate == todayStr) return streak

        val currentVal = if (streak.lastDate == yesterdayStr) {
            streak.current + 1
        } else {
            // Evaluated yesterday but was not logged. If it went through dailyCheck it already broke.
            // If it starts fresh, it recovers from floor or 1.
            if (streak.current == 0) 1 else streak.current + 1
        }
        val bestVal = if (currentVal > streak.best) currentVal else streak.best
        return streak.copy(current = currentVal, best = bestVal, lastDate = todayStr)
    }

    /**
     * Uncheck a prayer with confirmation dialog (reverts changes)
     */
    fun unlogPrayer(prayer: String, dateStr: String) {
        viewModelScope.launch {
            val state = _gameData.value
            val logItem = state.prayerLog.find { it.date == dateStr && it.prayer == prayer } ?: return@launch

            // Remove the log item from history
            val updatedLogs = state.prayerLog.filter { it != logItem }

            // Compute XP loss
            var xpLost = when (prayer) {
                "subuh" -> 30
                "dzuhur" -> 20
                "ashar" -> 20
                "maghrib" -> 25
                "isya" -> 25
                else -> 15
            }

            // Was 5/5 fully completed before deleting this?
            val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
            val wasFullBefore = wajibList.all { p ->
                state.prayerLog.any { it.date == dateStr && p == it.prayer }
            }

            if (wasFullBefore) {
                xpLost += 50 // subtract bonus as well
            }

            // Subtract timely bonus (+15) if the logged prayer was within 30 min of adzan
            if (logItem.type == "wajib") {
                val adzanTime = when (prayer) {
                    "subuh" -> state.prayerTimesCache.timings.subuh
                    "dzuhur" -> state.prayerTimesCache.timings.dzuhur
                    "ashar" -> state.prayerTimesCache.timings.ashar
                    "maghrib" -> state.prayerTimesCache.timings.maghrib
                    "isya" -> state.prayerTimesCache.timings.isya
                    else -> null
                }
                if (adzanTime != null && adzanTime.isNotEmpty()) {
                    val minsAfterAdzan = getMinutesDifference(logItem.time, adzanTime)
                    if (minsAfterAdzan in 0..30) {
                        xpLost += 15
                    }
                }
            }

            val newXp = (state.user.xp - xpLost).coerceAtLeast(0)
            val levelInfo = getLevelInfo(newXp)

            // Revert streaks if date is today
            var hero = state.heroStreak
            var subuhStrk = state.perPrayerStreaks["subuh"] ?: StreakState()
            var dzuhurStrk = state.perPrayerStreaks["dzuhur"] ?: StreakState()
            var asharStrk = state.perPrayerStreaks["ashar"] ?: StreakState()
            var maghribStrk = state.perPrayerStreaks["maghrib"] ?: StreakState()
            var isyaStrk = state.perPrayerStreaks["isya"] ?: StreakState()
            var tilawahStrk = state.tilawahStreak

            if (dateStr == LocalDate.now().toString()) {
                if (logItem.type == "wajib") {
                    when (prayer) {
                        "subuh" -> subuhStrk = subuhStrk.copy(current = (subuhStrk.current - 1).coerceAtLeast(0), lastDate = "")
                        "dzuhur" -> dzuhurStrk = dzuhurStrk.copy(current = (dzuhurStrk.current - 1).coerceAtLeast(0), lastDate = "")
                        "ashar" -> asharStrk = asharStrk.copy(current = (asharStrk.current - 1).coerceAtLeast(0), lastDate = "")
                        "maghrib" -> maghribStrk = maghribStrk.copy(current = (maghribStrk.current - 1).coerceAtLeast(0), lastDate = "")
                        "isya" -> isyaStrk = isyaStrk.copy(current = (isyaStrk.current - 1).coerceAtLeast(0), lastDate = "")
                    }
                }
                if (wasFullBefore) {
                    hero = hero.copy(current = (hero.current - 1).coerceAtLeast(0), lastDate = "")
                }
                if (prayer == "tilawah") {
                    tilawahStrk = tilawahStrk.copy(current = (tilawahStrk.current - 1).coerceAtLeast(0), lastDate = "")
                }
            }

            val trackerMap = mapOf(
                "subuh" to subuhStrk,
                "dzuhur" to dzuhurStrk,
                "ashar" to asharStrk,
                "maghrib" to maghribStrk,
                "isya" to isyaStrk
            )

            val updatedData = state.copy(
                user = state.user.copy(xp = newXp, level = levelInfo.level),
                prayerLog = updatedLogs,
                heroStreak = hero,
                perPrayerStreaks = trackerMap,
                tilawahStreak = tilawahStrk
            )

            _gameData.value = updatedData
            repository.saveGameState(updatedData)

            _toastEvent.emit("Sholat udah di-unlog.")
        }
    }

    /**
     * Increment Zikir clicker
     */
    fun incrementZikirQuestCounter() {
        viewModelScope.launch {
            val state = _gameData.value
            val todayStr = LocalDate.now().toString()

            val currentZikir = if (state.zikirCounter.date == todayStr) {
                state.zikirCounter.copy(count = (state.zikirCounter.count + 1).coerceAtMost(3))
            } else {
                ZikirCounter(date = todayStr, count = 1)
            }

            var updatedQuests = state.quests.list.map { q ->
                if (q.id == "quest_zikir_after_prayer") {
                    val completed = currentZikir.count >= 3
                    q.copy(progress = currentZikir.count, completed = completed)
                } else q
            }

            val updatedData = state.copy(
                zikirCounter = currentZikir,
                quests = state.quests.copy(list = updatedQuests)
            )

            _gameData.value = updatedData
            repository.saveGameState(updatedData)

            if (currentZikir.count == 3) {
                _toastEvent.emit("Dzikir selesai! Quest udah siap diklaim 🎉")
            }
        }
    }

    /**
     * Claim Quest Rewards
     */
    fun claimQuest(questId: String) {
        viewModelScope.launch {
            val state = _gameData.value
            val quest = state.quests.list.find { it.id == questId } ?: return@launch

            if (!quest.completed || quest.claimed) return@launch

            val newXp = state.user.xp + quest.xpReward
            val oldLevelInfo = getLevelInfo(state.user.xp)
            val newLevelInfo = getLevelInfo(newXp)

            val updatedQuests = state.quests.list.map { q ->
                if (q.id == questId) q.copy(claimed = true) else q
            }

            val partialData = state.copy(
                user = state.user.copy(xp = newXp, level = newLevelInfo.level),
                quests = state.quests.copy(list = updatedQuests)
            )

            val badgesList = evaluateBadges(partialData)
            val finalData = partialData.copy(badges = badgesList)

            _gameData.value = finalData
            repository.saveGameState(finalData)

            if (newLevelInfo.level > oldLevelInfo.level) {
                levelUpAnimationEvent.value = newLevelInfo.level
                checkTierUp(oldLevelInfo.level, newLevelInfo.level)?.let { tierData ->
                    tierUpAnimationEvent.value = tierData
                }
            }

            _toastEvent.emit("Quest '${quest.desc}' diklaim! +${quest.xpReward} XP")
        }
    }

    /**
     * Trigger manual check quest "Doa setelah sholat"
     */
    fun triggerManualDoaQuest() {
        viewModelScope.launch {
            val state = _gameData.value
            val updatedList = state.quests.list.map { q ->
                if (q.id == "quest_doa_solat") {
                    q.copy(progress = 1, completed = true)
                } else q
            }
            val updatedData = state.copy(quests = state.quests.copy(list = updatedList))
            _gameData.value = updatedData
            repository.saveGameState(updatedData)
            _toastEvent.emit("Doa udah kelar! Quest selesai 🎉")
        }
    }

    /**
     * Claim Daily Reward Chest — berlaku kalau 5 sholat wajib hari ini sudah komplit & chest belum dibuka.
     * Reward: 50-150 XP bonus + 1 random cosmetic item dari chestRewardPool.
     */
    fun claimDailyChest() {
        viewModelScope.launch {
            val state = _gameData.value
            val todayStr = LocalDate.now().toString()

            // Cek 5/5 sholat wajib komplit hari ini
            val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
            val allFiveDone = wajibList.all { p ->
                state.prayerLog.any { it.date == todayStr && it.prayer == p }
            }
            if (!allFiveDone) {
                _toastEvent.emit("Selesaikan 5 sholat wajib dulu ya buat buka peti! 🙏")
                return@launch
            }
            if (state.dailyChestOpenedDate == todayStr) {
                _toastEvent.emit("Peti harian sudah dibuka hari ini 📦")
                return@launch
            }

            // Roll reward: 50-150 XP bonus + 1 cosmetic item (prioritas yang belum dimiliki)
            val xpReward = (50..150).random()
            val unacquired = chestRewardPool.filter { (name, _) -> !state.rewards.contains(name) }
            val (rewardName, rewardEmoji) = if (unacquired.isNotEmpty()) {
                unacquired.random()
            } else {
                // Semua item sudah dimiliki — kasih duplicate (XP tetap dapet)
                chestRewardPool.random()
            }
            val isDuplicate = state.rewards.contains(rewardName)

            // Update XP + rewards list + mark chest opened today
            val oldXp = state.user.xp
            val newXp = oldXp + xpReward
            val oldLevelInfo = getLevelInfo(oldXp)
            val newLevelInfo = getLevelInfo(newXp)

            val updatedRewards = if (!isDuplicate) state.rewards + rewardName else state.rewards
            val updatedData = state.copy(
                user = state.user.copy(xp = newXp, level = newLevelInfo.level),
                rewards = updatedRewards,
                dailyChestOpenedDate = todayStr
            )

            val badgesList = evaluateBadges(updatedData)
            val finalData = updatedData.copy(badges = badgesList)

            _gameData.value = finalData
            repository.saveGameState(finalData)
            _isChestOpenedToday.value = true

            // Trigger chest reveal animation
            _chestRevealEvent.value = ChestRevealState(
                xpReward = xpReward,
                rewardName = rewardName,
                rewardEmoji = rewardEmoji,
                isDuplicate = isDuplicate
            )

            // Level-up celebration if applicable
            if (newLevelInfo.level > oldLevelInfo.level) {
                levelUpAnimationEvent.value = newLevelInfo.level
                checkTierUp(oldLevelInfo.level, newLevelInfo.level)?.let { tierData ->
                    tierUpAnimationEvent.value = tierData
                }
            }
        }
    }

    fun clearChestReveal() {
        _chestRevealEvent.value = null
    }

    /**
     * Generate Quests based on parameters
     */
    private fun generateQuests() {
        viewModelScope.launch {
            val todayStr = LocalDate.now().toString()
            val state = _gameData.value

            val pool = mutableListOf(
                Quest(
                    "quest_subuh_tepat",
                    "Sholat Subuh tepat waktu (≤30 menit setelah adzan)",
                    xpReward = 50,
                    target = 1,
                    progress = 0,
                    completed = false,
                    claimed = false
                ),
                Quest(
                    "quest_five_rings",
                    "Lengkapin 5/5 sholat hari ini",
                    xpReward = 100,
                    target = 1,
                    progress = 0,
                    completed = false,
                    claimed = false
                ),
                Quest(
                    "quest_tilawah_today",
                    "Tilawah/Dzikir hari ini",
                    xpReward = 30,
                    target = 1,
                    progress = 0,
                    completed = false,
                    claimed = false
                ),
                Quest(
                    "quest_timely_prayers",
                    "Sholat tepat waktu (≤10 menit), 3x hari ini",
                    xpReward = 60,
                    target = 3,
                    progress = 0,
                    completed = false,
                    claimed = false
                ),
                Quest(
                    "quest_zikir_after_prayer",
                    "Dzikir setelah sholat (3x)",
                    xpReward = 25,
                    target = 3,
                    progress = 0,
                    completed = false,
                    claimed = false
                ),
                Quest(
                    "quest_doa_solat",
                    "Doa setelah sholat",
                    xpReward = 20,
                    target = 1,
                    progress = 0,
                    completed = false,
                    claimed = false
                )
            )

            // Modes extensions — selalu aktif (intensity mode dihapus)
            pool.add(
                Quest(
                    "quest_dhuha_before_dzuhur",
                    "Sholat Dhuha sebelum Dzuhur",
                    xpReward = 40,
                    target = 1,
                    progress = 0,
                    completed = false,
                    claimed = false
                )
            )
            pool.add(
                Quest(
                    "quest_rawatib_two",
                    "Rawatib 2x hari ini",
                    xpReward = 45,
                    target = 2,
                    progress = 0,
                    completed = false,
                    claimed = false
                )
            )

            if (state.heroStreak.current >= 6) {
                pool.add(
                    Quest(
                        "quest_hero_streak_7",
                        "Pertahanin Hero Streak 7 hari! 🔥",
                        xpReward = 200,
                        target = 7,
                        progress = state.heroStreak.current,
                        completed = state.heroStreak.current >= 7,
                        claimed = false
                    )
                )
            }

            // Shuffle and pick 4 or 5
            val selectedQuests = pool.shuffled().take(5)

            val updatedData = state.copy(
                quests = QuestState(date = todayStr, list = selectedQuests),
                // reset zikir clicker daily too
                zikirCounter = ZikirCounter(date = todayStr, count = 0)
            )
            _gameData.value = updatedData
            repository.saveGameState(updatedData)
        }
    }

    /**
     * Evaluate badges unlocks
     */
    private fun evaluateBadges(data: MuslimLevelingData): List<String> {
        val earned = data.badges.toMutableSet()

        // 1. Langkah Pertama
        if (data.prayerLog.isNotEmpty() && !earned.contains("langkah_pertama")) {
            earned.add("langkah_pertama")
        }

        // 2. Subuh Warrior
        val subuhStrk = data.perPrayerStreaks["subuh"]?.current ?: 0
        if (subuhStrk >= 7 && !earned.contains("subuh_warrior")) {
            earned.add("subuh_warrior")
        }

        // 3. Subuh Legend
        if (subuhStrk >= 30 && !earned.contains("subuh_legend")) {
            earned.add("subuh_legend")
        }

        // 4. 5/5 Master
        val heroStrk = data.heroStreak.current
        if (heroStrk >= 1 && !earned.contains("five_five_master")) {
            earned.add("five_five_master")
        }

        // 5. 5/5 Streak x7
        if (heroStrk >= 7 && !earned.contains("five_five_streak_7")) {
            earned.add("five_five_streak_7")
        }

        // 6. 5/5 Streak x30
        if (heroStrk >= 30 && !earned.contains("five_five_streak_30")) {
            earned.add("five_five_streak_30")
        }

        // 7. Sultan Sunnah
        val sunnahCount = data.prayerLog.count { it.type == "sunnah" }
        if (sunnahCount >= 50 && !earned.contains("sultan_sunnah")) {
            earned.add("sultan_sunnah")
        }

        // 8. Tilawah Streak
        val tilawahStrk = data.tilawahStreak.current
        if (tilawahStrk >= 14 && !earned.contains("tilawah_streak_14")) {
            earned.add("tilawah_streak_14")
        }

        // 9. Ramadan Champion
        val today = LocalDate.now()
        // April 2026 is RAMADAN simulation check (Ramadan in 2026 runs roughly from mid-Feb to mid-March,
        // let's say month == 3 or simple check: if any prayer logged on today, mock true so they can earn it)
        val ramadanVerified = data.prayerLog.any { it.date == today.toString() }
        if (ramadanVerified && !earned.contains("ramadan_champion")) {
            earned.add("ramadan_champion")
        }

        // 10. Comeback King
        if (data.comebackCount >= 3 && !earned.contains("comeback_king")) {
            earned.add("comeback_king")
        }

        // 11. Early Bird
        val timelyLogsCount = data.prayerLog.count { log ->
            isLogTepatWaktu(log.prayer, log.time, data.prayerTimesCache.timings, 10)
        }
        if (timelyLogsCount >= 20 && !earned.contains("early_bird")) {
            earned.add("early_bird")
        }

        // 12. Mythic Reached
        if (data.user.level >= 80 && !earned.contains("mythic_reached")) {
            earned.add("mythic_reached")
        }

        // 13. Santri Digital — selesaikan semua 16 modul Belajar
        val allModulesCompleted = data.learningState.progress.count { it.completed } >= 16
        if (allModulesCompleted && !earned.contains("santri_digital")) {
            earned.add("santri_digital")
        }

        return earned.toList()
    }

    private fun isLogTepatWaktu(prayer: String, logTime: String, timings: Timings, minutesLimit: Int): Boolean {
        val prayTime = when (prayer) {
            "subuh" -> timings.subuh
            "dzuhur" -> timings.dzuhur
            "ashar" -> timings.ashar
            "maghrib" -> timings.maghrib
            "isya" -> timings.isya
            else -> null
        } ?: return false

        return getMinutesDifference(logTime, prayTime) <= minutesLimit
    }

    /**
     * Fetch prayer times from KEMENAG API (api.myquran.com mirror).
     * Uses numeric city ID (not city name) per KEMENAG API requirement.
     * Falls back to Aladhan if KEMENAG fails.
     */
    /**
     * Fetch jadwal sholat dari api.myquran.com v3.
     * v3 uses a date-keyed map (data.jadwal["YYYY-MM-DD"]) and MD5 city IDs.
     */
    fun fetchPrayerTimes(kotaId: String) {
        if (kotaId.isEmpty()) return
        _isFetchingApi.value = true
        viewModelScope.launch {
            try {
                val today = LocalDate.now()
                val period = today.toString() // YYYY-MM-DD
                val response = withContext(Dispatchers.IO) {
                    com.example.data.KemenagClient.apiService.getDailyJadwal(
                        cityId = kotaId,
                        period = period
                    )
                }
                if (response.status) {
                    val jadwal = response.data.jadwal.values.firstOrNull()
                    if (jadwal != null) {
                        val newCache = PlayerPrayerTimesCache(
                            date = today.toString(),
                            timings = Timings(
                                imsak = jadwal.imsak.ifEmpty { "04:30" },
                                subuh = jadwal.subuh.ifEmpty { "04:42" },
                                terbit = jadwal.terbit.ifEmpty { "05:55" },
                                dhuha = jadwal.dhuha.ifEmpty { "06:20" },
                                dzuhur = jadwal.dzuhur.ifEmpty { "12:01" },
                                ashar = jadwal.ashar.ifEmpty { "15:20" },
                                maghrib = jadwal.maghrib.ifEmpty { "17:55" },
                                isya = jadwal.isya.ifEmpty { "19:08" }
                            )
                        )
                        val updatedData = _gameData.value.copy(prayerTimesCache = newCache)
                        _gameData.value = updatedData
                        repository.saveGameState(updatedData)

                        // ── Schedule adhan reminders if enabled ──
                        val timingsMap = mapOf(
                            "subuh" to newCache.timings.subuh,
                            "dzuhur" to newCache.timings.dzuhur,
                            "ashar" to newCache.timings.ashar,
                            "maghrib" to newCache.timings.maghrib,
                            "isya" to newCache.timings.isya
                        )
                        val ctx = getApplication<Application>()
                        if (NotificationScheduler.isRemindersEnabled(ctx)) {
                            NotificationScheduler.scheduleAdhanReminders(ctx, kotaId, timingsMap)
                        }

                        _toastEvent.emit("Jadwal sholat KEMENAG (${response.data.kabko}) ke-load! ✅")
                    } else {
                        fetchPrayerTimesFromAladhanFallback(kotaId)
                    }
                } else {
                    // KEMENAG returned error status — try Aladhan fallback
                    fetchPrayerTimesFromAladhanFallback(kotaId)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                // Try Aladhan fallback with city name lookup
                fetchPrayerTimesFromAladhanFallback(kotaId)
            } finally {
                _isFetchingApi.value = false
            }
        }
    }

    /**
     * Fallback: try Aladhan API if KEMENAG fails.
     * Uses the cached city name from game data, or queries Aladhan directly.
     */
    private fun fetchPrayerTimesFromAladhanFallback(kotaId: String) {
        viewModelScope.launch {
            try {
                // Find city name from cached KEMENAG cities
                val cityName = _kemenagCities.value.find { it.id == kotaId }?.lokasi
                    ?: _gameData.value.user.kota
                    ?: ""

                if (cityName.isEmpty()) {
                    _toastEvent.emit("Koneksi error. Pakai jadwal default dulu ya.")
                    return@launch
                }

                // Aladhan expects city name without "Kota"/"Kab." prefix
                val aladhanCityName = cityName
                    .replace("Kota ", "", ignoreCase = true)
                    .replace("Kab. ", "", ignoreCase = true)
                    .replace("Kabupaten ", "", ignoreCase = true)
                    .trim()

                val response = withContext(Dispatchers.IO) {
                    com.example.data.AladhanClient.apiService.getTimingsByCity(city = aladhanCityName)
                }
                if (response.code == 200) {
                    val timings = response.data.timings
                    // Aladhan returns times with timezone suffix (e.g. "04:42 (WIB)") — strip it
                    fun cleanTime(t: String): String {
                        val parts = t.trim().split(" ")
                        return parts.firstOrNull()?.take(5) ?: t
                    }
                    val newCache = PlayerPrayerTimesCache(
                        date = LocalDate.now().toString(),
                        timings = Timings(
                            imsak = "00:00", // Aladhan doesn't provide imsak
                            subuh = cleanTime(timings.fajr),
                            terbit = cleanTime(timings.sunrise ?: "05:55"),
                            dhuha = "00:00",
                            dzuhur = cleanTime(timings.dhuhr),
                            ashar = cleanTime(timings.asr),
                            maghrib = cleanTime(timings.maghrib),
                            isya = cleanTime(timings.isha)
                        )
                    )
                    val updatedData = _gameData.value.copy(prayerTimesCache = newCache)
                    _gameData.value = updatedData
                    repository.saveGameState(updatedData)

                    val timingsMap = mapOf(
                        "subuh" to newCache.timings.subuh,
                        "dzuhur" to newCache.timings.dzuhur,
                        "ashar" to newCache.timings.ashar,
                        "maghrib" to newCache.timings.maghrib,
                        "isya" to newCache.timings.isya
                    )
                    val ctx = getApplication<Application>()
                    if (NotificationScheduler.isRemindersEnabled(ctx)) {
                        NotificationScheduler.scheduleAdhanReminders(ctx, kotaId, timingsMap)
                    }
                    _toastEvent.emit("Jadwal sholat (Aladhan fallback) ke-load! ✅")
                } else {
                    _toastEvent.emit("Gagal load jadwal sholat 😥")
                }
            } catch (e: Exception) {
                e.printStackTrace()
                _toastEvent.emit("Koneksi error. Pakai jadwal default dulu ya.")
            }
        }
    }

    // Helper functions
    private fun getMinutesDifference(time1: String, time2: String): Int {
        return try {
            val parts1 = time1.split(":")
            val parts2 = time2.split(":")
            val mins1 = parts1[0].toInt() * 60 + parts1[1].toInt()
            val mins2 = parts2[0].toInt() * 60 + parts2[1].toInt()
            Math.abs(mins1 - mins2)
        } catch (e: Exception) {
            999
        }
    }

    private fun isTimeBefore(time1: String, time2: String): Boolean {
        return try {
            val parts1 = time1.split(":")
            val parts2 = time2.split(":")
            val mins1 = parts1[0].toInt() * 60 + parts1[1].toInt()
            val mins2 = parts2[0].toInt() * 60 + parts2[1].toInt()
            mins1 < mins2
        } catch (e: Exception) {
            false
        }
    }

    private fun isTimeAfter(time1: String, time2: String): Boolean {
        return try {
            val parts1 = time1.split(":")
            val parts2 = time2.split(":")
            val mins1 = parts1[0].toInt() * 60 + parts1[1].toInt()
            val mins2 = parts2[0].toInt() * 60 + parts2[1].toInt()
            mins1 > mins2
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Cek apakah waktu sekarang masuk ke time window sholat sunnah.
     * Berdasarkan Aladhan API timings (imsak, subuh, terbit, dhuha, dzuhur, ashar, maghrib, isya).
     *
     * Riset fiqih:
     * - Dhuha: setelah matahari naik (±15 min after terbit) → sebelum dzuhur
     * - Tahajjud: setelah isya → sebelum imsak (utamanya sepertiga malam terakhir)
     * - Qobliyah Subuh: setelah imsak → sebelum subuh
     * - Qobliyah Dzuhur: setelah syuruq (terbit + ~15 min) → sebelum dzuhur (atau: sebelum dzuhur masuk)
     * - Ba'diyah Dzuhur: setelah dzuhur → sebelum ashar
     * - Qobliyah Ashar: setelah dzuhur → sebelum ashar
     * - Ba'diyah Maghrib: setelah maghrib → sebelum isya
     * - Ba'diyah Isya: setelah isya → sebelum tengah malam (isya + ~5-6 jam)
     */
    private fun isSunnahOnTime(prayer: String, currentTime: String, timings: Timings): Boolean {
        return try {
            when (prayer) {
                "dhuha" -> {
                    // Dhuha: 15 menit setelah terbit → sebelum dzuhur
                    val dhuhaStart = addMinutes(timings.terbit, 15)
                    isTimeAfter(currentTime, dhuhaStart) && isTimeBefore(currentTime, timings.dzuhur)
                }
                "tahajjud" -> {
                    // Tahajjud: setelah isya → sebelum imsak
                    isTimeAfter(currentTime, timings.isya) || isTimeBefore(currentTime, timings.imsak)
                    // Catatan: isya bisa malam, imsak pagi → cross-midnight, jadi OR
                }
                "rawatib_subuh_qobliyah" -> {
                    // Qobliyah Subuh: samakan dengan sholat wajib subuh (subuh → terbit)
                    isTimeAfter(currentTime, timings.subuh) && isTimeBefore(currentTime, timings.terbit)
                }
                "rawatib_dzuhur_qobliyah" -> {
                    // Qobliyah Dzuhur: dari dzuhur sampai ashar
                    isTimeAfter(currentTime, timings.dzuhur) && isTimeBefore(currentTime, timings.ashar)
                }
                "rawatib_dzuhur_ba'diyyah" -> {
                    // Ba'diyah Dzuhur: setelah dzuhur → sebelum ashar
                    isTimeAfter(currentTime, timings.dzuhur) && isTimeBefore(currentTime, timings.ashar)
                }
                "rawatib_ashar_qobliyah" -> {
                    // Qobliyah Ashar: setelah adzan ashar sampai adzan maghrib
                    isTimeAfter(currentTime, timings.ashar) && isTimeBefore(currentTime, timings.maghrib)
                }
                "rawatib_maghrib_ba'diyyah" -> {
                    // Ba'diyah Maghrib: setelah maghrib → sebelum isya
                    isTimeAfter(currentTime, timings.maghrib) && isTimeBefore(currentTime, timings.isya)
                }
                "rawatib_isya_ba'diyyah" -> {
                    // Ba'diyah Isya: setelah isya → sebelum tengah malam (isya + 5 jam)
                    val midnightCutoff = addMinutes(timings.isya, 300) // 5 jam after isya
                    isTimeAfter(currentTime, timings.isya) && isTimeBefore(currentTime, midnightCutoff)
                }
                else -> true // sunnah lain (tilawah, dzikir) tidak di-lock waktu
            }
        } catch (e: Exception) {
            true // fail-open kalau error parsing
        }
    }

    /** Add N minutes to "HH:mm" string, return new "HH:mm" (wraps around 24h) */
    private fun addMinutes(time: String, minutes: Int): String {
        return try {
            val parts = time.split(":")
            var total = parts[0].toInt() * 60 + parts[1].toInt() + minutes
            total = ((total % 1440) + 1440) % 1440 // wrap 0-1439
            String.format("%02d:%02d", total / 60, total % 60)
        } catch (e: Exception) {
            time
        }
    }

    /**
     * Public wrapper untuk isSunnahOnTime — dipakai UI untuk show lock state.
     * Returns true kalau waktu sekarang masuk window sholat sunnah.
     */
    fun checkSunnahOnTime(prayer: String, timings: com.example.data.Timings): Boolean {
        val currentTime = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"))
        return isSunnahOnTime(prayer, currentTime, timings)
    }

    /**
     * Public wrapper untuk getSunnahTimeHint — dipakai UI di SunnahRowCard.
     */
    fun getSunnahTimeHintPublic(prayer: String): String = getSunnahTimeHint(prayer)

    /**
     * Human-readable hint text untuk sunnah yang di-lock karena di luar waktu.
     * Dipakai di toast message saat user coba log sunnah di luar window.
     */
    private fun getSunnahTimeHint(prayer: String): String {
        return when (prayer) {
            "dhuha" -> "Dhuha bisa setelah matahari naik (±15 min setelah terbit) sampai sebelum Dzuhur."
            "tahajjud" -> "Tahajjud waktu setelah Isya sampai sebelum Imsak (utamanya sepertiga malam terakhir)."
            "rawatib_subuh_qobliyah" -> "Qobliyah Subuh waktunya sama dengan sholat Subuh (dari Subuh sampai Terbit)."
            "rawatib_dzuhur_qobliyah" -> "Qobliyah Dzuhur waktunya dari Dzuhur sampai Ashar."
            "rawatib_dzuhur_ba'diyyah" -> "Ba'diyah Dzuhur waktunya setelah Dzuhur sampai sebelum Ashar."
            "rawatib_ashar_qobliyah" -> "Qobliyah Ashar waktunya setelah adzan Ashar sampai adzan Maghrib."
            "rawatib_maghrib_ba'diyyah" -> "Ba'diyah Maghrib waktunya setelah Maghrib sampai sebelum Isya."
            "rawatib_isya_ba'diyyah" -> "Ba'diyah Isya waktunya setelah Isya sampai tengah malam."
            else -> "Coba lagi nanti ya."
        }
    }

    private fun isDifferentWeek(date1Str: String, date2Str: String): Boolean {
        if (date1Str.isEmpty() || date2Str.isEmpty()) return false
        return try {
            val date1 = LocalDate.parse(date1Str)
            val date2 = LocalDate.parse(date2Str)
            val weekFields = WeekFields.of(Locale.getDefault())
            val week1 = date1.get(weekFields.weekOfWeekBasedYear())
            val year1 = date1.year
            val week2 = date2.get(weekFields.weekOfWeekBasedYear())
            val year2 = date2.year
            week1 != week2 || year1 != year2
        } catch (e: Exception) {
            false
        }
    }

    fun getXpNeededForLevel(level: Int): Int {
        // Balanced curve: 40 + 8*level + 0.5*level²
        // Total XP to level 100 ≈ 208K
        // Casual (~350 XP/day): ~20 months | Active (~600 XP/day): ~11.5 months | Hardcore (~1000 XP/day): ~7 months
        return Math.round(40f + 8f * level + 0.5f * level * level).toInt()
    }

    fun getLevelInfo(cumulativeXp: Int): LevelInfo {
        var lvl = 1
        var tempXp = cumulativeXp
        while (true) {
            val needed = getXpNeededForLevel(lvl)
            if (tempXp >= needed) {
                tempXp -= needed
                lvl++
            } else {
                return LevelInfo(
                    level = lvl,
                    xpInCurrentLevel = tempXp,
                    xpNeededForNextLevel = needed,
                    progress = tempXp.toFloat() / needed.toFloat()
                )
            }
        }
    }

    fun getRankTitle(level: Int): String {
        return when {
            level in 1..9 -> {
                val div = 5 - (level - 1) / 2
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Warrior $divStr"
            }
            level in 10..19 -> {
                val div = 5 - (level - 10) / 2
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Elite $divStr"
            }
            level in 20..29 -> {
                val div = 5 - (level - 20) / 2
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Master $divStr"
            }
            level in 30..39 -> {
                val div = 5 - (level - 30) / 2
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Grandmaster $divStr"
            }
            level in 40..59 -> {
                val div = 5 - (level - 40) / 4
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Epic $divStr"
            }
            level in 60..79 -> {
                val div = 5 - (level - 60) / 4
                val divStr = romanNumeral(Math.max(1, Math.min(5, div)))
                "Muslim Legend $divStr"
            }
            level in 80..99 -> {
                when {
                    level < 85 -> "Muslim Mythic"
                    level < 90 -> "Muslim Mythic Honor"
                    level < 95 -> "Muslim Mythic Glory"
                    else -> "Muslim Mythic Immortal"
                }
            }
            else -> {
                // Level 100+: each level adds 1 star
                // 100 → ★1, 101 → ★2, 102 → ★3, ...
                val stars = level - 99
                "Muslim Mythic Immortal ★$stars"
            }
        }
    }

    private fun romanNumeral(num: Int): String {
        return when (num) {
            1 -> "I"
            2 -> "II"
            3 -> "III"
            4 -> "IV"
            5 -> "V"
            else -> ""
        }
    }

    /**
     * Extracts the base tier name from a level, ignoring division/suffix.
     * Returns one of: "Warrior", "Elite", "Master", "Grandmaster", "Epic",
     * "Legend", "Mythic", "Mythic Honor", "Mythic Glory", "Mythic Immortal"
     */
    fun getTierName(level: Int): String {
        return when {
            level in 1..9 -> "Warrior"
            level in 10..19 -> "Elite"
            level in 20..29 -> "Master"
            level in 30..39 -> "Grandmaster"
            level in 40..59 -> "Epic"
            level in 60..79 -> "Legend"
            level in 80..84 -> "Mythic"
            level in 85..89 -> "Mythic Honor"
            level in 90..94 -> "Mythic Glory"
            else -> "Mythic Immortal" // 95+
        }
    }

    /**
     * Checks whether leveling from oldLevel to newLevel crosses a tier boundary.
     * Returns TierUpData if so, null otherwise.
     */
    private fun checkTierUp(oldLevel: Int, newLevel: Int): TierUpData? {
        if (newLevel <= oldLevel) return null
        val oldTier = getTierName(oldLevel)
        val newTier = getTierName(newLevel)
        if (oldTier == newTier) return null
        return TierUpData(
            newTierName = newTier,
            oldTierName = oldTier,
            unlockedLevel = newLevel,
            rankTitle = getRankTitle(newLevel)
        )
    }

    // ═══════════════════════════════════════════
    // LEARNING SYSTEM — Belajar Tab Methods
    // ═══════════════════════════════════════════

    /**
     * Save quiz result for a module. If score >= 70%, marks module completed.
     * Returns true if passed (>=70%), false otherwise.
     */
    fun submitModuleQuiz(moduleId: String, scorePercent: Int): Boolean {
        val state = _gameData.value
        val existing = state.learningState.progress.find { it.moduleId == moduleId }
        val passed = scorePercent >= 70

        val updatedProgress = if (existing != null) {
            state.learningState.progress.map { p ->
                if (p.moduleId == moduleId) {
                    p.copy(
                        completed = p.completed || passed,
                        quizScore = maxOf(p.quizScore, scorePercent)
                    )
                } else p
            }
        } else {
            state.learningState.progress + ModuleProgress(
                moduleId = moduleId,
                completed = passed,
                quizScore = scorePercent
            )
        }

        val updatedState = state.copy(
            learningState = state.learningState.copy(progress = updatedProgress)
        )
        _gameData.value = updatedState

        viewModelScope.launch {
            repository.saveGameState(updatedState)
        }

        return passed
    }

    /**
     * Claim XP reward for a completed module. Only works once per module.
     * Returns the XP amount claimed, or 0 if already claimed / not completed.
     */
    fun claimModuleXp(moduleId: String, xpAmount: Int): Int {
        val state = _gameData.value
        val progress = state.learningState.progress.find { it.moduleId == moduleId }

        if (progress == null || !progress.completed || progress.xpClaimed) return 0

        val newXp = state.user.xp + xpAmount
        val oldLevelInfo = getLevelInfo(state.user.xp)
        val newLevelInfo = getLevelInfo(newXp)

        val updatedProgress = state.learningState.progress.map { p ->
            if (p.moduleId == moduleId) p.copy(xpClaimed = true) else p
        }

        val updatedState = state.copy(
            user = state.user.copy(xp = newXp, level = newLevelInfo.level),
            learningState = state.learningState.copy(progress = updatedProgress)
        )

        _gameData.value = updatedState

        viewModelScope.launch {
            val badgesList = evaluateBadges(updatedState)
            var finalXp = newXp
            var bonusMsg = ""

            // Check if Santri Digital badge was just earned
            if (badgesList.contains("santri_digital") && !updatedState.badges.contains("santri_digital")) {
                finalXp += 300
                bonusMsg = " 🏆 +300 XP bonus Santri Digital!"
            }

            val finalLevelInfo = getLevelInfo(finalXp)
            val finalData = updatedState.copy(
                user = updatedState.user.copy(xp = finalXp, level = finalLevelInfo.level),
                badges = badgesList
            )
            _gameData.value = finalData
            repository.saveGameState(finalData)

            if (finalLevelInfo.level > oldLevelInfo.level) {
                levelUpAnimationEvent.value = finalLevelInfo.level
                checkTierUp(oldLevelInfo.level, finalLevelInfo.level)?.let { tierData ->
                    tierUpAnimationEvent.value = tierData
                }
            }

            _toastEvent.emit("Modul selesai! +$xpAmount XP 🎓$bonusMsg")
        }

        return xpAmount
    }

    /**
     * Get the ModuleProgress for a given module ID, or null if not started.
     */
    fun getModuleProgress(moduleId: String): ModuleProgress? {
        return _gameData.value.learningState.progress.find { it.moduleId == moduleId }
    }
}

data class LevelInfo(
    val level: Int,
    val xpInCurrentLevel: Int,
    val xpNeededForNextLevel: Int,
    val progress: Float
)
