package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.theme.*
import com.example.viewmodel.*
import java.time.LocalDate

@Composable
fun ProfileScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    var showResetConfirm by remember { mutableStateOf(false) }
    var isSettingsExpanded by remember { mutableStateOf(false) }

    val context = LocalContext.current
    val scrollState = rememberScrollState()

    // Calculate weekly stats & trends
    val weeklyConsistency = remember(state.prayerLog) {
        getWeeklyConsistency(state.prayerLog)
    }
    val avgFirstHalf = (weeklyConsistency[0] + weeklyConsistency[1]) / 2f
    val avgSecondHalf = (weeklyConsistency[2] + weeklyConsistency[3]) / 2f
    val trendDirection = if (avgSecondHalf >= avgFirstHalf) "naik" else "turun"

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .muslimPattern()
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = 24.dp)
                .padding(top = 28.dp, bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Profile Main Card Header
            ProfileHeaderCard(state = state, viewModel = viewModel)

            Spacer(modifier = Modifier.height(16.dp))

            // STATS BANNER
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                SmallStatCard(
                    modifier = Modifier.weight(1.2f),
                    title = "Streak 5/5",
                    value = "${state.heroStreak.current} Hari",
                    record = "Rekor: ${state.heroStreak.best}",
                    icon = "🔥"
                )
                SmallStatCard(
                    modifier = Modifier.weight(1f),
                    title = "Tilawah Streak",
                    value = "${state.tilawahStreak.current} Hari",
                    record = "Rekor: ${state.tilawahStreak.best}",
                    icon = "📖"
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // CONSISTENCY CHART
            Text(
                text = "GRAFIK SHOLAT FARDHU 📊",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = GoldAccent,
                letterSpacing = 1.5.sp,
                modifier = Modifier
                    .align(Alignment.Start)
                    .padding(bottom = 10.dp)
            )

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("consistency_chart_card"),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.2f))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Konsistensi kamu $trendDirection dari ${avgFirstHalf.toInt()}% → ${avgSecondHalf.toInt()}% bulan ini",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (avgSecondHalf >= avgFirstHalf) RingGreen else RingRed,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    // Line Chart Canvas representation
                    ConsistencyLineChartCanvas(
                        stats = weeklyConsistency,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(120.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ACHIEVEMENTS / BADGES GRID
            Text(
                text = "PENCAPAIAN & BADGE 🏆",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = GoldAccent,
                letterSpacing = 1.5.sp,
                modifier = Modifier
                    .align(Alignment.Start)
                    .padding(bottom = 10.dp)
            )

            AchievementsGrid(unlockedBadges = state.badges)

            Spacer(modifier = Modifier.height(24.dp))

            // REWARD UNLOCKS
            Text(
                text = "REWARD MINGGU INI 🎁",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = GoldAccent,
                letterSpacing = 1.5.sp,
                modifier = Modifier
                    .align(Alignment.Start)
                    .padding(bottom = 10.dp)
            )

            RewardCollectorGallery(collectedRewards = state.rewards)

            Spacer(modifier = Modifier.height(24.dp))

            // COLLAPSIBLE SETTINGS PANEL
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { isSettingsExpanded = !isSettingsExpanded }
                    .testTag("settings_header_card"),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.25f))
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
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 10.dp)
                ) {
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

    // Reset Confirm Dialog
    if (showResetConfirm) {
        AlertDialog(
            onDismissRequest = { showResetConfirm = false },
            title = { Text("HAPUS DATA SHOLAT?", color = RingRed, fontWeight = FontWeight.Bold) },
            text = { Text("Yakin mau hapus semua data karakter & riwayat sholat? Level, streak, quest, dan rewards bakal hilang selamanya!", color = TextLight) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.resetAllData()
                        showResetConfirm = false
                    }
                ) {
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

@Composable
fun ProfileHeaderCard(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("profile_header_card"),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, Color(0xFF1F2937))
    ) {
        Column(
            modifier = Modifier
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(IslamicGreen.copy(alpha = 0.2f), Color.Transparent),
                            center = center,
                            radius = size.width / 1.5f
                        )
                    )
                }
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Gamer Avatar Icon
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(DarkBackground, CircleShape)
                    .border(BorderStroke(2.dp, GoldAccent), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "👑", fontSize = 40.sp)
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
                        .background(IslamicGreen, RoundedCornerShape(4.dp))
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

            // XP Details bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = "Level Progress", fontSize = 12.sp, color = TextMuted)
                Text(text = "${levelInfo.xpInCurrentLevel}/${levelInfo.xpNeededForNextLevel} XP", fontSize = 12.sp, color = TextLight, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(6.dp))

            LinearProgressIndicator(
                progress = { levelInfo.progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(CircleShape),
                color = IslamicGreen,
                trackColor = DarkSurfaceVariant
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "TOTAL XP", fontSize = 11.sp, color = TextMuted)
                    Text(text = "${state.user.xp}", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = GoldAccent)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "LOKASI", fontSize = 11.sp, color = TextMuted)
                    Text(text = state.user.kota, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextLight)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(text = "INTENSITAS", fontSize = 11.sp, color = TextMuted)
                    Text(text = state.user.intensityMode.capitalizeCompat(), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = IslamicGreen)
                }
            }
        }
    }
}

