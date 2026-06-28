package com.example.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.theme.*
import java.time.LocalDate
import java.time.YearMonth

// ═══════════════════════════════════════════════════════════════
// STATISTIK MINGGUAN — BOTTOM SHEET (Nur Quest redesign 2026-06-28)
// Matches Stitch mockup statistik_mingguan_bottom_sheet:
// drag handle + teal title + X close, XP HARIAN bar chart,
// 2-col Win Rate / Streak, Total XP Bulan Ini with trend.
// All charts Canvas-drawn (no external lib).
// ═══════════════════════════════════════════════════════════════

private val GlassBorder = OutlineVariant.copy(alpha = 0.3f)

private val WAJIB_PRAYERS = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")

// Day labels in Stitch mockup order (oldest → today). Bahasa Indonesia.
private val DAY_LABELS_ID = listOf("SEN", "SEL", "RAB", "KAM", "JUM", "SAB", "MIN")

// Day-of-week index for last 7 days, used to find "today" bar.
private fun todayDayOfWeekIndex(): Int = LocalDate.now().dayOfWeek.value - 1 // MON=0..SUN=6

/**
 * Modal Bottom Sheet — statistik mingguan.
 * Dipanggil dari ProfileScreen via tombol "Lihat Statistik 📊".
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatistikBottomSheet(
    state: MuslimLevelingData,
    onDismiss: () -> Unit
) {
    val modalSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scrollState = rememberScrollState()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = modalSheetState,
        shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp),
        containerColor = DarkSurface,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 12.dp)
                    .width(64.dp)
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(OutlineVariant)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(scrollState)
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {
            // ─── Header (teal title + subtitle + close button) ───
            StatistikHeader(onClose = onDismiss)

            Spacer(modifier = Modifier.height(24.dp))

            // ─── Compute stats ───
            val last7Days = remember(state.prayerLog) { getLast7DaysCompletion(state.prayerLog) }
            val winRate = remember(state.prayerLog) { getOverallWinRate(state.prayerLog) }
            val streak = remember(state.prayerLog) { getLongestHeroStreak(state.prayerLog) }
            val xpThisMonth = remember(state.prayerLog) { getXpThisMonth(state.prayerLog) }
            val xpTrendPct = remember(state.prayerLog) { getXpTrendPercent(state.prayerLog) }

            // ─── XP HARIAN (7 HARI TERAKHIR) ───
            XpDailyChartCard(last7Days = last7Days)

            Spacer(modifier = Modifier.height(12.dp))

            // ─── 2-col: Win Rate + Streak ───
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                WinRateCard(
                    winRate = winRate,
                    modifier = Modifier.weight(1f)
                )
                StreakCard(
                    streak = streak,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // ─── Total XP Bulan Ini (with trend) ───
            TotalXpMonthCard(
                xp = xpThisMonth,
                trendPct = xpTrendPct
            )

            Spacer(modifier = Modifier.height(20.dp))

            // ─── Action button: "Lanjutkan Perjalanan" (teal gradient, on-primary text) ───
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(
                        10.dp,
                        RoundedCornerShape(12.dp),
                        ambientColor = IslamicGreen.copy(alpha = 0.30f)
                    )
                    .clip(RoundedCornerShape(12.dp))
                    .background(Brush.horizontalGradient(listOf(IslamicGreen, IslamicGreenDim)))
                    .clickable { onDismiss() }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Lanjutkan Perjalanan",
                    color = Color(0xFF003828), // on-primary
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// HEADER — Statistik Mingguan + subtitle + X close button
// ═══════════════════════════════════════════════════════════════

@Composable
private fun StatistikHeader(onClose: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Statistik Mingguan",
                style = MaterialTheme.typography.headlineMedium,
                color = IslamicGreen,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Laporan Perjalanan Spiritual",
                style = MaterialTheme.typography.bodyMedium,
                color = TextMuted,
                fontSize = 14.sp
            )
        }
        // Close button (circular, X)
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(DarkSurfaceVariant)
                .border(1.dp, OutlineVariant.copy(alpha = 0.5f), CircleShape)
                .clickable(onClick = onClose),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "✕",
                color = TextLight,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// XP HARIAN CHART CARD — 7 bars SEN..MIN, today = teal
// ═══════════════════════════════════════════════════════════════

@Composable
private fun XpDailyChartCard(last7Days: List<DayCompletion>) {
    val todayIdx = todayDayOfWeekIndex()
    // Map last-7-day bars to day labels: bar index 0 = 6 days ago, bar 6 = today.
    // Each bar's day-of-week = (todayIdx - (6 - barIndex) + 7) % 7 → matches DAY_LABELS_ID index.
    val barDayIndices = (0..6).map { i -> (todayIdx - (6 - i) + 7) % 7 }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(DarkSurface)
            .border(1.dp, GlassBorder, RoundedCornerShape(16.dp))
            .padding(20.dp)
    ) {
        // Label-caps header: 📈 XP HARIAN (7 HARI TERAKHIR)
        Text(
            text = "📈 XP HARIAN (7 HARI TERAKHIR)",
            style = MaterialTheme.typography.labelMedium,
            color = TextMuted,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.2.sp
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Bar chart canvas — height matches mockup (h-40 = 160px)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
        ) {
            WeeklyBarChart(
                values = last7Days.map { it.completedCount.toFloat() },
                dayIndices = barDayIndices,
                todayIdx = todayIdx,
                maxValue = 5f
            )
        }
    }
}

@Composable
private fun WeeklyBarChart(
    values: List<Float>,
    dayIndices: List<Int>,
    todayIdx: Int,
    maxValue: Float
) {
    val animProgress = remember { Animatable(0f) }
    LaunchedEffect(values) {
        animProgress.snapTo(0f)
        animProgress.animateTo(1f, tween(900, easing = FastOutSlowInEasing))
    }

    Canvas(modifier = Modifier.fillMaxSize()) {
        val barCount = values.size
        val canvasWidth = size.width
        val canvasHeight = size.height
        val labelHeight = 28f
        val chartHeight = canvasHeight - labelHeight
        val barSpacing = 12f
        val barWidth = (canvasWidth - barSpacing * (barCount + 1)) / barCount

        values.forEachIndexed { index, value ->
            val animatedValue = value * animProgress.value
            val barHeight = (animatedValue / maxValue) * chartHeight
            val x = barSpacing + index * (barWidth + barSpacing)
            val y = chartHeight - barHeight

            // Today's bar = teal+cyan gradient, others = dim teal
            val isToday = dayIndices[index] == todayIdx
            val barColor = if (isToday) IslamicGreen else IslamicGreenDim
            val barGradient = Brush.verticalGradient(
                colors = if (isToday) {
                    listOf(CyanAccent, IslamicGreen)
                } else {
                    listOf(barColor, barColor.copy(alpha = 0.3f))
                },
                startY = y,
                endY = chartHeight
            )

            // Track background (surface-container-highest)
            drawRoundRect(
                color = DarkSurfaceVariant.copy(alpha = 0.5f),
                topLeft = Offset(x, 0f),
                size = Size(barWidth, chartHeight),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f, 4f)
            )

            // Bar fill
            if (barHeight > 0f) {
                drawRoundRect(
                    brush = barGradient,
                    topLeft = Offset(x, y),
                    size = Size(barWidth, barHeight),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f, 4f)
                )
            }

            // Day label below — today in cyan, others muted
            drawIntoCanvas {
                val paint = android.graphics.Paint().apply {
                    color = (if (isToday) CyanAccent else TextMuted).toArgb()
                    textSize = 26f
                    isAntiAlias = true
                    textAlign = android.graphics.Paint.Align.CENTER
                    typeface = android.graphics.Typeface.DEFAULT_BOLD
                }
                it.nativeCanvas.drawText(
                    DAY_LABELS_ID[dayIndices[index]],
                    x + barWidth / 2f,
                    canvasHeight - 4f,
                    paint
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// WIN RATE CARD — ✓ + 95% + "Wajib Sholat"
// ═══════════════════════════════════════════════════════════════

@Composable
private fun WinRateCard(winRate: Float, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(DarkSurface)
            .border(1.dp, GlassBorder, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Header: ✓ Win Rate
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(text = "✓", color = TextMuted, fontSize = 16.sp)
            Text(
                text = "Win Rate",
                style = MaterialTheme.typography.labelMedium,
                color = TextMuted,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        Column {
            Text(
                text = "${winRate.toInt()}%",
                style = MaterialTheme.typography.headlineMedium,
                color = TextLight,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Wajib Sholat",
                style = MaterialTheme.typography.bodyMedium,
                color = IslamicGreen,
                fontSize = 14.sp
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// STREAK CARD — gold border, 🔥, "7 HARI" gold, "Menyala 🔥"
// ═══════════════════════════════════════════════════════════════

@Composable
private fun StreakCard(streak: Int, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(DarkSurface, DarkSurfaceElevated)
                )
            )
            .border(1.dp, GoldAccent.copy(alpha = 0.3f), RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Header: 🔥 Streak (gold)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(text = "🔥", fontSize = 16.sp)
            Text(
                text = "Streak",
                style = MaterialTheme.typography.labelMedium,
                color = GoldAccent,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        Column {
            Text(
                text = "$streak HARI",
                style = MaterialTheme.typography.headlineMedium,
                color = GoldAccent,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Menyala 🔥",
                style = MaterialTheme.typography.bodyMedium,
                color = TextMuted,
                fontSize = 14.sp
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// TOTAL XP BULAN INI — label + "2,450 XP" (XP teal) + 📈 +12%
// ═══════════════════════════════════════════════════════════════

@Composable
private fun TotalXpMonthCard(xp: Int, trendPct: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(DarkSurface)
            .border(1.dp, GlassBorder, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Left: ⭐ icon + label + value
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(DarkSurfaceVariant)
                    .border(1.dp, IslamicGreen.copy(alpha = 0.2f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "⭐", fontSize = 22.sp)
            }
            Column {
                Text(
                    text = "Total XP Bulan Ini",
                    style = MaterialTheme.typography.labelMedium,
                    color = TextMuted,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = formatXp(xp),
                        style = MaterialTheme.typography.headlineLarge,
                        color = TextLight,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "XP",
                        color = IslamicGreen,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(bottom = 4.dp)
                    )
                }
            }
        }

        // Right: 📈 + trend %
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(text = "📈", fontSize = 18.sp)
            Text(
                text = "+$trendPct%",
                style = MaterialTheme.typography.labelSmall,
                color = CyanAccent,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

private fun formatXp(xp: Int): String {
    return "%,d".format(xp)
}

// ═══════════════════════════════════════════════════════════════
// DATA COMPUTATION
// ═══════════════════════════════════════════════════════════════

data class DayCompletion(
    val date: LocalDate,
    val completedCount: Int  // 0..5 (out of 5 wajib prayers)
)

/**
 * Completion count per day for the last 7 days (oldest first).
 */
