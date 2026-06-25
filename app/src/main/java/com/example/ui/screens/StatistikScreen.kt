package com.example.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.theme.*
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

// ═══════════════════════════════════════════════════════════════
// ARENA HIKMAH — STATISTIK BOTTOM SHEET (Weekly Recap)
// Dipanggil dari ProfileScreen via tombol "Lihat Statistik 📊"
// Gen Z vibes: bar chart konsistensi, win rate per sholat,
// streak terpanjang, total XP bulan ini.
// All charts drawn with Canvas (no external lib).
// ═══════════════════════════════════════════════════════════════

private val ArenaBorder = TextLight.copy(alpha = 0.08f)

private val WAJIB_PRAYERS = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
private val PRAYER_LABELS = mapOf(
    "subuh" to "Subuh",
    "dzuhur" to "Dzuhur",
    "ashar" to "Ashar",
    "maghrib" to "Maghrib",
    "isya" to "Isya"
)
private val PRAYER_EMOJI = mapOf(
    "subuh" to "🌅",
    "dzuhur" to "☀️",
    "ashar" to "🌇",
    "maghrib" to "🌆",
    "isya" to "🌙"
)
private val PRAYER_ACCENT = mapOf(
    "subuh" to GoldAccent,
    "dzuhur" to IslamicGreen,
    "ashar" to CyanAccent,
    "maghrib" to RingRed,
    "isya" to PurpleNeon
)

