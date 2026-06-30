package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class User(
    val username: String = "",
    val level: Int = 1,
    val xp: Int = 0,
    // intensityMode & santaiTrackedPrayers removed — semua mode sama (standar: 5 wajib + sunnah aktif)
    // Field di-keep untuk backward-compat parsing save game lama, tapi tidak dipakai lagi.
    val intensityMode: String = "standar",
    val santaiTrackedPrayers: List<String> = listOf("subuh", "maghrib", "isya"),
    val kota: String = "",          // Nama kota (display) — e.g. "KOTA DENPASAR"
    val kotaId: String = "6a9aeddfc689c1d0e3b9ccc3ab651bc5",    // api.myquran.com v3 city ID (default: KOTA DENPASAR)
    val theme: String = "dark", // "dark" | "light"
    val notifMode: String = "seimbang", // "fokus" | "seimbang" | "intensif"
    val profileImagePath: String? = null  // Local file path to uploaded profile photo (null = use default 👑 avatar)
)

@JsonClass(generateAdapter = true)
data class Timings(
    val imsak: String = "04:32",
    val subuh: String = "04:42",
    val terbit: String = "05:55",
    val dhuha: String = "06:20",
    val dzuhur: String = "12:01",
    val ashar: String = "15:20",
    val maghrib: String = "17:55",
    val isya: String = "19:08"
)

@JsonClass(generateAdapter = true)
data class PlayerPrayerTimesCache(
    val date: String = "",
    val timings: Timings = Timings()
)

@JsonClass(generateAdapter = true)
data class PrayerLog(
    val date: String, // YYYY-MM-DD
    val prayer: String, // subuh, dzuhur, ashar, maghrib, isya, dhuha, rawatib, tahajjud, tilawah
    val time: String, // HH:mm
    val type: String // "wajib" | "sunnah" | "tilawah"
)

@JsonClass(generateAdapter = true)
data class StreakState(
    val current: Int = 0,
    val best: Int = 0,
    val freezeAvailable: Boolean = true,
    val lastDate: String = "" // YYYY-MM-DD (or lastFullDay for hero)
)

@JsonClass(generateAdapter = true)
data class Quest(
    val id: String,
    val desc: String,
    val xpReward: Int,
    val target: Int,
    val progress: Int,
    val completed: Boolean,
    val claimed: Boolean
)

@JsonClass(generateAdapter = true)
data class QuestState(
    val date: String = "",
    val list: List<Quest> = emptyList()
)

@JsonClass(generateAdapter = true)
data class ZikirCounter(
    val date: String = "",
    val count: Int = 0
)

@JsonClass(generateAdapter = true)
data class MuslimLevelingData(
    val user: User = User(),
    val prayerTimesCache: PlayerPrayerTimesCache = PlayerPrayerTimesCache(),
    val prayerLog: List<PrayerLog> = emptyList(),
    val heroStreak: StreakState = StreakState(),
    val perPrayerStreaks: Map<String, StreakState> = mapOf(
        "subuh" to StreakState(),
        "dzuhur" to StreakState(),
        "ashar" to StreakState(),
        "maghrib" to StreakState(),
        "isya" to StreakState()
    ),
    val tilawahStreak: StreakState = StreakState(),
    val quests: QuestState = QuestState(),
    val badges: List<String> = emptyList(),
    val rewards: List<String> = emptyList(),
    val dailyChestOpenedDate: String = "",   // yyyy-MM-dd when chest last opened ("" = never)
    val zikirCounter: ZikirCounter = ZikirCounter(),
    val comebackCount: Int = 0,
    val lastCheckedDate: String = "",
    val learningState: LearningState = LearningState()
)

// ═══════════════════════════════════════════
// LEARNING SYSTEM — Belajar Tab Data Models
// ═══════════════════════════════════════════

@JsonClass(generateAdapter = true)
data class ModuleProgress(
    val moduleId: String = "",
    val completed: Boolean = false,
    val quizScore: Int = 0,        // percentage 0-100
    val xpClaimed: Boolean = false
)

@JsonClass(generateAdapter = true)
data class LearningState(
    val progress: List<ModuleProgress> = emptyList()
)

// Non-serializable UI models (not persisted, hardcoded in BelajarScreen.kt)
data class LearningModule(
    val id: String,
    val categoryId: String,
    val title: String,
    val icon: String,
    val estimatedMinutes: Int,
    val xpReward: Int
)

data class LearningCategory(
    val id: String,
    val label: String,
    val icon: String,
    val modules: List<LearningModule>
)

data class QuizQuestion(
    val question: String,
    val options: List<String>,
    val correctIndex: Int,
    val explanation: String
)

fun String.capitalizeCompat(): String {
    if (this.isEmpty()) return this
    return this.substring(0, 1).uppercase() + this.substring(1)
}
