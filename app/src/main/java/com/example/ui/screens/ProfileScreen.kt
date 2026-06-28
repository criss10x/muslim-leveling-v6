package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.lifecycle.viewModelScope
import com.example.data.*
import com.example.ui.components.CityDropdownPicker
import com.example.ui.components.NeonProgressBar
import com.example.ui.components.TierProfileAvatar
import com.example.ui.theme.*
import com.example.viewmodel.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDate

// ═══════════════════════════════════════════════════════════════
// NUR QUEST — PROFILE SCREEN (Stitch mockup: profil_pejuang_v2)
// Layout top→bottom:
//   1. Header card: avatar + LVL badge, name + 🏆, rank gold, XP bar
//   2. Stats 2x2 grid: 🔥 STREAK, 📖 TILAWAH, ❄️ STREAK FREEZE, ⭐ TOTAL XP
//   3. Weekly graph pill + card (Konsistensi Mingguan / 85% / trend) + STATISTIK MINGGUAN button
//   4. Achievements pill + 3-col grid (SUBUH WARRIOR gold, TEPAT WAKTU teal, rest locked)
//   5. Settings: PENGATURAN header + Lokasi + Notifikasi toggle + Reset red button
// All Text() uses solid color (no brush param). VM signatures unchanged.
// ═══════════════════════════════════════════════════════════════

private val GlassBorder = TextLight.copy(alpha = 0.08f)