fun getLast7DaysCompletion(log: List<PrayerLog>): List<DayCompletion> {
    val today = LocalDate.now()
    val result = mutableListOf<DayCompletion>()

    for (offset in 6 downTo 0) {
        val date = today.minusDays(offset.toLong())
        val dateStr = date.toString()
        val completed = WAJIB_PRAYERS.count { prayer ->
            log.any { it.date == dateStr && it.prayer == prayer && it.type == "wajib" }
        }
        result.add(DayCompletion(date = date, completedCount = completed))
    }

    return result
}

/**
 * Overall win rate for wajib prayers over last 7 days (0..100).
 * = total completed / (5 prayers × 7 days) × 100.
 */
fun getOverallWinRate(log: List<PrayerLog>): Float {
    val today = LocalDate.now()
    val last7Dates = (0..6).map { today.minusDays(it.toLong()).toString() }.toSet()
    val completed = WAJIB_PRAYERS.sumOf { prayer ->
        last7Dates.count { dateStr ->
            log.any { it.date == dateStr && it.prayer == prayer && it.type == "wajib" }
        }
    }
    return (completed.toFloat() / (WAJIB_PRAYERS.size * 7f)) * 100f
}

/**
 * Longest hero streak (consecutive days all 5 wajib completed).
 * ponytail: longest-streak shown in the "Streak" card. Real "current"
 * streak needs a separate helper when product wants live streak —
 * longest streak is a fine stand-in until then.
 */