/**
 * Modal Bottom Sheet yang menampilkan statistik mingguan/bulanan.
 * Dipanggil dari ProfileScreen.
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
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        containerColor = DarkBackground,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 12.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(TextMuted.copy(alpha = 0.5f))
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(scrollState)
                .padding(horizontal = 16.dp)
                .padding(bottom = 40.dp)
        ) {
            // ─── Header ───
            StatistikHeader()

            Spacer(modifier = Modifier.height(20.dp))

            // ─── Compute stats ───
            val last7Days = remember(state.prayerLog) { getLast7DaysCompletion(state.prayerLog) }
            val winRates = remember(state.prayerLog) { getWinRatePerPrayer(state.prayerLog) }
            val longestStreak = remember(state.prayerLog) { getLongestHeroStreak(state.prayerLog) }
            val xpThisMonth = remember(state.prayerLog) { getXpThisMonth(state.prayerLog) }
            val xpByWeek = remember(state.prayerLog) { getXpByWeek(state.prayerLog) }

            // ─── Weekly Bar Chart ───
            WeeklyBarChartCard(last7Days = last7Days)

            Spacer(modifier = Modifier.height(16.dp))

            // ─── Win Rate per Sholat ───
            WinRatePerPrayerCard(winRates = winRates)

            Spacer(modifier = Modifier.height(16.dp))

            // ─── Streak & XP Month cards (2 col) ───
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                LongestStreakCard(
                    streak = longestStreak,
                    modifier = Modifier.weight(1f)
                )
                XpThisMonthCard(
                    xp = xpThisMonth,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // ─── XP by Week (4 minggu terakhir) ───
            XpByWeekCard(weeklyXp = xpByWeek)

            Spacer(modifier = Modifier.height(20.dp))

            // ─── Insight / Recommendation ───
            InsightCard(
                winRates = winRates,
                last7Days = last7Days
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════

@Composable
private fun StatistikHeader() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "📊",
            fontSize = 40.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "STATISTIK",
            fontSize = 24.sp,
            fontWeight = FontWeight.Black,
            color = TextLight,
            letterSpacing = 2.sp
        )
        Text(
            text = "Recap performa sholat kamu",
            fontSize = 12.sp,
            color = TextMuted
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// WEEKLY BAR CHART — 7 hari terakhir
// ═══════════════════════════════════════════════════════════════

@Composable
private fun WeeklyBarChartCard(last7Days: List<DayCompletion>) {
    val today = LocalDate.now()
    val dayLabels = (0..6).map { offset ->
        val date = today.minusDays((6 - offset).toLong())
        date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale("id", "ID"))
            .take(3)
            .uppercase()
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(DarkSurface.copy(alpha = 0.6f))
            .border(1.dp, ArenaBorder, RoundedCornerShape(20.dp))
            .padding(20.dp)
    ) {
        Text(
            text = "KONSISTENSI 7 HARI",
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = IslamicGreen,
            letterSpacing = 1.5.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Berapa sholat wajib kamu lengkapi tiap hari",
            fontSize = 11.sp,
            color = TextMuted
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Bar chart canvas
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
        ) {
            WeeklyBarChart(
                values = last7Days.map { it.completedCount.toFloat() },
                labels = dayLabels,
                maxValue = 5f
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Summary row
        val totalCompleted = last7Days.sumOf { it.completedCount }
        val totalPossible = 35
        val percent = if (totalPossible > 0) (totalCompleted * 100 / totalPossible) else 0
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            SummaryMiniStat(label = "Minggu ini", value = "$totalCompleted/$totalPossible")
            SummaryMiniStat(label = "Completion", value = "$percent%", accent = IslamicGreen)
        }
    }
}

@Composable
private fun WeeklyBarChart(
    values: List<Float>,
    labels: List<String>,
    maxValue: Float
) {
    val animProgress = remember { Animatable(0f) }
    LaunchedEffect(values) {
        animProgress.snapTo(0f)
        animProgress.animateTo(1f, tween(900, easing = FastOutSlowInEasing))
    }

    Canvas(
        modifier = Modifier.fillMaxSize()
    ) {
        val barCount = values.size
        val canvasWidth = size.width
        val canvasHeight = size.height
        val labelHeight = 28f
        val chartHeight = canvasHeight - labelHeight
        val barSpacing = 12f
        val barWidth = (canvasWidth - barSpacing * (barCount + 1)) / barCount

        // Grid lines (dashed)
        val gridColor = TextLight.copy(alpha = 0.05f)
        for (i in 0..5) {
            val y = chartHeight - (chartHeight * i / 5f)
            drawLine(
                color = gridColor,
                start = Offset(0f, y),
                end = Offset(canvasWidth, y),
                strokeWidth = 1f
            )
        }

        // Bars
        values.forEachIndexed { index, value ->
            val animatedValue = value * animProgress.value
            val barHeight = (animatedValue / maxValue) * chartHeight
            val x = barSpacing + index * (barWidth + barSpacing)
            val y = chartHeight - barHeight

            // Bar with gradient
            val isToday = index == barCount - 1
            val barColor = if (isToday) IslamicGreen else IslamicGreenDim
            val barGradient = Brush.verticalGradient(
                colors = listOf(
                    barColor,
                    barColor.copy(alpha = 0.3f)
                ),
                startY = y,
                endY = chartHeight
            )

            drawRoundRect(
                brush = barGradient,
                topLeft = Offset(x, y),
                size = Size(barWidth, barHeight),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(6f, 6f)
            )

            // Value label on top of bar
            if (animatedValue > 0) {
                drawIntoCanvas {
                    val paint = android.graphics.Paint().apply {
                        color = barColor.toArgb()
                        textSize = 28f
                        isAntiAlias = true
                        textAlign = android.graphics.Paint.Align.CENTER
                        typeface = android.graphics.Typeface.DEFAULT_BOLD
                    }
                    it.nativeCanvas.drawText(
                        "${value.toInt()}",
                        x + barWidth / 2f,
                        y - 6f,
                        paint
                    )
                }
            }

            // Day label below
            drawIntoCanvas {
                val paint = android.graphics.Paint().apply {
                    color = (if (isToday) IslamicGreen else TextMuted).toArgb()
                    textSize = 26f
                    isAntiAlias = true
                    textAlign = android.graphics.Paint.Align.CENTER
                }
                it.nativeCanvas.drawText(
                    labels[index],
                    x + barWidth / 2f,
                    canvasHeight - 4f,
                    paint
                )
            }
        }
    }
}

@Composable
private fun SummaryMiniStat(label: String, value: String, accent: Color = TextLight) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = accent
        )
        Text(
            text = label,
            fontSize = 10.sp,
            color = TextMuted
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// WIN RATE PER SHOLAT
// ═══════════════════════════════════════════════════════════════

@Composable
private fun WinRatePerPrayerCard(winRates: List<PrayerWinRate>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(DarkSurface.copy(alpha = 0.6f))
            .border(1.dp, ArenaBorder, RoundedCornerShape(20.dp))
            .padding(20.dp)
    ) {
        Text(
            text = "WIN RATE PER SHOLAT",
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            letterSpacing = 1.5.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Persentase kehadiran 7 hari terakhir",
            fontSize = 11.sp,
            color = TextMuted
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Find worst prayer (most missed)
        val worstPrayer = winRates.minByOrNull { it.winRate }

        winRates.forEach { rate ->
            Spacer(modifier = Modifier.height(8.dp))
            WinRateRow(rate = rate)
        }

        if (worstPrayer != null && worstPrayer.winRate < 100f) {
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(RingRed.copy(alpha = 0.1f))
                    .border(1.dp, RingRed.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "⚠️",
                    fontSize = 16.sp,
                    modifier = Modifier.padding(end = 8.dp)
                )
                Text(
                    text = "${PRAYER_LABELS[worstPrayer.prayer]} paling sering miss (${worstPrayer.winRate.toInt()}%). Gas semangat lagi! 💪",
                    fontSize = 11.sp,
                    color = TextLight
                )
            }
        }
    }
}

@Composable
private fun WinRateRow(rate: PrayerWinRate) {
    val accentColor = PRAYER_ACCENT[rate.prayer] ?: IslamicGreen
    val animProgress = remember { Animatable(0f) }
    LaunchedEffect(rate.winRate) {
        animProgress.snapTo(0f)
        animProgress.animateTo(1f, tween(700, easing = FastOutSlowInEasing))
    }

    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = PRAYER_EMOJI[rate.prayer] ?: "🕌",
                    fontSize = 14.sp,
                    modifier = Modifier.padding(end = 6.dp)
                )
                Text(
                    text = PRAYER_LABELS[rate.prayer] ?: rate.prayer,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextLight
                )
            }
            Text(
                text = "${rate.winRate.toInt()}%",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = if (rate.winRate >= 80f) IslamicGreen else if (rate.winRate >= 50f) GoldAccent else RingRed
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Progress bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(TextLight.copy(alpha = 0.06f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(rate.winRate / 100f * animProgress.value)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(4.dp))
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(accentColor.copy(alpha = 0.6f), accentColor)
                        )
                    )
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// LONGEST STREAK CARD
// ═══════════════════════════════════════════════════════════════

@Composable
private fun LongestStreakCard(streak: Int, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(DarkSurface.copy(alpha = 0.6f))
            .border(1.dp, ArenaBorder, RoundedCornerShape(16.dp))
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "🔥",
            fontSize = 28.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "STREAK TERPANJANG",
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            textAlign = TextAlign.Center,
            letterSpacing = 1.sp
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = "$streak",
            fontSize = 32.sp,
            fontWeight = FontWeight.Black,
            color = GoldAccent
        )
        Text(
            text = "hari berturut-turut",
            fontSize = 10.sp,
            color = TextMuted,
            textAlign = TextAlign.Center
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// XP THIS MONTH CARD
// ═══════════════════════════════════════════════════════════════

@Composable
private fun XpThisMonthCard(xp: Int, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(DarkSurface.copy(alpha = 0.6f))
            .border(1.dp, ArenaBorder, RoundedCornerShape(16.dp))
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "⚡",
            fontSize = 28.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "XP BULAN INI",
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            color = IslamicGreen,
            textAlign = TextAlign.Center,
            letterSpacing = 1.sp
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = formatXp(xp),
            fontSize = 28.sp,
            fontWeight = FontWeight.Black,
            color = IslamicGreen
        )
        Text(
            text = "XP didapat",
            fontSize = 10.sp,
            color = TextMuted,
            textAlign = TextAlign.Center
        )
    }
}

private fun formatXp(xp: Int): String {
    return if (xp >= 1000) "${xp / 1000}.${(xp % 1000) / 100}K" else "$xp"
}

// ═══════════════════════════════════════════════════════════════
// XP BY WEEK (4 minggu terakhir) — mini line chart
// ═══════════════════════════════════════════════════════════════

@Composable
private fun XpByWeekCard(weeklyXp: List<Int>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(DarkSurface.copy(alpha = 0.6f))
            .border(1.dp, ArenaBorder, RoundedCornerShape(20.dp))
            .padding(20.dp)
    ) {
        Text(
            text = "XP 4 MINGGU TERAKHIR",
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = CyanAccent,
            letterSpacing = 1.5.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Tren XP yang kamu kumpulkan per minggu",
            fontSize = 11.sp,
            color = TextMuted
        )

        Spacer(modifier = Modifier.height(16.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(120.dp)
        ) {
            XpLineChart(values = weeklyXp.map { it.toFloat() })
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Week labels
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            weeklyXp.indices.forEach { i ->
                Text(
                    text = "W${i + 1}",
                    fontSize = 10.sp,
                    color = TextMuted
                )
            }
        }
    }
}

@Composable
private fun XpLineChart(values: List<Float>) {
    val animProgress = remember { Animatable(0f) }
    LaunchedEffect(values) {
        animProgress.snapTo(0f)
        animProgress.animateTo(1f, tween(900, easing = FastOutSlowInEasing))
    }

    Canvas(modifier = Modifier.fillMaxSize()) {
        val canvasWidth = size.width
        val canvasHeight = size.height
        val padding = 20f
        val chartWidth = canvasWidth - padding * 2
        val chartHeight = canvasHeight - padding * 2

        val maxValue = (values.maxOrNull() ?: 1f).coerceAtLeast(1f)

        // Grid lines
        val gridColor = TextLight.copy(alpha = 0.05f)
        for (i in 0..3) {
            val y = padding + chartHeight * i / 3f
            drawLine(
                color = gridColor,
                start = Offset(padding, y),
                end = Offset(canvasWidth - padding, y),
                strokeWidth = 1f
            )
        }

        if (values.size < 2) return@Canvas

        // Points
        val points = values.mapIndexed { index, value ->
            val x = padding + (chartWidth * index / (values.size - 1))
            val y = padding + chartHeight - (chartHeight * value / maxValue) * animProgress.value
            Offset(x, y)
        }

        // Filled area under line
        val path = Path().apply {
            moveTo(points.first().x, canvasHeight - padding)
            points.forEach { lineTo(it.x, it.y) }
            lineTo(points.last().x, canvasHeight - padding)
            close()
        }
        val areaGradient = Brush.verticalGradient(
            colors = listOf(
                IslamicGreen.copy(alpha = 0.3f),
                IslamicGreen.copy(alpha = 0.0f)
            ),
            startY = padding,
            endY = canvasHeight - padding
        )
        drawPath(path = path, brush = areaGradient)

        // Line
        val linePath = Path().apply {
            moveTo(points.first().x, points.first().y)
            points.forEach { lineTo(it.x, it.y) }
        }
        drawPath(
            path = linePath,
            color = IslamicGreen,
            style = Stroke(width = 3f, cap = StrokeCap.Round)
        )

        // Dots
        points.forEach { point ->
            drawCircle(
                color = IslamicGreen,
                radius = 5f,
                center = point
            )
            drawCircle(
                color = Color.White,
                radius = 2f,
                center = point
            )
        }

        // Value labels
        drawIntoCanvas {
            val paint = android.graphics.Paint().apply {
                color = TextLight.toArgb()
                textSize = 26f
                isAntiAlias = true
                textAlign = android.graphics.Paint.Align.CENTER
                typeface = android.graphics.Typeface.DEFAULT_BOLD
            }
            points.forEachIndexed { i, point ->
                it.nativeCanvas.drawText(
                    "${values[i].toInt()}",
                    point.x,
                    point.y - 12f,
                    paint
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// INSIGHT CARD — smart recommendation
// ═══════════════════════════════════════════════════════════════

@Composable
private fun InsightCard(
    winRates: List<PrayerWinRate>,
    last7Days: List<DayCompletion>
) {
    val avgCompletion = if (last7Days.isNotEmpty()) {
        last7Days.map { it.completedCount }.sum().toFloat() / (last7Days.size * 5f) * 100f
    } else 0f

    val insight = when {
        avgCompletion >= 90f -> InsightData(
            icon = "🏆",
            title = "Konsisten Banget!",
            message = "Kamu konsisten 90%+ minggu ini. Pertahankan hero streak kamu ya! 🔥",
            color = GoldAccent
        )
        avgCompletion >= 70f -> InsightData(
            icon = "💪",
            title = "Mantap, Lanjutkan!",
            message = "Kamu di jalur yang benar. Sedikit lagi buat capai 100% konsistensi! 🎯",
            color = IslamicGreen
        )
        avgCompletion >= 40f -> InsightData(
            icon = "📈",
            title = "Lagi Naik Kok",
            message = "Ada progress bagus. Fokus ke sholat yang paling sering miss ya! 💪",
            color = CyanAccent
        )
        else -> InsightData(
            icon = "🚀",
            title = "Gas Dimulai Hari Ini!",
            message = "Mulai dari sholat hari ini. Setiap perjalanan dimulai dari langkah pertama! 🌱",
            color = PurpleNeon
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        insight.color.copy(alpha = 0.15f),
                        DarkSurface.copy(alpha = 0.6f)
                    )
                )
            )
            .border(1.dp, insight.color.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
            .padding(20.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = insight.icon,
                fontSize = 28.sp,
                modifier = Modifier.padding(end = 12.dp)
            )
            Column {
                Text(
                    text = insight.title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = insight.color
                )
                Text(
                    text = insight.message,
                    fontSize = 12.sp,
                    color = TextLight
                )
            }
        }
    }
}

private data class InsightData(
    val icon: String,
    val title: String,
    val message: String,
    val color: Color
)

// ═══════════════════════════════════════════════════════════════
// DATA COMPUTATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════

data class DayCompletion(
    val date: LocalDate,
    val completedCount: Int  // 0..5 (out of 5 wajib prayers)
)

data class PrayerWinRate(
    val prayer: String,
    val winRate: Float,  // 0..100
    val completedDays: Int,
    val totalDays: Int
)

/**
 * Get completion count per day for the last 7 days (oldest first).
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
 * Get win rate per sholat wajib for the last 7 days.
 */
