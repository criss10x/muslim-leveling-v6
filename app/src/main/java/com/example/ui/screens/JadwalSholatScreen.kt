package com.example.ui.screens

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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.MuslimLevelingData
import com.example.data.capitalizeCompat
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

// ═══════════════════════════════════════════════════════════════
// JADWAL SHOLAT SCREEN
// Menampilkan jadwal 5 waktu sholat untuk kota user.
// Highlight sholat aktif/berikutnya, tampilkan countdown.
// ═══════════════════════════════════════════════════════════════

private val ArenaBorder = TextLight.copy(alpha = 0.08f)

@Composable
fun JadwalSholatScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    val scrollState = rememberScrollState()
    val today = LocalDate.now()
    val todayStr = today.toString()
    val dateFormatter = DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy")
    val todayFormatted = today.format(dateFormatter)

    val timings = state.prayerTimesCache.timings
    val prayers = listOf(
        Triple("subuh", "Subuh", timings.subuh),
        Triple("dzuhur", "Dzuhur", timings.dzuhur),
        Triple("ashar", "Ashar", timings.ashar),
        Triple("maghrib", "Maghrib", timings.maghrib),
        Triple("isya", "Isya", timings.isya)
    )

    // Cari sholat berikutnya & aktif
    val now = LocalTime.now()
    val nextPrayer = prayers.firstOrNull { (_, _, timeStr) ->
        try {
            LocalTime.parse(timeStr, DateTimeFormatter.ofPattern("HH:mm")).isAfter(now)
        } catch (e: Exception) { false }
    } ?: prayers.first() // wrap ke subuh besok

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
            SectionTitlePill(text = "JADWAL SHOLAT", gradient = GradientGreenGold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "🕐 Waktu Sholat",
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                color = TextLight,
                textAlign = TextAlign.Center
            )
            Text(
                text = todayFormatted,
                fontSize = 12.sp,
                color = GoldAccent,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp)
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Kota info
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "📍 ${state.user.kota}",
                    fontSize = 14.sp,
                    color = IslamicGreen,
                    fontWeight = FontWeight.Bold
                )
            }

            // Cache date check
            if (state.prayerTimesCache.date != todayStr) {
                Spacer(modifier = Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(AmberFlame.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
                        .border(1.dp, AmberFlame.copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                        .padding(12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "⚠️ Jadwal belum ter-update hari ini. Buka tab Profil → ubah kota untuk refresh.",
                        fontSize = 11.sp,
                        color = AmberFlame,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ─── Countdown next prayer ───
            NextPrayerCountdownCard(
                nextPrayerName = nextPrayer.second,
                nextPrayerTime = nextPrayer.third,
                now = now
            )

            Spacer(modifier = Modifier.height(24.dp))

            // ─── Prayer schedule list ───
            SectionTitlePill(text = "5 WAKTU SHOLAT", gradient = GradientGoldAmber)
            Spacer(modifier = Modifier.height(12.dp))

            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                prayers.forEach { (id, name, timeStr) ->
                    val isNext = id == nextPrayer.first
                    val isLogged = state.prayerLog.any { it.date == todayStr && it.prayer == id }
                    PrayerScheduleRow(
                        name = name,
                        time = timeStr,
                        isNext = isNext,
                        isLogged = isLogged
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ─── Info card ───
            val cardShape = RoundedCornerShape(16.dp)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = cardShape,
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, ArenaBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "ℹ️ Info",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = GoldAccent
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Jadwal sholat diambil dari API Aladhan berdasarkan kota yang dipilih di profil. Data otomatis ter-update tiap hari saat app dibuka.",
                        fontSize = 11.sp,
                        color = TextMuted,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "💡 Untuk ganti kota, buka tab Profil → Pengaturan → pilih kota.",
                        fontSize = 11.sp,
                        color = IslamicGreen,
                        lineHeight = 16.sp
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// NEXT PRAYER COUNTDOWN CARD
// ═══════════════════════════════════════════════════════════════

@Composable
private fun NextPrayerCountdownCard(
    nextPrayerName: String,
    nextPrayerTime: String,
    now: LocalTime
) {
    val cardShape = RoundedCornerShape(20.dp)

    // Hitung countdown
    val countdownText = remember(nextPrayerTime, now) {
        try {
            val prayerTime = LocalTime.parse(nextPrayerTime, DateTimeFormatter.ofPattern("HH:mm"))
            val diff = ChronoUnit.HOURS.between(now, prayerTime)
            val diffMinutes = ChronoUnit.MINUTES.between(now, prayerTime) % 60
            if (diff < 0) {
                // Sudah lewat hari ini, berarti besok
                "${24 + diff}j ${diffMinutes}m lagi"
            } else {
                "${diff}j ${diffMinutes}m lagi"
            }
        } catch (e: Exception) {
            "--"
        }
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(18.dp, cardShape, ambientColor = IslamicGreen.copy(alpha = 0.3f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = androidx.compose.foundation.BorderStroke(
            1.5.dp,
            Brush.linearGradient(listOf(IslamicGreen, CyanAccent, IslamicGreen))
        )
    ) {
        Box(
            modifier = Modifier
                .background(Brush.verticalGradient(GradientDarkSurface))
                .padding(20.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "SHOLAT BERIKUTNYA",
                    fontSize = 10.sp,
                    color = TextMuted,
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = 1.5.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "🕌 ${nextPrayerName}",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Black,
                    color = IslamicGreen
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = nextPrayerTime,
                    fontSize = 20.sp,
                    color = GoldAccent,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
                Spacer(modifier = Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .background(IslamicGreen.copy(alpha = 0.12f), RoundedCornerShape(100.dp))
                        .border(1.dp, IslamicGreen.copy(alpha = 0.3f), RoundedCornerShape(100.dp))
                        .padding(horizontal = 16.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = "⏳ $countdownText",
                        fontSize = 14.sp,
                        color = IslamicGreen,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PRAYER SCHEDULE ROW
// ═══════════════════════════════════════════════════════════════

@Composable
private fun PrayerScheduleRow(
    name: String,
    time: String,
    isNext: Boolean,
    isLogged: Boolean
) {
    val accentColor = when {
        isNext -> IslamicGreen
        isLogged -> GoldAccent
        else -> TextMuted
    }
    val cardShape = RoundedCornerShape(14.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("schedule_row_${name.lowercase()}")
            .then(
                if (isNext) Modifier.shadow(12.dp, cardShape, ambientColor = IslamicGreen.copy(alpha = 0.35f))
                else Modifier
            ),
        shape = cardShape,
        colors = CardDefaults.cardColors(
            containerColor = if (isNext) DarkSurface else DarkSurface.copy(alpha = 0.7f)
        ),
        border = androidx.compose.foundation.BorderStroke(
            if (isNext) 1.5.dp else 1.dp,
            if (isNext) Brush.linearGradient(listOf(IslamicGreen.copy(alpha = 0.6f), CyanAccent.copy(alpha = 0.3f)))
            else Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Icon
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(accentColor.copy(alpha = 0.12f))
                        .border(1.dp, accentColor.copy(alpha = 0.3f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    val icon = when (name.lowercase()) {
                        "subuh" -> "🌅"
                        "dzuhur" -> "☀️"
                        "ashar" -> "🌤️"
                        "maghrib" -> "🌇"
                        "isya" -> "🌙"
                        else -> "🕌"
                    }
                    Text(text = icon, fontSize = 18.sp)
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        text = name,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isNext) IslamicGreen else TextLight
                    )
                    if (isNext) {
                        Text(
                            text = "Berikutnya",
                            fontSize = 9.sp,
                            color = IslamicGreen.copy(alpha = 0.8f),
                            fontWeight = FontWeight.Medium
                        )
                    } else if (isLogged) {
                        Text(
                            text = "✓ Sudah dilog",
                            fontSize = 9.sp,
                            color = GoldAccent.copy(alpha = 0.8f),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Time
            Text(
                text = time,
                fontSize = 20.sp,
                fontWeight = FontWeight.Black,
                color = accentColor,
                fontFamily = FontFamily.Monospace
            )
        }
    }
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
