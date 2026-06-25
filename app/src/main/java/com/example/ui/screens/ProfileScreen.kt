package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
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
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.notifications.NotificationScheduler
import com.example.ui.components.CityDropdownPicker
import com.example.ui.components.NeonProgressBar
import com.example.ui.theme.*
import com.example.viewmodel.*
import java.time.LocalDate

// ═══════════════════════════════════════════════════════════════
// ARENA HIKMAH — PROFILE SCREEN
// Avatar with rotating gradient arc + pulsing glow; per-stat accent
// bars (teal/gold/crimson/violet); achievements grid with X/N counter
// + teal progress; consistency chart with glowing gradient dots;
// per-mode gradient selectors; crimson-glow reset button.
// ═══════════════════════════════════════════════════════════════

// Subtle card border equivalent (rgba(232,237,245,0.08))
private val ArenaBorder = TextLight.copy(alpha = 0.08f)

@Composable
fun ProfileScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    var showResetConfirm by remember { mutableStateOf(false) }
    var isSettingsExpanded by remember { mutableStateOf(false) }

    val context = LocalContext.current
    val scrollState = rememberScrollState()

    val weeklyConsistency = remember(state.prayerLog) {
        getWeeklyConsistency(state.prayerLog)
    }
    val avgFirstHalf = (weeklyConsistency[0] + weeklyConsistency[1]) / 2f
    val avgSecondHalf = (weeklyConsistency[2] + weeklyConsistency[3]) / 2f
    val trendDirection = if (avgSecondHalf >= avgFirstHalf) "naik" else "turun"

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
            ProfileHeaderCard(state = state, viewModel = viewModel)
            Spacer(modifier = Modifier.height(16.dp))

            // ─── STATS ROW: streak (teal), level (gold), freeze (crimson), total (violet) ───
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                SmallStatCard(
                    modifier = Modifier.weight(1f),
                    title = "Streak 5/5",
                    value = "${state.heroStreak.current}",
                    sub = "Hari · Rekor ${state.heroStreak.best}",
                    accentColor = IslamicGreen
                )
                SmallStatCard(
                    modifier = Modifier.weight(1f),
                    title = "Tilawah",
                    value = "${state.tilawahStreak.current}",
                    sub = "Hari · Rekor ${state.tilawahStreak.best}",
                    accentColor = GoldAccent
                )
                SmallStatCard(
                    modifier = Modifier.weight(1f),
                    title = "Freeze",
                    value = if (state.heroStreak.freezeAvailable) "1" else "0",
                    sub = "Tersedia",
                    accentColor = RingRed
                )
                SmallStatCard(
                    modifier = Modifier.weight(1f),
                    title = "Total XP",
                    value = "${state.user.xp}",
                    sub = "Akumulasi",
                    accentColor = PurpleNeon
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ─── CONSISTENCY CHART ───
            ArenaSectionPill(text = "GRAFIK SHOLAT FARDHU 📊", gradient = GradientGoldAmber, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(10.dp))

            val chartShape = RoundedCornerShape(18.dp)
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("consistency_chart_card")
                    .shadow(14.dp, chartShape, ambientColor = IslamicGreen.copy(alpha = 0.2f)),
                shape = chartShape,
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, ArenaBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Konsistensi kamu $trendDirection dari ${avgFirstHalf.toInt()}% → ${avgSecondHalf.toInt()}% bulan ini",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (avgSecondHalf >= avgFirstHalf) IslamicGreen else RingRed,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    ConsistencyLineChartCanvas(
                        stats = weeklyConsistency,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(120.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ─── ACHIEVEMENTS ───
            ArenaSectionPill(text = "PENCAPAIAN & BADGE 🏆", gradient = GradientGreenGold, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(10.dp))
            AchievementsGrid(unlockedBadges = state.badges)

            Spacer(modifier = Modifier.height(24.dp))

            // ─── REWARDS ───
            ArenaSectionPill(text = "REWARD MINGGU INI 🎁", gradient = GradientGoldAmber, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(10.dp))
            RewardCollectorGallery(collectedRewards = state.rewards)

            Spacer(modifier = Modifier.height(24.dp))

            // ─── COLLAPSIBLE SETTINGS ───
            val settingsShape = RoundedCornerShape(16.dp)
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { isSettingsExpanded = !isSettingsExpanded }
                    .testTag("settings_header_card")
                    .shadow(8.dp, settingsShape, ambientColor = IslamicGreen.copy(alpha = 0.15f)),
                shape = settingsShape,
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, ArenaBorder)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(text = "⚙️", fontSize = 18.sp, modifier = Modifier.padding(end = 8.dp))
                        Text(
                            text = "PENGATURAN 🎮",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextLight
                        )
                    }
                    Icon(
                        imageVector = if (isSettingsExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                        contentDescription = "Expand Settings",
                        tint = GoldAccent
                    )
                }
            }

            AnimatedVisibility(
                visible = isSettingsExpanded,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically() + fadeOut()
            ) {
                Column(modifier = Modifier.fillMaxWidth().padding(top = 10.dp)) {
                    SettingsPanelContent(
                        state = state,
                        viewModel = viewModel,
                        onResetClick = { showResetConfirm = true }
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    if (showResetConfirm) {
        AlertDialog(
            onDismissRequest = { showResetConfirm = false },
            title = { Text("HAPUS DATA SHOLAT?", color = RingRed, fontWeight = FontWeight.Bold) },
            text = { Text("Yakin mau hapus semua data karakter & riwayat sholat? Level, streak, quest, dan rewards bakal hilang selamanya!", color = TextLight) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.resetAllData()
                    showResetConfirm = false
                }) {
                    Text("Ya, Hapus Semua", color = RingRed, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetConfirm = false }) {
                    Text("Batal", color = TextLight)
                }
            },
            containerColor = DarkSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }
}

// ─── Section title pill: teal-to-gold horizontal gradient, black text, 10sp bold, letter-spacing 2sp ───
@Composable
private fun ArenaSectionPill(
    text: String,
    gradient: List<Color> = GradientGreenGold,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .shadow(8.dp, RoundedCornerShape(100.dp), ambientColor = IslamicGreen.copy(alpha = 0.35f))
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

// ═══════════════════════════════════════════════════════════════
// PROFILE HEADER CARD
// Avatar with rotating gradient arc ring (8s rotation) + pulsing glow.
// ═══════════════════════════════════════════════════════════════
@Composable
fun ProfileHeaderCard(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)

    val transition = rememberInfiniteTransition(label = "avatar_ring")
    val ringRotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ring_rotation"
    )
    val pulseScale by transition.animateFloat(
        initialValue = 1f,
        targetValue = 1.06f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    val headerShape = RoundedCornerShape(22.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("profile_header_card")
            .shadow(
                elevation = 22.dp,
                shape = headerShape,
                ambientColor = IslamicGreen.copy(alpha = 0.28f),
                spotColor = GoldAccent.copy(alpha = 0.18f)
            ),
        shape = headerShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, ArenaBorder)
    ) {
        Column(
            modifier = Modifier
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(IslamicGreen.copy(alpha = 0.16f), Color.Transparent),
                            center = center,
                            radius = size.width / 1.5f
                        )
                    )
                }
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Avatar with rotating gradient arc + pulsing glow
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(90.dp)
            ) {
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer { rotationZ = ringRotation }
                ) {
                    val strokeWidth = 3.dp.toPx()
                    drawArc(
                        brush = Brush.sweepGradient(listOf(IslamicGreen, GoldAccent, PurpleNeon, IslamicGreen)),
                        startAngle = 0f,
                        sweepAngle = 270f,
                        useCenter = false,
                        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                    )
                }
                Box(
                    modifier = Modifier
                        .size(72.dp * pulseScale)
                        .shadow(18.dp, CircleShape, ambientColor = GoldAccent.copy(alpha = 0.55f))
                        .background(
                            Brush.radialGradient(listOf(GoldAccent.copy(alpha = 0.22f), DarkBackground)),
                            CircleShape
                        )
                        .border(BorderStroke(2.dp, Brush.linearGradient(GradientGoldAmber)), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "👑", fontSize = 36.sp)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = state.user.username,
                fontSize = 22.sp,
                fontWeight = FontWeight.ExtraBold,
                color = TextLight,
                textAlign = TextAlign.Center
            )

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
            ) {
                Text(
                    text = rankTitle,
                    fontSize = 14.sp,
                    color = GoldAccent,
                    fontWeight = FontWeight.Black
                )
                Spacer(modifier = Modifier.width(6.dp))
                Box(
                    modifier = Modifier
                        .shadow(6.dp, RoundedCornerShape(4.dp), ambientColor = IslamicGreen.copy(alpha = 0.4f))
                        .background(Brush.horizontalGradient(GradientGreenGold), RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "LV ${levelInfo.level}",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }

            // XP progress row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = "Level Progress".uppercase(), fontSize = 10.sp, color = TextMuted, letterSpacing = 1.sp, fontWeight = FontWeight.Medium)
                Text(
                    text = "${levelInfo.xpInCurrentLevel}/${levelInfo.xpNeededForNextLevel} XP",
                    fontSize = 11.sp,
                    color = TextLight,
                    fontWeight = FontWeight.Black,
                    fontFamily = FontFamily.Monospace
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            NeonProgressBar(
                progress = levelInfo.progress,
                modifier = Modifier.fillMaxWidth(),
                height = 8.dp,
                brush = Brush.horizontalGradient(listOf(IslamicGreen, IslamicGreenDim, GoldAccent)),
                glowColor = IslamicGreen,
                trackColor = DarkSurfaceVariant
            )

            Spacer(modifier = Modifier.height(14.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "TOTAL XP".uppercase(), fontSize = 10.sp, color = TextMuted, letterSpacing = 1.sp)
                    Text(text = "${state.user.xp}", fontSize = 18.sp, fontWeight = FontWeight.Black, color = GoldAccent, fontFamily = FontFamily.Monospace)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "LOKASI".uppercase(), fontSize = 10.sp, color = TextMuted, letterSpacing = 1.sp)
                    Text(text = state.user.kota, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextLight)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "INTENSITAS".uppercase(), fontSize = 10.sp, color = TextMuted, letterSpacing = 1.sp)
                    Text(text = state.user.intensityMode.capitalizeCompat(), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = IslamicGreen)
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// SMALL STAT CARD
// Left accent bar (2dp, colored per stat type), label (10sp uppercase muted),
// value (24sp mono bold), sub (11sp muted).
// ═══════════════════════════════════════════════════════════════
@Composable
fun SmallStatCard(
    modifier: Modifier,
    title: String,
    value: String,
    sub: String,
    accentColor: Color = IslamicGreen
) {
    val cardShape = RoundedCornerShape(14.dp)
    Card(
        modifier = modifier
            .shadow(8.dp, cardShape, ambientColor = accentColor.copy(alpha = 0.18f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, ArenaBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left accent bar (2dp wide, full-height, colored per stat)
            Box(
                modifier = Modifier
                    .width(2.dp)
                    .fillMaxHeight()
                    .background(accentColor, RoundedCornerShape(100.dp))
            )
            Spacer(modifier = Modifier.width(8.dp))
            Column {
                Text(
                    text = title.uppercase(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextMuted,
                    letterSpacing = 1.sp
                )
                Text(
                    text = value,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Black,
                    color = accentColor,
                    fontFamily = FontFamily.Monospace,
                    lineHeight = 26.sp
                )
                Text(
                    text = sub,
                    fontSize = 11.sp,
                    color = TextMuted
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// CONSISTENCY CHART
// Gradient dots with outer glow on a gradient line.
// ═══════════════════════════════════════════════════════════════
@Composable
fun ConsistencyLineChartCanvas(
    stats: List<Float>,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height

        // Horizontal grid helper lines (very faint)
        val linesCount = 4
        for (i in 0 until linesCount) {
            val y = height * (i.toFloat() / (linesCount - 1))
            drawLine(
                color = TextLight.copy(alpha = 0.05f),
                start = Offset(0f, y),
                end = Offset(width, y),
                strokeWidth = 1f
            )
        }

        val pointCount = stats.size
        if (pointCount < 2) return@Canvas

        val paddingX = 40.dp.toPx()
        val spacingX = (width - paddingX * 2) / (pointCount - 1)

        val path = Path()
        val points = mutableListOf<Offset>()

        for (i in 0 until pointCount) {
            val x = paddingX + i * spacingX
            val y = height - (stats[i] / 100f) * (height * 0.8f) - (height * 0.1f)
            points.add(Offset(x, y))
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }

        // Glowing gradient line
        drawPath(
            path = path,
            brush = Brush.horizontalGradient(listOf(IslamicGreen, GoldAccent, IslamicGreen)),
            style = Stroke(width = 7f, cap = StrokeCap.Round)
        )

        // Under-fill gradient
        val fillPath = Path().apply {
            addPath(path)
            lineTo(points.last().x, height)
            lineTo(points.first().x, height)
            close()
        }
        drawPath(
            path = fillPath,
            brush = Brush.verticalGradient(
                listOf(IslamicGreen.copy(alpha = 0.18f), GoldAccent.copy(alpha = 0.08f), Color.Transparent)
            )
        )

        // Points with outer glow
        points.forEachIndexed { idx, offset ->
            // Outer glow
            drawCircle(
                brush = Brush.radialGradient(
                    listOf(IslamicGreen.copy(alpha = 0.35f), Color.Transparent),
                    center = offset,
                    radius = 18f
                ),
                radius = 18f,
                center = offset
            )
            // Dark background ring
            drawCircle(color = DarkBackground, radius = 12f, center = offset)
            // Gradient inner dot
            drawCircle(
                brush = Brush.radialGradient(listOf(GoldAccent, IslamicGreen), center = offset, radius = 8f),
                radius = 8f,
                center = offset
            )

            // Score text
            val scoreText = "${stats[idx].toInt()}%"
            val textPaint = android.graphics.Paint().apply {
                color = android.graphics.Color.WHITE
                textSize = 9.dp.toPx()
                isFakeBoldText = true
                textAlign = android.graphics.Paint.Align.CENTER
                setShadowLayer(8f, 0f, 0f, android.graphics.Color.argb(180, 20, 232, 200))
            }
            drawContext.canvas.nativeCanvas.drawText(
                scoreText,
                offset.x,
                offset.y - 12.dp.toPx(),
                textPaint
            )

            // Week label
            val weekLabel = "Mng ${idx + 1}"
            val labelPaint = android.graphics.Paint().apply {
                color = android.graphics.Color.LTGRAY
                textSize = 9.dp.toPx()
                textAlign = android.graphics.Paint.Align.CENTER
            }
            drawContext.canvas.nativeCanvas.drawText(
                weekLabel,
                offset.x,
                height - 4f,
                labelPaint
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// ACHIEVEMENTS GRID
// X/N counter + teal progress bar; locked items muted.
// ═══════════════════════════════════════════════════════════════
@Composable
fun AchievementsGrid(unlockedBadges: List<String>) {
    val badgesPool = listOf(
        Badge("langkah_pertama", "Langkah Pertama", "Catat sholat pertama", "👣"),
        Badge("subuh_warrior", "Subuh Warrior", "Streak Subuh 7 hari", "⏱️"),
        Badge("subuh_legend", "Subuh Legend", "Streak Subuh 30 hari", "🏆"),
        Badge("five_five_master", "5/5 Master", "Pertama kali 5/5!", "🥇"),
        Badge("five_five_streak_7", "Streak x7", "Hero streak 7 hari", "🎖️"),
        Badge("five_five_streak_30", "Streak x30", "Hero streak 30 hari", "👑"),
        Badge("sultan_sunnah", "Sultan Sunnah", "Total 50 sholat sunnah", "☘️"),
        Badge("tilawah_streak_14", "Tilawah Streak", "Streak Tilawah 14 hari", "📜"),
        Badge("ramadan_champion", "Virtual Ramadan", "Aktif selama Ramadan 🌙", "🌙"),
        Badge("comeback_king", "Comeback King", "Pernah break 3x tapi balik lagi! 💪", "🛡️"),
        Badge("early_bird", "Early Bird", "20x Sholat tepat waktu", "🏹"),
        Badge("mythic_reached", "Mythic Reached", "Level 80 tercapai! 🔮", "🔮"),
        Badge("santri_digital", "Santri Digital", "Selesaikan semua 16 modul Belajar! 🎓", "🎓")
    )

    val unlockedCount = badgesPool.count { unlockedBadges.contains(it.id) }
    val progress = unlockedCount.toFloat() / badgesPool.size.toFloat()

    Column {
        Row(
            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Unlocked: $unlockedCount/${badgesPool.size}",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = GoldAccent,
                fontFamily = FontFamily.Monospace
            )
            Text(
                text = "${(progress * 100).toInt()}%",
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold,
                color = if (progress == 1f) IslamicGreen else GoldAccent,
                fontFamily = FontFamily.Monospace
            )
        }
        // Teal progress bar
        NeonProgressBar(
            progress = progress,
            modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
            height = 6.dp,
            brush = Brush.horizontalGradient(listOf(IslamicGreen, IslamicGreenDim, IslamicGreen)),
            glowColor = IslamicGreen,
            trackColor = DarkSurfaceVariant
        )

        badgesPool.chunked(3).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                row.forEach { badge ->
                    val isUnlocked = unlockedBadges.contains(badge.id)
                    BadgeItemView(badge, isUnlocked, modifier = Modifier.weight(1f))
                }
                if (row.size < 3) {
                    repeat(3 - row.size) { Spacer(modifier = Modifier.weight(1f)) }
                }
            }
        }
    }
}

@Composable
fun BadgeItemView(badge: Badge, isUnlocked: Boolean, modifier: Modifier) {
    val cardShape = RoundedCornerShape(14.dp)
    val accentColor = if (isUnlocked) GoldAccent else TextMuted

    Card(
        modifier = modifier
            .height(105.dp)
            .then(
                if (isUnlocked) Modifier.shadow(
                    elevation = 12.dp,
                    shape = cardShape,
                    ambientColor = GoldAccent.copy(alpha = 0.35f),
                    spotColor = GoldAccent.copy(alpha = 0.2f)
                ) else Modifier.shadow(
                    elevation = 4.dp,
                    shape = cardShape,
                    ambientColor = Color.Black.copy(alpha = 0.15f)
                )
            ),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = if (isUnlocked) DarkSurface else DarkSurface.copy(alpha = 0.5f)),
        border = BorderStroke(
            1.dp,
            if (isUnlocked) Brush.linearGradient(listOf(GoldAccent.copy(alpha = 0.5f), GoldAccent.copy(alpha = 0.1f), GoldAccent.copy(alpha = 0.5f)))
            else Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
        )
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .then(
                        if (isUnlocked) Modifier.shadow(10.dp, CircleShape, ambientColor = GoldAccent.copy(alpha = 0.5f)) else Modifier
                    )
                    .background(
                        if (isUnlocked) Brush.radialGradient(listOf(GoldAccent.copy(alpha = 0.22f), Color.Transparent))
                        else Brush.radialGradient(listOf(TextMuted.copy(alpha = 0.08f), Color.Transparent)),
                        CircleShape
                    )
                    .border(
                        BorderStroke(1.5.dp,
                            if (isUnlocked) Brush.linearGradient(GradientGoldAmber)
                            else Brush.linearGradient(listOf(TextMuted.copy(alpha = 0.18f), TextMuted.copy(alpha = 0.18f)))
                        ),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (isUnlocked) badge.icon else "🔒",
                    fontSize = 22.sp,
                    textAlign = TextAlign.Center
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = badge.title,
                fontSize = 11.sp,
                fontWeight = if (isUnlocked) FontWeight.Bold else FontWeight.Medium,
                color = if (isUnlocked) TextLight else TextMuted.copy(alpha = 0.6f),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                text = badge.desc,
                fontSize = 8.sp,
                color = if (isUnlocked) TextMuted else TextMuted.copy(alpha = 0.5f),
                textAlign = TextAlign.Center,
                lineHeight = 10.sp,
                maxLines = 2
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// REWARD COLLECTOR GALLERY
// ═══════════════════════════════════════════════════════════════
@Composable
fun RewardCollectorGallery(collectedRewards: List<String>) {
    val poolOfTen = listOf(
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

    val galleryShape = RoundedCornerShape(18.dp)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(10.dp, galleryShape, ambientColor = GoldAccent.copy(alpha = 0.15f))
            .background(DarkSurface, galleryShape)
            .border(BorderStroke(1.dp, ArenaBorder), galleryShape)
            .padding(16.dp)
    ) {
        Text(
            text = "Gacha Loot (${collectedRewards.size}/10):",
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            fontFamily = FontFamily.Monospace,
            modifier = Modifier.padding(bottom = 12.dp)
        )

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            poolOfTen.forEachIndexed { idx, item ->
                val isUnlocked = collectedRewards.contains(item)
                val textCol = if (isUnlocked) TextLight else TextMuted
                val badgeEmoji = when (idx) {
                    0 -> "🌙"
                    1 -> "🔱"
                    2 -> "🖼️"
                    3 -> "⚔️"
                    4 -> "🧪"
                    5 -> "🌌"
                    6 -> "☄️"
                    7 -> "🥋"
                    8 -> "👼"
                    else -> "🗡️"
                }

                Box(
                    modifier = Modifier
                        .width(96.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .then(
                            if (isUnlocked) Modifier.shadow(8.dp, RoundedCornerShape(12.dp), ambientColor = GoldAccent.copy(alpha = 0.35f))
                            else Modifier
                        )
                        .background(
                            if (isUnlocked) Brush.verticalGradient(listOf(GoldAccent.copy(alpha = 0.10f), DarkSurfaceVariant))
                            else Brush.verticalGradient(GradientDarkSurface)
                        )
                        .border(
                            BorderStroke(1.dp,
                                if (isUnlocked) Brush.linearGradient(listOf(GoldAccent.copy(alpha = 0.5f), GoldAccent.copy(alpha = 0.15f)))
                                else Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
                            ),
                            RoundedCornerShape(12.dp)
                        )
                        .padding(10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = if (isUnlocked) badgeEmoji else "🎁", fontSize = 24.sp)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = item,
                            fontSize = 9.sp,
                            textAlign = TextAlign.Center,
                            fontWeight = FontWeight.Medium,
                            color = textCol,
                            lineHeight = 11.sp,
                            maxLines = 2
                        )
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS PANEL
// Per-mode gradient selectors (santai/standar/sultan) with glow when selected.
// Reset button: crimson glow + gradient border.
// ═══════════════════════════════════════════════════════════════
@Composable
fun SettingsPanelContent(
    state: MuslimLevelingData,
    viewModel: GameViewModel,
    onResetClick: () -> Unit
) {
    var username by remember { mutableStateOf(state.user.username) }
    var kota by remember { mutableStateOf(state.user.kota) }
    var kotaId by remember { mutableStateOf(state.user.kotaId) }
    var intensityMode by remember { mutableStateOf(state.user.intensityMode) }
    var notifMode by remember { mutableStateOf(state.user.notifMode) }

    // Load daftar kota KEMENAG saat settings dibuka
    LaunchedEffect(Unit) {
        viewModel.loadCitiesFromKemenag()
    }
    val cities by viewModel.kemenagCities.collectAsState()
    val isLoadingCities by viewModel.isLoadingCities.collectAsState()
    var selectedSantaiList by remember { mutableStateOf(state.user.santaiTrackedPrayers) }

    val context = LocalContext.current

    val panelShape = RoundedCornerShape(16.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("settings_expanded_panel")
            .shadow(8.dp, panelShape, ambientColor = IslamicGreen.copy(alpha = 0.15f)),
        shape = panelShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, ArenaBorder)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Edit Nickname Gamer:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = TextLight,
                    unfocusedTextColor = TextLight,
                    focusedBorderColor = IslamicGreen,
                    unfocusedBorderColor = DarkSurfaceVariant,
                    focusedContainerColor = DarkBackground,
                    unfocusedContainerColor = DarkBackground
                ),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .testTag("username_edit_field"),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(10.dp))

            Text("Kota/Kabupaten:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            CityDropdownPicker(
                value = kota,
                onValueChange = { newName ->
                    kota = newName
                    // Lookup ID kota dari daftar KEMENAG
                    val match = cities.find { it.lokasi.equals(newName.trim(), ignoreCase = true) }
                    kotaId = match?.id ?: state.user.kotaId
                },
                cities = cities,
                isLoading = isLoadingCities,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .testTag("kota_edit_field")
            )

            Spacer(modifier = Modifier.height(10.dp))

            // ─── Mode Leveling selectors (santai/standar/sultan) ───
            // Per-mode gradient color + glow when selected:
            //   santai = teal, standar = gold, sultan = violet
            Text("Mode Leveling:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("santai", "standar", "sultan").forEach { m ->
                    val isS = m == intensityMode
                    val modeGradient = when (m) {
                        "santai" -> GradientCyanGreen
                        "sultan" -> listOf(PurpleNeon, PurpleNeon.copy(alpha = 0.6f))
                        else -> GradientGoldAmber
                    }
                    val modeColor = when (m) {
                        "santai" -> IslamicGreen
                        "sultan" -> PurpleNeon
                        else -> GoldAccent
                    }
                    ArenaModeSelector(
                        label = m.capitalizeCompat(),
                        isSelected = isS,
                        modeGradient = modeGradient,
                        modeColor = modeColor,
                        modifier = Modifier.weight(1f),
                        onClick = { intensityMode = m }
                    )
                }
            }

            if (intensityMode == "santai") {
                Text(
                    text = "Pilih 3 sholat wajib yg mau dilacak:",
                    fontSize = 11.sp,
                    color = TextMuted,
                    modifier = Modifier.padding(top = 4.dp, bottom = 4.dp)
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    listOf("subuh", "dzuhur", "ashar", "maghrib", "isya").forEach { pray ->
                        val isSel = selectedSantaiList.contains(pray)
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (isSel) IslamicGreen.copy(alpha = 0.2f) else DarkBackground)
                                .border(BorderStroke(1.dp, if (isSel) IslamicGreen else ArenaBorder), RoundedCornerShape(8.dp))
                                .clickable {
                                    val currentList = selectedSantaiList.toMutableList()
                                    if (isSel) currentList.remove(pray) else currentList.add(pray)
                                    selectedSantaiList = currentList
                                }
                                .padding(vertical = 6.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(text = pray.substring(0, 3).uppercase(), fontSize = 10.sp, color = if (isSel) IslamicGreen else TextLight, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // ─── Note: Notif mode & Adzan reminder dipindah ke tab Notif ───
            Text(
                text = "💡 Pengaturan notifikasi & adzan dipindah ke tab 'Notif' di bottom bar.",
                fontSize = 11.sp,
                color = TextMuted,
                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                modifier = Modifier.padding(vertical = 8.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // ─── Save button (teal gradient + glow) ───
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(10.dp, RoundedCornerShape(12.dp), ambientColor = IslamicGreen.copy(alpha = 0.45f))
                    .background(Brush.horizontalGradient(GradientGreenGold), RoundedCornerShape(12.dp))
                    .clickable {
                        val finalSantai = if (selectedSantaiList.isEmpty()) listOf("subuh", "maghrib", "isya") else selectedSantaiList
                        // Validate kota: must match a KEMENAG city, fallback to existing
                        val match = cities.find { it.lokasi.equals(kota.trim(), ignoreCase = true) }
                        val validKota = match?.lokasi ?: state.user.kota
                        val validKotaId = match?.id ?: state.user.kotaId
                        viewModel.updateProfileSettings(
                            username = username.trim(),
                            kota = validKota,
                            kotaId = validKotaId,
                            intensityMode = intensityMode,
                            santaiPrayers = finalSantai,
                            notifMode = notifMode,
                            theme = "dark"
                        )
                    }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text("Simpan Perubahan 💾", fontWeight = FontWeight.Black, fontSize = 13.sp, color = Color.Black)
            }

            Spacer(modifier = Modifier.height(12.dp))

            // ─── Reset button: crimson glow + gradient border ───
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(12.dp, RoundedCornerShape(12.dp), ambientColor = RingRed.copy(alpha = 0.5f), spotColor = RingRed.copy(alpha = 0.3f))
                    .background(Brush.verticalGradient(listOf(RingRed.copy(alpha = 0.15f), DarkSurface)), RoundedCornerShape(12.dp))
                    .border(BorderStroke(1.5.dp, Brush.linearGradient(listOf(RingRed, RingRed.copy(alpha = 0.6f), RingRed))), RoundedCornerShape(12.dp))
                    .clickable { onResetClick() }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text("⚠️ Hapus Semua Data Karakter ⚠️", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = RingRed)
            }
        }
    }
}

// ─── Reusable per-mode gradient selector with glow when selected ───
@Composable
private fun ArenaModeSelector(
    label: String,
    isSelected: Boolean,
    modeGradient: List<Color>,
    modeColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(10.dp)
    Box(
        modifier = modifier
            .clip(shape)
            .then(
                if (isSelected) Modifier.shadow(10.dp, shape, ambientColor = modeColor.copy(alpha = 0.5f))
                else Modifier
            )
            .background(
                if (isSelected) Brush.verticalGradient(listOf(modeColor.copy(alpha = 0.22f), DarkSurface))
                else Brush.verticalGradient(GradientDarkSurface)
            )
            .border(
                BorderStroke(
                    if (isSelected) 1.5.dp else 1.dp,
                    if (isSelected) Brush.linearGradient(modeGradient)
                    else Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
                ),
                shape
            )
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = if (isSelected) modeColor else TextLight
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// DATA HELPERS (signatures unchanged)
// ═══════════════════════════════════════════════════════════════

data class Badge(
    val id: String,
    val title: String,
    val desc: String,
    val icon: String
)

fun getWeeklyConsistency(log: List<PrayerLog>): List<Float> {
    val today = LocalDate.now()
    val stats = mutableListOf<Float>()

    for (i in 3 downTo 0) {
        val startDay = today.minusDays((i + 1) * 7L - 1)
        val endDay = today.minusDays(i * 7L)

        var completedDaysCount = 0
        var currentDate = startDay
        while (!currentDate.isAfter(endDay)) {
            val dateStr = currentDate.toString()
            val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
            val allChecked = wajibList.all { prayer ->
                log.any { it.date == dateStr && it.prayer == prayer }
            }
            if (allChecked) {
                completedDaysCount++
            }
            currentDate = currentDate.plusDays(1)
        }
        stats.add((completedDaysCount.toFloat() / 7f) * 100f)
    }
    return stats
}