fun getWinRatePerPrayer(log: List<PrayerLog>): List<PrayerWinRate> {
    val today = LocalDate.now()
    val last7Dates = (0..6).map { today.minusDays(it.toLong()).toString() }.toSet()

    return WAJIB_PRAYERS.map { prayer ->
        val completed = last7Dates.count { dateStr ->
            log.any { it.date == dateStr && it.prayer == prayer && it.type == "wajib" }
        }
        val winRate = (completed.toFloat() / 7f) * 100f
        PrayerWinRate(
            prayer = prayer,
            winRate = winRate,
            completedDays = completed,
            totalDays = 7
        )
    }
}

/**
 * Get longest hero streak (consecutive days where all 5 wajib prayers completed).
 * Computed from entire prayer log history.
 */
fun getLongestHeroStreak(log: List<PrayerLog>): Int {
    if (log.isEmpty()) return 0

    // Group by date, check if all 5 wajib completed per day
    val wajibByDate = log
        .filter { it.type == "wajib" && WAJIB_PRAYERS.contains(it.prayer) }
        .groupBy { it.date }
        .mapValues { (_, entries) -> entries.map { it.prayer }.toSet() }

    // Find dates with all 5 prayers
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
 * Get total XP earned this month.
 * XP per prayer: subuh=30, dzuhur=20, ashar=20, maghrib=25, isya=25
 * +50 bonus for 5/5 completion.
 */
fun getXpThisMonth(log: List<PrayerLog>): Int {
    val now = LocalDate.now()
    val yearMonth = YearMonth.now()
    val firstOfMonth = yearMonth.atDay(1)

    var totalXp = 0

    // Iterate days in current month up to today
    var date = firstOfMonth
    while (!date.isAfter(now)) {
        val dateStr = date.toString()
        val dayLogs = log.filter { it.date == dateStr && it.type == "wajib" }
        val prayersDone = dayLogs.map { it.prayer }.toSet()

        var dayXp = 0
        prayersDone.forEach { prayer ->
            dayXp += when (prayer) {
                "subuh" -> 30
                "dzuhur" -> 20
                "ashar" -> 20
                "maghrib" -> 25
                "isya" -> 25
                else -> 0
            }
        }

        // 5/5 bonus
        if (WAJIB_PRAYERS.all { it in prayersDone }) {
            dayXp += 50
        }

        totalXp += dayXp
        date = date.plusDays(1)
    }

    return totalXp
}

/**
 * Get XP per week for the last 4 weeks (oldest first).
 */
fun getXpByWeek(log: List<PrayerLog>): List<Int> {
    val today = LocalDate.now()
    val result = mutableListOf<Int>()

    for (weekOffset in 3 downTo 0) {
        val weekStart = today.minusDays((weekOffset + 1) * 7L - 1)
        val weekEnd = today.minusDays(weekOffset * 7L)

        var weekXp = 0
        var date = weekStart
        while (!date.isAfter(weekEnd)) {
            val dateStr = date.toString()
            val dayLogs = log.filter { it.date == dateStr && it.type == "wajib" }
            val prayersDone = dayLogs.map { it.prayer }.toSet()

            prayersDone.forEach { prayer ->
                weekXp += when (prayer) {
                    "subuh" -> 30
                    "dzuhur" -> 20
                    "ashar" -> 20
                    "maghrib" -> 25
                    "isya" -> 25
                    else -> 0
                }
            }

            if (WAJIB_PRAYERS.all { it in prayersDone }) {
                weekXp += 50
            }

            date = date.plusDays(1)
        }

        result.add(weekXp)
    }

    return result
}