@Composable
fun ProfileScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    var showResetConfirm by remember { mutableStateOf(false) }
    var isSettingsExpanded by remember { mutableStateOf(true) }
    var showStatistikSheet by remember { mutableStateOf(false) }
    var notifEnabled by remember { mutableStateOf(true) }

    val context = LocalContext.current
    val scrollState = rememberScrollState()

    val weeklyConsistency = remember(state.prayerLog) {
        getWeeklyConsistency(state.prayerLog)
    }
    val avgFirstHalf = (weeklyConsistency[0] + weeklyConsistency[1]) / 2f
    val avgSecondHalf = (weeklyConsistency[2] + weeklyConsistency[3]) / 2f
    val trendUp = avgSecondHalf >= avgFirstHalf
    val trendDelta = (avgSecondHalf - avgFirstHalf).toInt().coerceAtLeast(0)
    val consistencyPct = avgSecondHalf.toInt().coerceIn(0, 100)

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
                .padding(top = 24.dp, bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ─── 1. HEADER CARD ───
            ProfileHeaderCard(state = state, viewModel = viewModel)

            // ─── 2. STATS 2x2 GRID ───
            StatsGrid(state = state)

            // ─── 3. WEEKLY GRAPH ───
            WeeklyGraphSection(
                consistencyPct = consistencyPct,
                trendUp = trendUp,
                trendDelta = trendDelta,
                weeklyConsistency = weeklyConsistency,
                onOpenStatistik = { showStatistikSheet = true }
            )

            // ─── 4. ACHIEVEMENTS ───
            AchievementsSection(unlockedBadges = state.badges)

            // ─── 5. SETTINGS ───
            SettingsSection(
                state = state,
                viewModel = viewModel,
                isExpanded = isSettingsExpanded,
                onToggleExpand = { isSettingsExpanded = !isSettingsExpanded },
                notifEnabled = notifEnabled,
                onToggleNotif = { notifEnabled = it },
                onResetClick = { showResetConfirm = true }
            )
        }
    }

    if (showResetConfirm) {
        AlertDialog(
            onDismissRequest = { showResetConfirm = false },
            title = { Text("HAPUS DATA SHOLAT?", color = RingRed, fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    "Yakin mau hapus semua data karakter & riwayat sholat? Level, streak, quest, dan rewards bakal hilang selamanya!",
                    color = TextLight
                )
            },
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

    if (showStatistikSheet) {
        StatistikBottomSheet(
            state = state,
            onDismiss = { showStatistikSheet = false }
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// 1. PROFILE HEADER CARD
// Avatar (TierProfileAvatar, gradient border) + LVL badge bottom-right,
// name uppercase + 🏆, rank gold-neon, XP row + bar.
// ═══════════════════════════════════════════════════════════════
@Composable
fun ProfileHeaderCard(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)
    val tierName = viewModel.getTierName(levelInfo.level)
    val context = LocalContext.current

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = androidx.activity.result.contract.ActivityResultContracts.GetContent()
    ) { uri ->
        if (uri != null) {
            viewModel.viewModelScope.launch(Dispatchers.IO) {
                runCatching {
                    val inputStream = context.contentResolver.openInputStream(uri)
                    val bitmap = android.graphics.BitmapFactory.decodeStream(inputStream)
                    inputStream?.close()
                    if (bitmap != null) {
                        val size = minOf(bitmap.width, bitmap.height)
                        val startX = (bitmap.width - size) / 2
                        val startY = (bitmap.height - size) / 2
                        val cropped = android.graphics.Bitmap.createBitmap(bitmap, startX, startY, size, size)
                        val finalBitmap = if (cropped.width > 512) {
                            android.graphics.Bitmap.createScaledBitmap(cropped, 512, 512, true)
                        } else {
                            cropped
                        }
                        viewModel.saveProfileImage(finalBitmap)
                    }
                }.onFailure { it.printStackTrace() }
            }
        }
    }

    val headerShape = RoundedCornerShape(12.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("profile_header_card")
            .shadow(
                elevation = 16.dp,
                shape = headerShape,
                ambientColor = IslamicGreen.copy(alpha = 0.20f),
                spotColor = CyanAccent.copy(alpha = 0.12f)
            ),
        shape = headerShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.85f)),
        border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.20f))
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .drawBehind {
                    // Tertiary top-right glow per mockup
                    drawCircle(
                        color = CyanAccent.copy(alpha = 0.10f),
                        radius = size.minDimension * 0.6f,
                        center = Offset(size.width * 1.1f, -size.height * 0.3f)
                    )
                }
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                // Avatar + LVL badge
                Box(
                    contentAlignment = Alignment.BottomEnd,
                    modifier = Modifier
                        .size(80.dp)
                        .clickable { imagePickerLauncher.launch("image/*") }
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .shadow(12.dp, CircleShape, ambientColor = IslamicGreen.copy(alpha = 0.30f))
                            .clip(CircleShape)
                            .background(Brush.linearGradient(listOf(IslamicGreen, CyanAccent)))
                            .padding(2.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(CircleShape)
                                .border(2.dp, DarkSurface, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            TierProfileAvatar(
                                profileImagePath = state.user.profileImagePath,
                                tierName = tierName,
                                sizeDp = 76.dp,
                                showEditBadge = false
                            )
                        }
                    }
                    // LVL badge bottom-right
                    Box(
                        modifier = Modifier
                            .padding(0.dp)
                            .offset(x = 2.dp, y = 2.dp)
                            .shadow(4.dp, RoundedCornerShape(100.dp))
                            .clip(RoundedCornerShape(100.dp))
                            .background(DarkSurfaceElevated)
                            .border(1.dp, IslamicGreen, RoundedCornerShape(100.dp))
                            .padding(horizontal = 8.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "LVL ${levelInfo.level}",
                            color = IslamicGreen,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 0.5.sp
                        )
                    }
                }

                // Name + rank + XP
                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = state.user.username.uppercase(),
                            color = TextLight,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 1.sp,
                            maxLines = 1,
                            modifier = Modifier.weight(1f)
                        )
                        Text(text = "🏆", fontSize = 18.sp)
                    }
                    Text(
                        text = rankTitle.uppercase(),
                        color = GoldAccent,
                        fontFamily = FontFamily.Monospace,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp,
                        modifier = Modifier.padding(top = 2.dp, bottom = 8.dp)
                    )
                    // XP row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "XP",
                            color = TextMuted,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        )
                        Text(
                            text = "${levelInfo.xpInCurrentLevel} / ${levelInfo.xpNeededForNextLevel}",
                            color = IslamicGreen,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    NeonProgressBar(
                        progress = levelInfo.progress,
                        modifier = Modifier.fillMaxWidth(),
                        height = 8.dp,
                        brush = Brush.horizontalGradient(listOf(IslamicGreen, CyanAccent)),
                        glowColor = IslamicGreen,
                        trackColor = DarkSurfaceVariant
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 2. STATS 2x2 GRID
// Centered: emoji (28sp) + value (title-lg) + label-caps (10sp muted)
// Top border tint per stat (primary for 1-2, tertiary for 3, gold for 4)
// ═══════════════════════════════════════════════════════════════
@Composable
private fun StatsGrid(state: MuslimLevelingData) {
    val freezeCount = if (state.heroStreak.freezeAvailable) 1 else 0
    val stats = listOf(
        StatItem("🔥", "${state.heroStreak.current} Hari", "STREAK", IslamicGreen),
        StatItem("📖", "${state.tilawahStreak.current} Juz", "TILAWAH", IslamicGreen),
        StatItem("❄️", "$freezeCount", "STREAK FREEZE", CyanAccent),
        StatItem("⭐", "${state.user.xp}", "TOTAL XP", GoldAccent)
    )
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        stats.chunked(2).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                row.forEach { item ->
                    StatCard(item = item, modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

private data class StatItem(
    val emoji: String,
    val value: String,
    val label: String,
    val accent: Color
)

@Composable
private fun StatCard(item: StatItem, modifier: Modifier = Modifier) {
    val cardShape = RoundedCornerShape(8.dp)
    Card(
        modifier = modifier
            .shadow(6.dp, cardShape, ambientColor = item.accent.copy(alpha = 0.12f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.85f)),
        border = BorderStroke(1.dp, GlassBorder)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(text = item.emoji, fontSize = 28.sp, textAlign = TextAlign.Center)
            Text(
                text = item.value,
                color = TextLight,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )
            Text(
                text = item.label,
                color = TextMuted,
                fontFamily = FontFamily.Monospace,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
                textAlign = TextAlign.Center
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 3. WEEKLY GRAPH SECTION
// Pill badge "GRAFIK SHOLAT FARDHU", card with "Konsistensi Mingguan" / "85%"
// trend line, line chart S S R K J S M, button "STATISTIK MINGGUAN ›"
// ═══════════════════════════════════════════════════════════════
@Composable
private fun WeeklyGraphSection(
    consistencyPct: Int,
    trendUp: Boolean,
    trendDelta: Int,
    weeklyConsistency: List<Float>,
    onOpenStatistik: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionPill(
            emoji = "📈",
            text = "GRAFIK SHOLAT FARDHU",
            tint = IslamicGreen
        )

        val cardShape = RoundedCornerShape(12.dp)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("consistency_chart_card")
                .shadow(10.dp, cardShape, ambientColor = IslamicGreen.copy(alpha = 0.15f)),
            shape = cardShape,
            colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.85f)),
            border = BorderStroke(1.dp, GlassBorder)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Column {
                        Text(
                            text = "Konsistensi Mingguan",
                            color = TextMuted,
                            fontSize = 14.sp
                        )
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            modifier = Modifier.padding(top = 4.dp)
                        ) {
                            Text(
                                text = if (trendUp) "↗" else "↘",
                                color = IslamicGreen,
                                fontSize = 14.sp
                            )
                            Text(
                                text = if (trendUp) "Naik $trendDelta% dari minggu lalu"
                                       else "Turun $trendDelta% dari minggu lalu",
                                color = IslamicGreen,
                                fontFamily = FontFamily.Monospace,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.5.sp
                            )
                        }
                    }
                    Text(
                        text = "$consistencyPct%",
                        color = TextLight,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                WeeklyLineChart(
                    stats = weeklyConsistency,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp)
                )
            }
        }

        // STATISTIK MINGGUAN button
        val btnShape = RoundedCornerShape(12.dp)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("statistik_button_card")
                .clickable { onOpenStatistik() }
                .shadow(8.dp, btnShape, ambientColor = IslamicGreen.copy(alpha = 0.15f)),
            shape = btnShape,
            colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.85f)),
            border = BorderStroke(1.dp, GlassBorder)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(DarkSurfaceElevated)
                            .border(1.dp, OutlineVariant.copy(alpha = 0.5f), RoundedCornerShape(8.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = "📊", fontSize = 18.sp)
                    }
                    Text(
                        text = "STATISTIK MINGGUAN",
                        color = TextLight,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 0.5.sp
                    )
                }
                Text(
                    text = "›",
                    color = IslamicGreen,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

// ─── Section pill: emoji + caps label, tinted ───
@Composable
private fun SectionPill(
    emoji: String,
    text: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .shadow(6.dp, RoundedCornerShape(100.dp), ambientColor = tint.copy(alpha = 0.20f))
            .clip(RoundedCornerShape(100.dp))
            .background(tint.copy(alpha = 0.10f))
            .border(1.dp, tint.copy(alpha = 0.20f), RoundedCornerShape(100.dp))
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(text = emoji, fontSize = 12.sp)
            Text(
                text = text,
                color = tint,
                fontFamily = FontFamily.Monospace,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.5.sp
            )
        }
    }
}

