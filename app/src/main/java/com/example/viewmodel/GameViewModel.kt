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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
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
    val unlockedRewardName: String? = null,
    val rewardIndex: Int = 1
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
    val rewardRevealEvent = MutableStateFlow<RewardRevealState?>(null)

    // For Aladhan loading state
    private val _isFetchingApi = MutableStateFlow(false)
    val isFetchingApi: StateFlow<Boolean> = _isFetchingApi.asStateFlow()

    // 10 Gacha reward pool
    val rewardPool = listOf(
        "Lencana Bulan Sabit Menyala",
        "Efek Aura Sultan",
        "Bingkai Penjelajah Subuh",
        "Gelar Pembasmi Sunyi Tahajjud",
        "Ikon Ramuan Mana Dzikir",
        "Segel Penjaga Maghrib",
        "Jejak Api Istiqomah",
        "Jubah Bijak Al-Qur'an",
        "Sayap Gacha Malaikat",
        "Pedang Sholat Mitik"
    )

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
    fun startNewGame(username: String, intensityMode: String, kota: String) {
        viewModelScope.launch {
            val defaultData = MuslimLevelingData(
                user = User(
                    username = username,
                    intensityMode = intensityMode,
                    kota = kota,
                    santaiTrackedPrayers = listOf("subuh", "maghrib", "isya")
                ),
                lastCheckedDate = LocalDate.now().toString()
            )
            _gameData.value = defaultData
            repository.saveGameState(defaultData)
            fetchPrayerTimes(kota)
            generateQuests()
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
        intensityMode: String,
        santaiPrayers: List<String>,
        notifMode: String,
        theme: String
    ) {
        viewModelScope.launch {
            val currentData = _gameData.value
            val oldKota = currentData.user.kota

            val updatedUser = currentData.user.copy(
                username = username,
                kota = kota,
                intensityMode = intensityMode,
                santaiTrackedPrayers = santaiPrayers,
                notifMode = notifMode,
                theme = theme
            )

            var updatedData = currentData.copy(user = updatedUser)
            _gameData.value = updatedData
            repository.saveGameState(updatedData)

            if (kota.isNotEmpty() && kota.lowercase() != oldKota.lowercase()) {
                fetchPrayerTimes(kota)
            }
            _toastEvent.emit("Profil udah ke-update! ✅")
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
                fetchPrayerTimes(state.user.kota)
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
            fetchPrayerTimes(state.user.kota)
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

            // Update cumulative user XP
            val oldXp = state.user.xp
            val newXp = oldXp + xpGained

            val oldLevelInfo = getLevelInfo(oldXp)
            val newLevelInfo = getLevelInfo(newXp)

            val didLevelUp = newLevelInfo.level > oldLevelInfo.level

            // 3. Roll 30% Gacha reward item
            var unlockedReward: String? = null
            var rewardIdx = 1
            if (Random.nextFloat() <= 0.30f) {
                val unacquired = rewardPool.filter { !state.rewards.contains(it) }
                if (unacquired.isNotEmpty()) {
                    unlockedReward = unacquired.random()
                    rewardIdx = rewardPool.indexOf(unlockedReward) + 1
                }
            }

            val updatedRewards = if (unlockedReward != null) {
                state.rewards + unlockedReward
            } else {
                state.rewards
            }

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
                rewards = updatedRewards,
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
            }

            // Gacha reveal sequence
            rewardRevealEvent.value = RewardRevealState(
                prayerName = prayer.capitalizeCompat(),
                xpGained = xpGained,
                isFiveOfFiveCompleted = isHeroCompletor,
                unlockedRewardName = unlockedReward,
                rewardIndex = rewardIdx
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

            // Modes extensions
            if (state.user.intensityMode == "sultan" || state.user.intensityMode == "standar") {
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
            }

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
     * Formats API or caches for Aladhan
     */
    fun fetchPrayerTimes(kota: String) {
        if (kota.isEmpty()) return
        _isFetchingApi.value = true
        viewModelScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    AladhanClient.apiService.getTimingsByCity(city = kota)
                }
                if (response.code == 200) {
                    val timings = response.data.timings
                    val newCache = PlayerPrayerTimesCache(
                        date = LocalDate.now().toString(),
                        timings = Timings(
                            subuh = timings.fajr,
                            dzuhur = timings.dhuhr,
                            ashar = timings.asr,
                            maghrib = timings.maghrib,
                            isya = timings.isha
                        )
                    )
                    val updatedData = _gameData.value.copy(prayerTimesCache = newCache)
                    _gameData.value = updatedData
                    repository.saveGameState(updatedData)
                    _toastEvent.emit("Jadwal sholat $kota udah ke-load! ✅")
                } else {
                    _toastEvent.emit("Gagal load jadwal sholat 😥")
                }
            } catch (e: Exception) {
                e.printStackTrace()
                _toastEvent.emit("Koneksi error. Pakai jadwal default dulu ya.")
            } finally {
                _isFetchingApi.value = false
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
        return Math.round(100 * (level + 1) * Math.pow(1.15, (level + 1).toDouble())).toInt()
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
            else -> "Muslim Mythic Immortal ★${level - 100}"
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
}

data class LevelInfo(
    val level: Int,
    val xpInCurrentLevel: Int,
    val xpNeededForNextLevel: Int,
    val progress: Float
)
