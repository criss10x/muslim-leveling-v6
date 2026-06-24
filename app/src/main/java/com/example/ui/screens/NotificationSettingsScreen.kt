package com.example.ui.screens

import android.content.Context
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.MuslimLevelingData
import com.example.data.capitalizeCompat
import com.example.notifications.NotificationScheduler
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel
import java.time.LocalDate

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS SCREEN
// 3 mode notifikasi:
//   🔇 Silent      — notifikasi dimatikan total
//   🔔 Notif Saja  — notifikasi tanpa suara (vibrate only)
//   🔊 Notif Suara — notifikasi + suara adzan
// Per-sholat toggle, test button, adzan reminder toggle.
// ═══════════════════════════════════════════════════════════════

private val ArenaBorder = TextLight.copy(alpha = 0.08f)

// Notif mode constants
private const val MODE_SILENT = "silent"
private const val MODE_NOTIF_ONLY = "notif_only"
private const val MODE_NOTIF_SOUND = "notif_sound"

// SharedPreferences keys for per-prayer toggle & sound
private const val PREFS_NOTIF = "notif_settings"
private const val KEY_NOTIF_MODE = "notif_mode"
private const val KEY_PRAYER_PREFIX = "prayer_notif_"
private const val PRAYERS = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")

@Composable
fun NotificationSettingsScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    val prefs = remember { context.getSharedPreferences(PREFS_NOTIF, Context.MODE_PRIVATE) }

    // Current notif mode (default: notif_only)
    var notifMode by remember { mutableStateOf(prefs.getString(KEY_NOTIF_MODE, MODE_NOTIF_ONLY) ?: MODE_NOTIF_ONLY) }

    // Per-prayer toggle state
    var prayerToggles by remember {
        mutableStateOf(
            PRAYERS.associateWith { prayer ->
                prefs.getBoolean("${KEY_PRAYER_PREFIX}$prayer", true)
            }
        )
    }

    // Adzan reminder toggle (existing system)
    var adzanEnabled by remember {
        mutableStateOf(NotificationScheduler.isRemindersEnabled(context))
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .futuristicBackground()
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = 20.dp)
                .padding(top = 28.dp, bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ─── Title ───
            SectionTitlePill(text = "PENGATURAN NOTIFIKASI", gradient = GradientGreenGold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "🔔 Notifikasi",
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                color = TextLight,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Atur cara kamu diingetin waktu sholat",
                fontSize = 12.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp)
            )

            Spacer(modifier = Modifier.height(24.dp))

            // ═══════════════════════════════════════
            // MODE SELECTOR — 3 cards
            // ═══════════════════════════════════════
            SectionTitlePill(text = "MODE NOTIFIKASI", gradient = GradientGoldAmber)
            Spacer(modifier = Modifier.height(12.dp))

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NotifModeCard(
                    icon = "🔇",
                    title = "Silent",
                    desc = "Tidak ada notifikasi sama sekali. Cocok kalau lagi fokus ibadah sendiri.",
                    isSelected = notifMode == MODE_SILENT,
                    accentColor = TextMuted,
                    onClick = {
                        notifMode = MODE_SILENT
                        prefs.edit().putString(KEY_NOTIF_MODE, MODE_SILENT).apply()
                        if (adzanEnabled) {
                            NotificationScheduler.cancelAdhanReminders(context)
                        }
                    }
                )

                NotifModeCard(
                    icon = "🔔",
                    title = "Notif Saja",
                    desc = "Notifikasi muncul tanpa suara, cuma getaran. Diskrep tanpa ganggu.",
                    isSelected = notifMode == MODE_NOTIF_ONLY,
                    accentColor = IslamicGreen,
                    onClick = {
                        notifMode = MODE_NOTIF_ONLY
                        prefs.edit().putString(KEY_NOTIF_MODE, MODE_NOTIF_ONLY).apply()
                        if (adzanEnabled) {
                            rescheduleAdhan(context, state.user.kota, state.prayerTimesCache.timings.let {
                                mapOf(
                                    "subuh" to it.subuh,
                                    "dzuhur" to it.dzuhur,
                                    "ashar" to it.ashar,
                                    "maghrib" to it.maghrib,
                                    "isya" to it.isya
                                )
                            })
                        }
                    }
                )

                NotifModeCard(
                    icon = "🔊",
                    title = "Notif + Suara",
                    desc = "Notifikasi lengkap dengan suara adzan. Paling lengkap & nggak bakal kelewat.",
                    isSelected = notifMode == MODE_NOTIF_SOUND,
                    accentColor = GoldAccent,
                    onClick = {
                        notifMode = MODE_NOTIF_SOUND
                        prefs.edit().putString(KEY_NOTIF_MODE, MODE_NOTIF_SOUND).apply()
                        if (!adzanEnabled) {
                            adzanEnabled = true
                            NotificationScheduler.setRemindersEnabled(context, true)
                        }
                        rescheduleAdhan(context, state.user.kota, state.prayerTimesCache.timings.let {
                            mapOf(
                                "subuh" to it.subuh,
                                "dzuhur" to it.dzuhur,
                                "ashar" to it.ashar,
                                "maghrib" to it.maghrib,
                                "isya" to it.isya
                            )
                        })
                    }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ═══════════════════════════════════════
            // PER-SHALAT TOGGLE
            // ═══════════════════════════════════════
            if (notifMode != MODE_SILENT) {
                SectionTitlePill(text = "NOTIF PER SHOLAT", gradient = GradientCyanGreen)
                Spacer(modifier = Modifier.height(12.dp))

                val cardShape = RoundedCornerShape(16.dp)
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = cardShape,
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    border = BorderStroke(1.dp, ArenaBorder)
                ) {
                    Column(modifier = Modifier.padding(8.dp)) {
                        PRAYERS.forEachIndexed { index, prayer ->
                            val isEnabled = prayerToggles[prayer] ?: true
                            PrayerToggleRow(
                                prayerName = prayer.capitalizeCompat(),
                                time = when (prayer) {
                                    "subuh" -> state.prayerTimesCache.timings.subuh
                                    "dzuhur" -> state.prayerTimesCache.timings.dzuhur
                                    "ashar" -> state.prayerTimesCache.timings.ashar
                                    "maghrib" -> state.prayerTimesCache.timings.maghrib
                                    "isya" -> state.prayerTimesCache.timings.isya
                                    else -> "--:--"
                                },
                                isEnabled = isEnabled,
                                onToggle = {
                                    val newToggles = prayerToggles.toMutableMap()
                                    newToggles[prayer] = !isEnabled
                                    prayerToggles = newToggles
                                    prefs.edit().putBoolean("${KEY_PRAYER_PREFIX}$prayer", !isEnabled).apply()
                                    // Reschedule if adzan enabled
                                    if (adzanEnabled) {
                                        rescheduleAdhan(context, state.user.kota, state.prayerTimesCache.timings.let {
                                            mapOf(
                                                "subuh" to it.subuh,
                                                "dzuhur" to it.dzuhur,
                                                "ashar" to it.ashar,
                                                "maghrib" to it.maghrib,
                                                "isya" to it.isya
                                            )
                                        })
                                    }
                                }
                            )
                            if (index < PRAYERS.lastIndex) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(0.5.dp)
                                        .background(ArenaBorder)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }

            // ═══════════════════════════════════════
            // ADZAN REMINDER MASTER TOGGLE
            // ═══════════════════════════════════════
            SectionTitlePill(text = "PENGINGAT ADZAN", gradient = GradientGoldAmber)
            Spacer(modifier = Modifier.height(12.dp))

            val toggleShape = RoundedCornerShape(14.dp)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = toggleShape,
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, if (adzanEnabled) IslamicGreen.copy(alpha = 0.4f) else ArenaBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            adzanEnabled = !adzanEnabled
                            NotificationScheduler.setRemindersEnabled(context, adzanEnabled)
                            if (adzanEnabled && state.prayerTimesCache.timings.subuh.isNotEmpty()) {
                                val timings = mapOf(
                                    "subuh" to state.prayerTimesCache.timings.subuh,
                                    "dzuhur" to state.prayerTimesCache.timings.dzuhur,
                                    "ashar" to state.prayerTimesCache.timings.ashar,
                                    "maghrib" to state.prayerTimesCache.timings.maghrib,
                                    "isya" to state.prayerTimesCache.timings.isya
                                )
                                NotificationScheduler.scheduleAdhanReminders(
                                    context, state.user.kota, timings
                                )
                            }
                        }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "🔔 Pengingat Adzan Otomatis",
                            fontSize = 14.sp,
                            color = TextLight,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (adzanEnabled) "Aktif — notifikasi tiap waktu sholat"
                                   else "Mati — aktifkan untuk reminder sholat",
                            fontSize = 11.sp,
                            color = if (adzanEnabled) IslamicGreen else TextMuted,
                            modifier = Modifier.padding(top = 2.dp)
                        )
                    }
                    // Toggle switch
                    Box(
                        modifier = Modifier
                            .size(width = 48.dp, height = 26.dp)
                            .clip(RoundedCornerShape(100.dp))
                            .background(if (adzanEnabled) IslamicGreen else DarkSurfaceVariant)
                            .border(1.dp, if (adzanEnabled) IslamicGreen else ArenaBorder, RoundedCornerShape(100.dp)),
                        contentAlignment = if (adzanEnabled) Alignment.CenterEnd else Alignment.CenterStart
                    ) {
                        Box(
                            modifier = Modifier
                                .padding(horizontal = 2.dp)
                                .size(20.dp)
                                .background(TextLight, CircleShape)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ═══════════════════════════════════════
            // TEST NOTIFICATION BUTTON
            // ═══════════════════════════════════════
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(8.dp, RoundedCornerShape(12.dp), ambientColor = IslamicGreen.copy(alpha = 0.3f))
                    .background(Brush.horizontalGradient(GradientGreenGold), RoundedCornerShape(12.dp))
                    .clickable {
                        val modeLabel = when (notifMode) {
                            MODE_SILENT -> "Silent"
                            MODE_NOTIF_ONLY -> "Notif Saja"
                            MODE_NOTIF_SOUND -> "Notif + Suara"
                            else -> "Default"
                        }
                        NotificationHelper.sendTestNotification(context, notifMode)
                    }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "🔔 Test Notifikasi Sekarang",
                    fontWeight = FontWeight.Black,
                    fontSize = 13.sp,
                    color = Color.Black
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Info card
            val infoShape = RoundedCornerShape(14.dp)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = infoShape,
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, ArenaBorder)
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = "ℹ️ Cara Kerja",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = GoldAccent
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    val infoText = when (notifMode) {
                        MODE_SILENT -> "Mode Silent: Semua notifikasi sholat dimatikan. Kamu nggak akan diganggu sama notifikasi apa pun."
                        MODE_NOTIF_ONLY -> "Mode Notif Saja: Kamu akan dapat notifikasi (tanpa suara) tiap waktu sholat. Hanya getaran sebagai alert."
                        MODE_NOTIF_SOUND -> "Mode Notif + Suara: Notifikasi lengkap dengan suara adzan. Pastikan volume HP kamu tidak silent."
                        else -> ""
                    }
                    Text(
                        text = infoText,
                        fontSize = 11.sp,
                        color = TextMuted,
                        lineHeight = 16.sp
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// NOTIF MODE CARD
// ═══════════════════════════════════════════════════════════════

@Composable
private fun NotifModeCard(
    icon: String,
    title: String,
    desc: String,
    isSelected: Boolean,
    accentColor: Color,
    onClick: () -> Unit
) {
    val cardShape = RoundedCornerShape(16.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("notif_mode_${title.lowercase()}")
            .then(
                if (isSelected) Modifier.shadow(12.dp, cardShape, ambientColor = accentColor.copy(alpha = 0.4f))
                else Modifier
            )
            .clickable { onClick() },
        shape = cardShape,
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) DarkSurface else DarkSurface.copy(alpha = 0.6f)
        ),
        border = BorderStroke(
            if (isSelected) 1.5.dp else 1.dp,
            if (isSelected) Brush.linearGradient(listOf(accentColor.copy(alpha = 0.6f), accentColor.copy(alpha = 0.2f)))
            else Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon circle
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(accentColor.copy(alpha = if (isSelected) 0.18f else 0.08f))
                    .border(1.dp, accentColor.copy(alpha = if (isSelected) 0.4f else 0.2f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(text = icon, fontSize = 22.sp)
            }
            Spacer(modifier = Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (isSelected) accentColor else TextLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = desc,
                    fontSize = 11.sp,
                    color = TextMuted,
                    lineHeight = 15.sp
                )
            }
            // Selected indicator
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape)
                        .background(accentColor)
                        .border(2.dp, Color.Black.copy(alpha = 0.2f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "✓", fontSize = 14.sp, color = Color.Black, fontWeight = FontWeight.Black)
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PRAYER TOGGLE ROW
// ═══════════════════════════════════════════════════════════════

@Composable
private fun PrayerToggleRow(
    prayerName: String,
    time: String,
    isEnabled: Boolean,
    onToggle: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onToggle() }
            .padding(horizontal = 12.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            val icon = when (prayerName.lowercase()) {
                "subuh" -> "🌅"
                "dzuhur" -> "☀️"
                "ashar" -> "🌤️"
                "maghrib" -> "🌇"
                "isya" -> "🌙"
                else -> "🕌"
            }
            Text(text = icon, fontSize = 20.sp)
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = prayerName,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = if (isEnabled) TextLight else TextMuted
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = time,
                fontSize = 12.sp,
                color = TextMuted,
                fontFamily = FontFamily.Monospace
            )
        }
        // Toggle
        Box(
            modifier = Modifier
                .size(width = 44.dp, height = 24.dp)
                .clip(RoundedCornerShape(100.dp))
                .background(if (isEnabled) IslamicGreen else DarkSurfaceVariant)
                .border(1.dp, if (isEnabled) IslamicGreen else ArenaBorder, RoundedCornerShape(100.dp)),
            contentAlignment = if (isEnabled) Alignment.CenterEnd else Alignment.CenterStart
        ) {
            Box(
                modifier = Modifier
                    .padding(horizontal = 2.dp)
                    .size(18.dp)
                    .background(TextLight, CircleShape)
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// HELPER: Reschedule adhan reminders
// ═══════════════════════════════════════════════════════════════

private fun rescheduleAdhan(
    context: Context,
    city: String,
    timings: Map<String, String>
) {
    if (city.isEmpty() || timings.isEmpty()) return
    NotificationScheduler.scheduleAdhanReminders(context, city, timings)
}

// ─── Section title pill ───
@Composable
private fun SectionTitlePill(
    text: String,
    gradient: List<Color> = GradientGreenGold
) {
    Box(
        modifier = Modifier
            .shadow(8.dp, RoundedCornerShape(100.dp), ambientColor = IslamicGreen.copy(alpha = 0.4f))
            .background(Brush.horizontalGradient(gradient), RoundedCornerShape(100.dp))
            .padding(horizontal = 14.dp, vertical = 5.dp)
    ) {
        Text(
            text = text,
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            color = Color.Black,
            letterSpacing = 2.sp
        )
    }
}
