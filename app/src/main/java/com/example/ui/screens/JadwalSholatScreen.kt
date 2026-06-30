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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
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
import com.example.notifications.NotificationScheduler
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

// ═══════════════════════════════════════════════════════════════
// JADWAL SHOLAT SCREEN
// Match mockup: jadwal_sholat_hero_icons_edition/code.html 1:1
// ═══════════════════════════════════════════════════════════════

private val ArenaBorder = TextLight.copy(alpha = 0.08f)

@Composable
fun JadwalSholatScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    val scrollState = rememberScrollState()
    val context = LocalContext.current
    val today = LocalDate.now()
    val todayStr = today.toString()

    var showQibla by remember { mutableStateOf(false) }

    val timings = state.prayerTimesCache.timings
    val prayers = listOf(
        Triple("subuh", "Subuh", timings.subuh),
        Triple("dzuhur", "Dzuhur", timings.dzuhur),
        Triple("ashar", "Ashar", timings.ashar),
        Triple("maghrib", "Maghrib", timings.maghrib),
        Triple("isya", "Isya", timings.isya)
    )

    val now = LocalTime.now()
    val nextPrayer = prayers.firstOrNull { (_, _, timeStr) ->
        try {
            LocalTime.parse(timeStr, DateTimeFormatter.ofPattern("HH:mm")).isAfter(now)
        } catch (e: Exception) { false }
    } ?: prayers.first()

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
                .padding(horizontal = 16.dp)
                .padding(top = 24.dp, bottom = 100.dp)
        ) {
            // ─── 1. Title pill ───
            Box(
                modifier = Modifier
                    .padding(top = 8.dp)
                    .padding(bottom = 8.dp)
                    .align(Alignment.CenterHorizontally)
                    .background(AmberFlame.copy(alpha = 0.1f), RoundedCornerShape(100.dp))
                    .border(1.dp, AmberFlame.copy(alpha = 0.3f), RoundedCornerShape(100.dp))
                    .padding(horizontal = 16.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "JADWAL SHOLAT",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Black,
                    color = AmberFlame,
                    letterSpacing = 2.sp,
                    fontFamily = FontFamily.Monospace
                )
            }

            // ─── 2. Header: title + date + city ───
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "🕐 Waktu Sholat",
                fontSize = 32.sp,
                fontWeight = FontWeight.ExtraBold,
                color = TextLight,
                modifier = Modifier.padding(start = 4.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(start = 4.dp)
            ) {
                Text(
                    text = "15 Ramadhan 1445H",
                    fontSize = 14.sp,
                    color = TextMuted
                )
                Text(
                    text = "  •  ",
                    fontSize = 14.sp,
                    color = OutlineVariant
                )
                Text(
                    text = "📍 ${state.user.kota}, Indonesia",
                    fontSize = 14.sp,
                    color = TextMuted,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ─── 3. Qibla button (yellow hero) ───
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(8.dp, RoundedCornerShape(12.dp), ambientColor = AmberFlame.copy(alpha = 0.3f))
                    .background(Brush.horizontalGradient(GradientGoldAmber), RoundedCornerShape(12.dp))
                    .clickable { showQibla = true }
                    .padding(vertical = 16.dp, horizontal = 24.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("🧭", fontSize = 22.sp)
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        "Kompas Kiblat",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 20.sp,
                        color = Color(0xFF3A3000)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        "→",
                        fontSize = 20.sp,
                        color = Color(0xFF3A3000).copy(alpha = 0.7f),
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ─── 4. Next Prayer card ───
            NextPrayerCard(
                nextPrayerName = nextPrayer.second,
                nextPrayerTime = nextPrayer.third,
                now = now
            )

            Spacer(modifier = Modifier.height(24.dp))

            // ─── 5. Prayer schedule list (5 cards) ───
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                prayers.forEach { (id, name, timeStr) ->
                    val isNext = id == nextPrayer.first
                    val isLogged = state.prayerLog.any { it.date == todayStr && it.prayer == id }
                    PrayerRow(
                        name = name,
                        time = timeStr,
                        isNext = isNext,
                        isLogged = isLogged,
                        modifier = Modifier.testTag("schedule_row_${name.lowercase()}")
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // ─── 6. Adzan master switch + 3 mode buttons ───
            NotificationSettingsSection(state = state, context = context)

            Spacer(modifier = Modifier.height(24.dp))

            // ─── 7. Footer ───
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DarkSurface.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .border(1.dp, OutlineVariant.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "SUMBER DATA: KEMENAG RI",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = OutlineDefault,
                    letterSpacing = 1.5.sp,
                    fontFamily = FontFamily.Monospace
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text("👆", fontSize = 12.sp)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Ketuk lokasi di header untuk mengubah kota",
                        fontSize = 12.sp,
                        color = TextMuted.copy(alpha = 0.6f)
                    )
                }
            }
        }

        if (showQibla) {
            QiblaScreen(
                cityName = state.user.kota,
                onBack = { showQibla = false }
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// NEXT PRAYER CARD — match mockup section 4
// ═══════════════════════════════════════════════════════════════

@Composable
private fun NextPrayerCard(
    nextPrayerName: String,
    nextPrayerTime: String,
    now: LocalTime
) {
    val countdownText = remember(nextPrayerTime, now) {
        try {
            val prayerTime = LocalTime.parse(nextPrayerTime, DateTimeFormatter.ofPattern("HH:mm"))
            val totalMinutes = ChronoUnit.MINUTES.between(now, prayerTime)
            if (totalMinutes < 0) "${24 * 60 + totalMinutes}m lagi"
            else "${totalMinutes}m lagi"
        } catch (e: Exception) {
            "--"
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(20.dp, RoundedCornerShape(12.dp), ambientColor = IslamicGreen.copy(alpha = 0.1f))
            .background(DarkSurfaceElevated, RoundedCornerShape(12.dp))
            .border(1.dp, IslamicGreenDim.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
            .padding(24.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column {
                    Text(
                        text = "SELANJUTNYA",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = IslamicGreen,
                        letterSpacing = 1.5.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = nextPrayerName,
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextLight
                    )
                }
                Box(
                    modifier = Modifier
                        .background(DarkSurfaceVariant.copy(alpha = 0.8f), RoundedCornerShape(100.dp))
                        .border(1.dp, AmberFlame.copy(alpha = 0.5f), RoundedCornerShape(100.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = "⏱ $countdownText".uppercase(),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = GoldAccent,
                        letterSpacing = 1.sp,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = nextPrayerTime,
                    fontSize = 40.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = IslamicGreen,
                    fontFamily = FontFamily.Monospace
                )
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(IslamicGreenDim.copy(alpha = 0.2f))
                        .border(1.dp, IslamicGreenDim.copy(alpha = 0.5f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text("🔔", fontSize = 18.sp)
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PRAYER ROW — match mockup section 5
// States: completed (opacity-75 + check pill) | active (teal border-l-4) | future (bell)
// ═══════════════════════════════════════════════════════════════

@Composable
private fun PrayerRow(
    name: String,
    time: String,
    isNext: Boolean,
    isLogged: Boolean,
    modifier: Modifier = Modifier
) {
    val icon = when (name.lowercase()) {
        "subuh" -> "🌅"
        "dzuhur" -> "☀️"
        "ashar" -> "🌤️"
        "maghrib" -> "🌇"
        "isya" -> "🌙"
        else -> "🕌"
    }
    val iconColor = when {
        isNext -> CyanAccent
        isLogged -> IslamicGreen
        else -> GoldAccent
    }
    val nameColor = if (isNext || isLogged) TextLight else TextMuted
    val timeColor = when {
        isNext -> IslamicGreen
        isLogged -> OutlineDefault
        else -> TextMuted
    }

    val rowBg = if (isNext) DarkSurface else DarkSurface.copy(alpha = 0.75f)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (isNext) Modifier
                    .background(rowBg, RoundedCornerShape(8.dp))
                    .border(
                        width = 1.dp,
                        color = IslamicGreenDim.copy(alpha = 0.4f),
                        shape = RoundedCornerShape(8.dp)
                    )
                    .drawBehind {
                        drawRect(
                            color = IslamicGreen,
                            topLeft = androidx.compose.ui.geometry.Offset(0f, 0f),
                            size = androidx.compose.ui.geometry.Size(4.dp.toPx(), size.height)
                        )
                    }
                else Modifier
                    .background(rowBg, RoundedCornerShape(8.dp))
                    .border(1.dp, OutlineVariant.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
            )
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(if (isNext) IslamicGreenDim.copy(alpha = 0.2f) else DarkSurfaceVariant)
                        .then(
                            if (isNext) Modifier.border(1.dp, IslamicGreenDim.copy(alpha = 0.3f), CircleShape)
                            else Modifier
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = icon, fontSize = 20.sp)
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text(
                        text = name,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = nameColor
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = time,
                        fontSize = 12.sp,
                        color = timeColor,
                        fontFamily = FontFamily.Monospace,
                        letterSpacing = 1.sp
                    )
                }
            }

            when {
                isLogged -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .background(IslamicGreenDim.copy(alpha = 0.1f), RoundedCornerShape(6.dp))
                            .border(1.dp, IslamicGreenDim.copy(alpha = 0.2f), RoundedCornerShape(6.dp))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("✓", fontSize = 12.sp, color = IslamicGreenDim)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "SUDAH DILOG",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            color = IslamicGreenDim,
                            letterSpacing = 1.sp,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
                isNext -> {
                    Text(text = "⋮", fontSize = 20.sp, color = OutlineDefault)
                }
                else -> {
                    Text(text = "🔔", fontSize = 18.sp, color = OutlineDefault)
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS — match mockup section 7
// Master switch (ON teal) + 3 mode buttons: SILENT / NOTIF / SOUND
// ═══════════════════════════════════════════════════════════════

private const val MODE_SILENT = "silent"
private const val MODE_NOTIF_ONLY = "notif_only"
private const val MODE_NOTIF_SOUND = "notif_sound"
private const val PREFS_NOTIF = "notif_settings"
private const val KEY_NOTIF_MODE = "notif_mode"

@Composable
private fun NotificationSettingsSection(
    state: MuslimLevelingData,
    context: Context
) {
    val prefs = remember { context.getSharedPreferences(PREFS_NOTIF, Context.MODE_PRIVATE) }
    var notifMode by remember { mutableStateOf(prefs.getString(KEY_NOTIF_MODE, MODE_NOTIF_SOUND) ?: MODE_NOTIF_SOUND) }
    var adzanEnabled by remember { mutableStateOf(NotificationScheduler.isRemindersEnabled(context)) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(DarkSurface, RoundedCornerShape(12.dp))
            .border(1.dp, OutlineVariant.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
            .padding(20.dp)
    ) {
        // ─── Master switch ───
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("📢", fontSize = 20.sp)
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Adzan Master Switch",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextLight
                )
            }
            Box(
                modifier = Modifier
                    .size(width = 48.dp, height = 24.dp)
                    .clip(RoundedCornerShape(100.dp))
                    .background(if (adzanEnabled) IslamicGreenDim else DarkSurfaceVariant)
                    .border(
                        1.dp,
                        if (adzanEnabled) IslamicGreen else OutlineVariant,
                        RoundedCornerShape(100.dp)
                    )
                    .clickable {
                        adzanEnabled = !adzanEnabled
                        NotificationScheduler.setRemindersEnabled(context, adzanEnabled)
                        if (adzanEnabled) rescheduleAdhan(context, state)
                    },
                contentAlignment = if (adzanEnabled) Alignment.CenterEnd else Alignment.CenterStart
            ) {
                Box(
                    modifier = Modifier
                        .padding(horizontal = 3.dp)
                        .size(16.dp)
                        .background(Color(0xFF003828), CircleShape)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(OutlineVariant.copy(alpha = 0.3f))
        )
        Spacer(modifier = Modifier.height(16.dp))

        // ─── 3 mode buttons ───
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            ModeButton(
                icon = "🔇",
                label = "SILENT",
                isActive = notifMode == MODE_SILENT,
                modifier = Modifier.weight(1f),
                onClick = {
                    notifMode = MODE_SILENT
                    prefs.edit().putString(KEY_NOTIF_MODE, MODE_SILENT).apply()
                    if (adzanEnabled) NotificationScheduler.cancelAdhanReminders(context)
                }
            )
            ModeButton(
                icon = "🔔",
                label = "NOTIF",
                isActive = notifMode == MODE_NOTIF_ONLY,
                modifier = Modifier.weight(1f),
                onClick = {
                    notifMode = MODE_NOTIF_ONLY
                    prefs.edit().putString(KEY_NOTIF_MODE, MODE_NOTIF_ONLY).apply()
                    if (adzanEnabled) rescheduleAdhan(context, state)
                }
            )
            ModeButton(
                icon = "🔊",
                label = "SOUND",
                isActive = notifMode == MODE_NOTIF_SOUND,
                modifier = Modifier.weight(1f),
                onClick = {
                    notifMode = MODE_NOTIF_SOUND
                    prefs.edit().putString(KEY_NOTIF_MODE, MODE_NOTIF_SOUND).apply()
                    if (!adzanEnabled) {
                        adzanEnabled = true
                        NotificationScheduler.setRemindersEnabled(context, true)
                    }
                    rescheduleAdhan(context, state)
                }
            )
        }
    }
}

@Composable
private fun ModeButton(
    icon: String,
    label: String,
    isActive: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(if (isActive) IslamicGreenDim.copy(alpha = 0.2f) else DarkSurfaceVariant)
            .border(
                1.dp,
                if (isActive) IslamicGreenDim.copy(alpha = 0.5f) else OutlineVariant.copy(alpha = 0.5f),
                RoundedCornerShape(8.dp)
            )
            .clickable { onClick() }
            .padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = icon, fontSize = 18.sp)
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            color = if (isActive) IslamicGreen else TextMuted,
            letterSpacing = 1.sp,
            fontFamily = FontFamily.Monospace
        )
    }
}

// ─── Helpers ───

private fun rescheduleAdhan(context: Context, state: MuslimLevelingData) {
    if (state.user.kota.isEmpty()) return
    val timings = mapOf(
        "subuh" to state.prayerTimesCache.timings.subuh,
        "dzuhur" to state.prayerTimesCache.timings.dzuhur,
        "ashar" to state.prayerTimesCache.timings.ashar,
        "maghrib" to state.prayerTimesCache.timings.maghrib,
        "isya" to state.prayerTimesCache.timings.isya
    )
    NotificationScheduler.scheduleAdhanReminders(context, state.user.kota, timings)
}