fun getLongestHeroStreak(log: List<PrayerLog>): Int {
    if (log.isEmpty()) return 0

    val wajibByDate = log
        .filter { it.type == "wajib" && WAJIB_PRAYERS.contains(it.prayer) }
        .groupBy { it.date }
        .mapValues { (_, entries) -> entries.map { it.prayer }.toSet() }

    val fullDates = wajibByDate
        .filter { (_, prayers) -> WAJIB_PRAYERS.all { it in prayers } }
        .keys
        .mapNotNull { runCatching { LocalDate.parse(it) }.getOrNull() }
        .sorted()

    if (fullDates.isEmpty()) return 0

    var longest = 1
    var current = 1

    for (i in 1 until fullDates.size) {
        if (fullDates[i] == fullDates[i - 1].plusDays(1)) {
            current++
            longest = maxOf(longest, current)
        } else {
            current = 1
        }
    }

    return longest
}

/**
 * Total XP earned this month.
 * XP per prayer: subuh=30, dzuhur=20, ashar=20, maghrib=25, isya=25
 * +50 bonus for 5/5 completion.
 */
fun getXpThisMonth(log: List<PrayerLog>): Int {
    val now = LocalDate.now()
    val yearMonth = YearMonth.now()
    val firstOfMonth = yearMonth.atDay(1)

    var totalXp = 0

    var date = firstOfMonth
    while (!date.isAfter(now)) {
        totalXp += dayXp(log, date.toString())
        date = date.plusDays(1)
    }

    return totalXp
}