@Composable
fun SmallStatCard(
    modifier: Modifier,
    title: String,
    value: String,
    record: String,
    icon: String
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.15f))
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(IslamicGreen.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(text = icon, fontSize = 18.sp)
            }

            Spacer(modifier = Modifier.width(10.dp))

            Column {
                Text(text = title, fontSize = 11.sp, color = TextMuted)
                Text(text = value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextLight)
                Text(text = record, fontSize = 10.sp, color = TextMuted)
            }
        }
    }
}

@Composable
fun ConsistencyLineChartCanvas(
    stats: List<Float>,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height

        // Draw horizontal grid helper lines
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

        // Calculations for chart points
        val pointCount = stats.size // always 4
        if (pointCount < 2) return@Canvas

        val paddingX = 40.dp.toPx()
        val spacingX = (width - paddingX * 2) / (pointCount - 1)

        val path = Path()
        val points = mutableListOf<Offset>()

        for (i in 0 until pointCount) {
            val x = paddingX + i * spacingX
            // invert Y axis (0% starts at bottom of height)
            val y = height - (stats[i] / 100f) * (height * 0.8f) - (height * 0.1f)
            points.add(Offset(x, y))

            if (i == 0) {
                path.moveTo(x, y)
            } else {
                path.lineTo(x, y)
            }
        }

        // Draw glowing line path
        drawPath(
            path = path,
            color = IslamicGreen,
            style = Stroke(width = 6f, cap = StrokeCap.Round)
        )

        // Draw under-fill gradient
        val fillPath = Path().apply {
            addPath(path)
            lineTo(points.last().x, height)
            lineTo(points.first().x, height)
            close()
        }
        drawPath(
            path = fillPath,
            brush = Brush.verticalGradient(
                listOf(IslamicGreen.copy(alpha = 0.25f), Color.Transparent)
            )
        )

        // Draw points circles plus text markers
        points.forEachIndexed { idx, offset ->
            drawCircle(
                color = DarkBackground,
                radius = 12f,
                center = offset
            )
            drawCircle(
                color = IslamicGreen,
                radius = 8f,
                center = offset
            )

            // Draw indicator text (using native paint due to simplicity)
            val scoreText = "${stats[idx].toInt()}%"
            val textPaint = android.graphics.Paint().apply {
                color = android.graphics.Color.WHITE
                textSize = 9.dp.toPx()
                isFakeBoldText = true
                textAlign = android.graphics.Paint.Align.CENTER
            }
            drawContext.canvas.nativeCanvas.drawText(
                scoreText,
                offset.x,
                offset.y - 12.dp.toPx(),
                textPaint
            )

            // Draw label week below
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
        Badge("mythic_reached", "Mythic Reached", "Level 80 tercapai! 🔮", "🔮")
    )

    // Build absolute grid layout
    Column {
        var rowList = badgesPool.chunked(3)
        rowList.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                row.forEach { badge ->
                    val isUnlocked = unlockedBadges.contains(badge.id)
                    BadgeItemView(badge, isUnlocked, modifier = Modifier.weight(1f))
                }
                // Fill up remaining space if row is not full
                if (row.size < 3) {
                    repeat(3 - row.size) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
fun BadgeItemView(badge: Badge, isUnlocked: Boolean, modifier: Modifier) {
    val containerCol = if (isUnlocked) DarkSurface else DarkSurface.copy(alpha = 0.4f)
    val borderCol = if (isUnlocked) GoldAccent else Color.Gray.copy(alpha = 0.1f)

    Card(
        modifier = modifier.height(105.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = containerCol),
        border = BorderStroke(1.2.dp, borderCol)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(if (isUnlocked) GoldAccent.copy(alpha = 0.15f) else Color.Gray.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (isUnlocked) badge.icon else "🔒",
                    fontSize = 20.sp,
                    textAlign = TextAlign.Center
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = badge.title,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = if (isUnlocked) TextLight else TextMuted,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                text = badge.desc,
                fontSize = 8.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                lineHeight = 10.sp,
                maxLines = 2
            )
        }
    }
}

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

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(DarkSurface, RoundedCornerShape(20.dp))
            .border(BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.15f)), RoundedCornerShape(20.dp))
            .padding(16.dp)
    ) {
        Text(
            text = "Gacha Loot (${collectedRewards.size}/10):",
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            modifier = Modifier.padding(bottom = 12.dp)
        )

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            poolOfTen.forEachIndexed { idx, item ->
                val isUnlocked = collectedRewards.contains(item)
                val textCol = if (isUnlocked) TextLight else TextMuted
                val borderOutline = if (isUnlocked) GoldAccent else Color.Gray.copy(alpha = 0.2f)
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
                        .background(if (isUnlocked) DarkSurfaceVariant else DarkBackground)
                        .border(BorderStroke(1.dp, borderOutline), RoundedCornerShape(12.dp))
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

@Composable
fun SettingsPanelContent(
    state: MuslimLevelingData,
    viewModel: GameViewModel,
    onResetClick: () -> Unit
) {
    var username by remember { mutableStateOf(state.user.username) }
    var kota by remember { mutableStateOf(state.user.kota) }
    var intensityMode by remember { mutableStateOf(state.user.intensityMode) }
    var notifMode by remember { mutableStateOf(state.user.notifMode) }
    var selectedSantaiList by remember { mutableStateOf(state.user.santaiTrackedPrayers) }

    val context = LocalContext.current

    Card(
        modifier = Modifier.fillMaxWidth().testTag("settings_expanded_panel"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurfaceVariant)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Edit Username
            Text("Edit Nickname Gamer:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = TextLight,
                    unfocusedTextColor = TextLight,
                    focusedBorderColor = IslamicGreen,
                    unfocusedBorderColor = DarkSurface,
                    focusedContainerColor = DarkBackground,
                    unfocusedContainerColor = DarkBackground
                ),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .testTag("username_edit_field"),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Edit city
            Text("Kota/Kabupaten:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            OutlinedTextField(
                value = kota,
                onValueChange = { kota = it },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = TextLight,
                    unfocusedTextColor = TextLight,
                    focusedBorderColor = IslamicGreen,
                    unfocusedBorderColor = DarkSurface,
                    focusedContainerColor = DarkBackground,
                    unfocusedContainerColor = DarkBackground
                ),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .testTag("kota_edit_field"),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Edit Intensity
            Text("Mode Leveling:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("santai", "standar", "sultan").forEach { m ->
                    val isS = m == intensityMode
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (isS) IslamicGreen.copy(alpha = 0.2f) else DarkBackground)
                            .border(BorderStroke(if (isS) 1.5.dp else 1.dp, if (isS) IslamicGreen else Color.Transparent), RoundedCornerShape(8.dp))
                            .clickable { intensityMode = m }
                            .padding(vertical = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = m.capitalizeCompat(), fontSize = 12.sp, fontWeight = FontWeight.Bold, color = if (isS) IslamicGreen else TextLight)
                    }
                }
            }

            // If Santai, picker of 3 sholats
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
                                .clip(RoundedCornerShape(6.dp))
                                .background(if (isSel) RingBlue.copy(alpha = 0.25f) else DarkBackground)
                                .border(BorderStroke(1.dp, if (isSel) RingBlue else Color.Transparent), RoundedCornerShape(6.dp))
                                .clickable {
                                    val currentList = selectedSantaiList.toMutableList()
                                    if (isSel) {
                                        currentList.remove(pray)
                                    } else {
                                        currentList.add(pray)
                                    }
                                    selectedSantaiList = currentList
                                }
                                .padding(vertical = 6.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(text = pray.substring(0, 3).uppercase(), fontSize = 10.sp, color = if (isSel) RingBlue else TextLight)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Notifications mode selection
            Text("Mode Notifikasi HP:", fontSize = 12.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
            val notifModes = listOf("fokus", "seimbang", "intensif")
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                notifModes.forEach { n ->
                    val isS = n == notifMode
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (isS) RingBlue.copy(alpha = 0.2f) else DarkBackground)
                            .border(BorderStroke(if (isS) 1.5.dp else 1.dp, if (isS) RingBlue else Color.Transparent), RoundedCornerShape(8.dp))
                            .clickable {
                                notifMode = n
                                NotificationHelper.sendTestNotification(context, n)
                            }
                            .padding(vertical = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = n.capitalizeCompat(), fontSize = 12.sp, fontWeight = FontWeight.Bold, color = if (isS) RingBlue else TextLight)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Update action triggers Settings Update in DB and ViewModel
            Button(
                onClick = {
                    val finalSantai = if (selectedSantaiList.isEmpty()) listOf("subuh", "maghrib", "isya") else selectedSantaiList
                    viewModel.updateProfileSettings(
                        username = username.trim(),
                        kota = kota.trim(),
                        intensityMode = intensityMode,
                        santaiPrayers = finalSantai,
                        notifMode = notifMode,
                        theme = "dark"
                    )
                },
                colors = ButtonDefaults.buttonColors(containerColor = IslamicGreen, contentColor = Color.Black),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Simpan Perubahan 💾", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color.Black)
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Reset red button
            Button(
                onClick = onResetClick,
                colors = ButtonDefaults.buttonColors(containerColor = RingRed.copy(alpha = 0.2f), contentColor = RingRed),
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, RingRed),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("⚠️ Hapus Semua Data Karakter ⚠️", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = RingRed)
            }
        }
    }
}

// Data holder classes for profiles
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