// ─── Weekly line chart: gradient line + glowing dots + day labels S S R K J S M ───
@Composable
private fun WeeklyLineChart(
    stats: List<Float>,
    modifier: Modifier = Modifier
) {
    // Mockup labels: S S R K J S M (Sen Sel Rab Kam Jum Sab Min — single-letter ID)
    val dayLabels = listOf("S", "S", "R", "K", "J", "S", "M")

    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height
        val padBottom = 18f
        val chartHeight = height - padBottom

        // Faint dashed grid lines (mockup uses 2 dashed lines)
        for (i in 1..2) {
            val y = chartHeight * (i / 3f)
            drawLine(
                color = OutlineVariant.copy(alpha = 0.30f),
                start = Offset(0f, y),
                end = Offset(width, y),
                strokeWidth = 1f,
                pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(4f, 4f))
            )
        }

        if (stats.size < 2) return@Canvas

        val padX = 24f
        val spacingX = (width - padX * 2) / (stats.size - 1)
        val points = mutableListOf<Offset>()
        val path = Path()

        stats.forEachIndexed { i, v ->
            val x = padX + i * spacingX
            val y = chartHeight - (v / 100f) * (chartHeight * 0.85f) - (chartHeight * 0.05f)
            points.add(Offset(x, y))
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }

        // Gradient line (cyan → emerald)
        drawPath(
            path = path,
            brush = Brush.horizontalGradient(listOf(CyanAccent, IslamicGreen)),
            style = Stroke(width = 3f, cap = StrokeCap.Round)
        )

        // Under-fill gradient
        val fillPath = Path().apply {
            addPath(path)
            lineTo(points.last().x, chartHeight)
            lineTo(points.first().x, chartHeight)
            close()
        }
        drawPath(
            path = fillPath,
            color = IslamicGreen.copy(alpha = 0.12f)
        )

        // Data points: dark bg ring + gradient dot; last point solid + glow
        points.forEachIndexed { idx, offset ->
            drawCircle(color = DarkBackground, radius = 5f, center = offset)
            drawCircle(color = IslamicGreen, radius = 3f, center = offset)
            if (idx == points.lastIndex) {
                drawCircle(
                    brush = Brush.radialGradient(
                        listOf(IslamicGreen.copy(alpha = 0.6f), Color.Transparent),
                        center = offset,
                        radius = 12f
                    ),
                    radius = 12f,
                    center = offset
                )
                drawCircle(color = IslamicGreen, radius = 4f, center = offset)
            }
        }

        // Day labels under chart (S S R K J S M)
        val labelPaint = android.graphics.Paint().apply {
            color = TextMuted.toArgb()
            textSize = 9.dp.toPx()
            isAntiAlias = true
            textAlign = android.graphics.Paint.Align.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        points.forEachIndexed { i, offset ->
            drawContext.canvas.nativeCanvas.drawText(
                dayLabels.getOrElse(i) { "" },
                offset.x,
                height - 4f,
                labelPaint
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 4. ACHIEVEMENTS SECTION
// Pill badge + 3-col grid. Mockup badges shown literally:
//   SUBUH WARRIOR (gold, unlocked) | TEPAT WAKTU (teal, unlocked) | JUMAT BERKAH (locked)
//   KHATAM QURAN (locked) | QIYAMULLAIL (locked) | SEDEKAH SUBUH (locked)
// Unlocked state is driven by state.badges IDs (best-effort mapping).
// ═══════════════════════════════════════════════════════════════
@Composable
private fun AchievementsSection(unlockedBadges: List<String>) {
    // Mockup badge grid: id, title, emoji, accent when unlocked
    val mockupBadges = listOf(
        MockupBadge("subuh_warrior", "SUBUH WARRIOR", "🕌", GoldAccent),
        MockupBadge("tepat_waktu", "TEPAT WAKTU", "⏱", IslamicGreen),
        MockupBadge("jumat_berkah", "JUMAT BERKAH", "🤲", GoldAccent),
        MockupBadge("khatam_quran", "KHATAM QURAN", "📖", GoldAccent),
        MockupBadge("qiyamullail", "QIYAMULLAIL", "🌙", IslamicGreen),
        MockupBadge("sedekah_subuh", "SEDEKAH SUBUH", "🤝", GoldAccent)
    )

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionPill(
            emoji = "💡",
            text = "PENCAPAIAN & BADGE",
            tint = GoldAccent
        )
        mockupBadges.chunked(3).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                row.forEach { badge ->
                    MockupBadgeItem(
                        badge = badge,
                        isUnlocked = unlockedBadges.contains(badge.id),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

private data class MockupBadge(
    val id: String,
    val title: String,
    val emoji: String,
    val accent: Color
)

@Composable
private fun MockupBadgeItem(
    badge: MockupBadge,
    isUnlocked: Boolean,
    modifier: Modifier = Modifier
) {
    val cardShape = RoundedCornerShape(12.dp)
    val accent = if (isUnlocked) badge.accent else TextMuted
    val container = if (isUnlocked) DarkSurface.copy(alpha = 0.85f) else DarkSurfaceVariant.copy(alpha = 0.4f)
    Card(
        modifier = modifier
            .height(110.dp)
            .then(
                if (isUnlocked) Modifier.shadow(
                    elevation = 10.dp,
                    shape = cardShape,
                    ambientColor = accent.copy(alpha = 0.20f),
                    spotColor = accent.copy(alpha = 0.10f)
                ) else Modifier
            ),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = container),
        border = BorderStroke(
            1.dp,
            if (isUnlocked) accent.copy(alpha = 0.50f) else OutlineVariant.copy(alpha = 0.30f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp)
                .then(if (!isUnlocked) Modifier.alpha(0.6f) else Modifier),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = if (isUnlocked) badge.emoji else "🔒",
                fontSize = 30.sp,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = badge.title,
                color = if (isUnlocked) TextLight else TextMuted,
                fontFamily = FontFamily.Monospace,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.5.sp,
                textAlign = TextAlign.Center,
                maxLines = 2
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 5. SETTINGS SECTION
// PENGATURAN header (collapsible), then:
//   - "Lokasi Saat Ini" + UBAH button (opens city picker)
//   - "Notifikasi Adzan" + toggle
//   - "Reset Data Profil" red button
// VM calls preserved: loadCitiesFromKemenag, kemenagCities, isLoadingCities,
// updateProfileSettings, resetAllData.
// ═══════════════════════════════════════════════════════════════
@Composable
private fun SettingsSection(
    state: MuslimLevelingData,
    viewModel: GameViewModel,
    isExpanded: Boolean,
    onToggleExpand: () -> Unit,
    notifEnabled: Boolean,
    onToggleNotif: (Boolean) -> Unit,
    onResetClick: () -> Unit
) {
    val cardShape = RoundedCornerShape(12.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("settings_section"),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.85f)),
        border = BorderStroke(1.dp, GlassBorder)
    ) {
        Column {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onToggleExpand() }
                    .background(DarkSurfaceElevated)
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(text = "⚙️", fontSize = 18.sp)
                    Text(
                        text = "PENGATURAN",
                        color = TextLight,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                Icon(
                    imageVector = if (isExpanded) Icons.Default.KeyboardArrowUp
                                  else Icons.Default.KeyboardArrowDown,
                    contentDescription = "Toggle Settings",
                    tint = TextMuted
                )
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically() + fadeOut()
            ) {
                SettingsContent(
                    state = state,
                    viewModel = viewModel,
                    notifEnabled = notifEnabled,
                    onToggleNotif = onToggleNotif,
                    onResetClick = onResetClick
                )
            }
        }
    }
}

@Composable
private fun SettingsContent(
    state: MuslimLevelingData,
    viewModel: GameViewModel,
    notifEnabled: Boolean,
    onToggleNotif: (Boolean) -> Unit,
    onResetClick: () -> Unit
) {
    var username by remember { mutableStateOf(state.user.username) }
    var kota by remember { mutableStateOf(state.user.kota) }
    var kotaId by remember { mutableStateOf(state.user.kotaId) }
    var notifMode by remember { mutableStateOf(state.user.notifMode) }
    var showCityPicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadCitiesFromKemenag()
    }
    val cities by viewModel.kemenagCities.collectAsState()
    val isLoadingCities by viewModel.isLoadingCities.collectAsState()

    Column(modifier = Modifier.padding(16.dp)) {
        // ─── Lokasi Saat Ini + UBAH button ───
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Lokasi Saat Ini",
                    color = TextLight,
                    fontSize = 16.sp
                )
                Text(
                    text = if (state.user.kota.isNotBlank()) state.user.kota
                           else "Jakarta, Indonesia",
                    color = TextMuted,
                    fontSize = 14.sp
                )
            }
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(4.dp))
                    .border(1.dp, IslamicGreen.copy(alpha = 0.30f), RoundedCornerShape(4.dp))
                    .clickable { showCityPicker = !showCityPicker }
                    .padding(horizontal = 12.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "UBAH",
                    color = IslamicGreen,
                    fontFamily = FontFamily.Monospace,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
            }
        }

        HorizontalDivider(
            modifier = Modifier.padding(vertical = 16.dp),
            thickness = 1.dp,
            color = OutlineVariant.copy(alpha = 0.30f)
        )

        // ─── City picker (collapsible when UBAH tapped) ───
        if (showCityPicker) {
            CityDropdownPicker(
                value = kota,
                onValueChange = { newName ->
                    kota = newName
                    val match = cities.find { it.lokasi.equals(newName.trim(), ignoreCase = true) }
                    kotaId = match?.id ?: state.user.kotaId
                },
                cities = cities,
                isLoading = isLoadingCities,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
                    .testTag("kota_edit_field")
            )
            HorizontalDivider(
                modifier = Modifier.padding(bottom = 16.dp),
                thickness = 1.dp,
                color = OutlineVariant.copy(alpha = 0.30f)
            )
        }

        // ─── Notifikasi Adzan + toggle ───
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Notifikasi Adzan",
                    color = TextLight,
                    fontSize = 16.sp
                )
                Text(
                    text = if (notifEnabled) "Aktif untuk 5 waktu" else "Nonaktif",
                    color = TextMuted,
                    fontSize = 14.sp
                )
            }
            Switch(
                checked = notifEnabled,
                onCheckedChange = { onToggleNotif(it) },
                colors = SwitchDefaults.colors(
                    checkedTrackColor = IslamicGreen,
                    checkedThumbColor = DarkBackground,
                    uncheckedTrackColor = DarkSurfaceVariant,
                    uncheckedThumbColor = TextMuted
                )
            )
        }

        HorizontalDivider(
            modifier = Modifier.padding(vertical = 16.dp),
            thickness = 1.dp,
            color = OutlineVariant.copy(alpha = 0.30f)
        )

        // ─── Save button (only meaningful if user changed name/kota) ───
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp)
                .shadow(8.dp, RoundedCornerShape(8.dp), ambientColor = IslamicGreen.copy(alpha = 0.30f))
                .clip(RoundedCornerShape(8.dp))
                .background(Brush.horizontalGradient(GradientGreenGold))
                .clickable {
                    val match = cities.find { it.lokasi.equals(kota.trim(), ignoreCase = true) }
                    val validKota = match?.lokasi ?: state.user.kota
                    val validKotaId = match?.id ?: state.user.kotaId
                    viewModel.updateProfileSettings(
                        username = username.trim(),
                        kota = validKota,
                        kotaId = validKotaId,
                        notifMode = notifMode,
                        theme = "dark"
                    )
                }
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Simpan Perubahan",
                color = DarkBackground,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
        }

        // ─── Reset Data Profil (red) ───
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .border(1.dp, RingRed.copy(alpha = 0.50f), RoundedCornerShape(8.dp))
                .clickable { onResetClick() }
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(text = "🗑️", fontSize = 16.sp)
                Text(
                    text = "Reset Data Profil",
                    color = RingRed,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
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