/**
 * Month-over-month XP trend percent (this month vs last month, 0 if no baseline).
 * ponytail: returns 0 when last month had no XP — avoids div-by-zero and
 * avoids showing a misleading +∞. Replace with a real baseline when analytics needs it.
 */
fun getXpTrendPercent(log: List<PrayerLog>): Int {
    val now = LocalDate.now()
    val thisMonth = YearMonth.now()
    val lastMonth = thisMonth.minusMonths(1)

    val thisXp = monthXp(log, thisMonth, now)
    val lastXp = monthXp(log, lastMonth, lastMonth.atEndOfMonth())

    if (lastXp <= 0) return 0
    val pct = ((thisXp - lastXp).toFloat() / lastXp.toFloat()) * 100f
    return pct.toInt().coerceAtLeast(0)
}

private fun monthXp(log: List<PrayerLog>, ym: YearMonth, upTo: LocalDate): Int {
    var xp = 0
    var date = ym.atDay(1)
    while (!date.isAfter(upTo)) {
        xp += dayXp(log, date.toString())
        date = date.plusDays(1)
    }
    return xp
}

private fun dayXp(log: List<PrayerLog>, dateStr: String): Int {
    val dayLogs = log.filter { it.date == dateStr && it.type == "wajib" }
    val prayersDone = dayLogs.map { it.prayer }.toSet()

    var xp = 0
    prayersDone.forEach { prayer ->
        xp += when (prayer) {
            "subuh" -> 30
            "dzuhur" -> 20
            "ashar" -> 20
            "maghrib" -> 25
            "isya" -> 25
            else -> 0
        }
    }

    if (WAJIB_PRAYERS.all { it in prayersDone }) {
        xp += 50
    }

    return xp
}
