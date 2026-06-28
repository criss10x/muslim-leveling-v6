package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel
import java.time.LocalDate
import java.time.LocalTime
import java.time.temporal.ChronoUnit

// ═══════════════════════════════════════════════════════════════
// HomeScreen — rewritten to match mockup HTML 1:1
// dashboard_utama_targeted_neon_glow/code.html
// Sections: AppBar → Hero → Bento(NextMatch+Streak) → RitualRings →
//   Quest Sholat → Bonus Sunnah → Side Quest → Zikir/Doa bento →
//   Stats Arena → (BottomNav handled by MainActivity, not here).
// All VM calls preserved: logPrayer/unlogPrayer/claimQuest/
//   getLevelInfo/getRankTitle/checkSunnahOnTime/getSunnahTimeHintPublic.
// ═══════════════════════════════════════════════════════════════

@Composable
fun HomeScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    var showUnlogConfirm by remember { mutableStateOf<String?>(null) }
    val todayStr = LocalDate.now().toString()

    val wajibList = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya")
    val checkedWajibToday = wajibList.count { p ->
        state.prayerLog.any { it.date == todayStr && it.prayer == p }
    }
    val wajibDenominator = 5

    val sunnahCount = state.prayerLog.count {
        it.date == todayStr && (
            it.type == "sunnah" ||
            it.prayer == "dhuha" ||
            it.prayer == "rawatib" ||
            it.prayer == "tahajjud" ||
            it.prayer.startsWith("rawatib_")
        )
    }
    val sunnahDenominator = 8

    val tilawahLogged = state.prayerLog.any { it.date == todayStr && it.prayer == "tilawah" }

    // Zikir counter state — daily reset
    val zikirCount = if (state.zikirCounter.date == todayStr) state.zikirCounter.count else 0
    val zikirGoal = 100

    // Quick Doa checklist state (mockup: Makan, Keluar Rumah, Tidur)
    var doaMakan by remember { mutableStateOf(false) }
    var doaKeluar by remember { mutableStateOf(false) }
    var doaTidur by remember { mutableStateOf(false) }

    val scrollState = rememberScrollState()

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
                .padding(bottom = 96.dp), // space for bottom nav (handled by MainActivity)
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ── 1. Fixed AppBar ──
            MockupAppBar(state = state, viewModel = viewModel)
            Spacer(modifier = Modifier.height(16.dp))

            // ── 2. Hero Section: Rank + XP + Streak pill ──
            HeroSection(state = state, viewModel = viewModel)
            Spacer(modifier = Modifier.height(16.dp))

            // ── 3. Bento grid: Next Match + Streak ──
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                NextMatchBento(
                    state = state,
                    checkedWajibToday = checkedWajibToday,
                    wajibDenominator = wajibDenominator,
                    modifier = Modifier.weight(1f)
                )
                StreakBento(
                    streak = state.heroStreak.current,
                    modifier = Modifier.width(132.dp)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))

            // ── 4. Ritual Rings section ──
            RitualRingsSection(
                checkedWajibToday = checkedWajibToday,
                wajibDenominator = wajibDenominator,
                sunnahCount = sunnahCount,
                sunnahDenominator = sunnahDenominator,
                tilawahLogged = tilawahLogged
            )
            Spacer(modifier = Modifier.height(20.dp))

            // ── 5. Quest Sholat Hari Ini ──
            MockupSectionHeader(
                text = "QUEST SHOLAT HARI INI",
                icon = "✓",
                color = IslamicGreen
            )
            Spacer(modifier = Modifier.height(8.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val timings = state.prayerTimesCache.timings
                val prayers = listOf(
                    Triple("Subuh", "subuh", timings.subuh),
                    Triple("Dzuhur", "dzuhur", timings.dzuhur),
                    Triple("Ashar", "ashar", timings.ashar),
                    Triple("Maghrib", "maghrib", timings.maghrib),
                    Triple("Isya", "isya", timings.isya)
                )
                prayers.forEach { (name, key, time) ->
                    val isChecked = state.prayerLog.any { it.date == todayStr && it.prayer == key }
                    val isActive = !isChecked && isCurrentOrUpcoming(key, timings)
                    val isLocked = !isChecked && !isPrayerWindowOpen(key, timings)
                    PrayerRowCard(
                        name = name,
                        time = time,
                        isChecked = isChecked,
                        isActive = isActive,
                        isLocked = isLocked,
                        onCheckedChange = { check ->
                            if (check) {
                                viewModel.logPrayer(key, "wajib")
                            } else {
                                showUnlogConfirm = key
                            }
                        }
                    )
                }
            }
            Spacer(modifier = Modifier.height(20.dp))

            // ── 6. Bonus Quest — Sunnah ──
            MockupSectionHeader(
                text = "BONUS QUEST — SUNNAH",
                icon = "✦",
                color = GoldAccent
            )
            Spacer(modifier = Modifier.height(8.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val sunnahItems = listOf(
                    Triple("dhuha", "Sholat Dhuha", "Sunnah pagi"),
                    Triple("tahajjud", "Sholat Tahajjud", "Sunnah sepertiga malam"),
                    Triple("rawatib_subuh_qobliyah", "Qobliyah Subuh", "2 rakaat sebelum Subuh"),
                    Triple("rawatib_dzuhur_qobliyah", "Qobliyah Dzuhur Sebelum", "2-4 rakaat sebelum Dzuhur"),
                    Triple("rawatib_dzuhur_ba'diyyah", "Ba'diyyah Dzuhur Sesudah", "2 rakaat sesudah Dzuhur"),
                    Triple("rawatib_ashar_qobliyah", "Qobliyah Ashar", "2-4 rakaat sebelum Ashar"),
                    Triple("rawatib_maghrib_ba'diyyah", "Ba'diyyah Maghrib", "2 rakaat sesudah Maghrib"),
                    Triple("rawatib_isya_ba'diyyah", "Ba'diyyah Isya", "2 rakaat sesudah Isya")
                )
                sunnahItems.forEach { (id, name, desc) ->
                    val isChecked = state.prayerLog.any { it.date == todayStr && it.prayer == id }
                    val isOnTime = viewModel.checkSunnahOnTime(id, state.prayerTimesCache.timings)
                    val isTimeLocked = !isOnTime && !isChecked
                    SunnahRowCard(
                        id = id,
                        name = name,
                        desc = desc,
                        isChecked = isChecked,
                        isTimeLocked = isTimeLocked,
                        timeWindowHint = viewModel.getSunnahTimeHintPublic(id),
                        onCheckedChange = { check ->
                            if (check) {
                                viewModel.logPrayer(id, "sunnah")
                            } else {
                                showUnlogConfirm = id
                            }
                        }
                    )
                }
            }
            Spacer(modifier = Modifier.height(20.dp))

            // ── 7. Side Quest divider + chamfer card ──
            SideQuestDivider()
            Spacer(modifier = Modifier.height(12.dp))
            SideQuestChamferCard(
                isClaimed = tilawahLogged,
                onLog = { viewModel.logPrayer("tilawah", "tilawah") }
            )
            Spacer(modifier = Modifier.height(20.dp))

            // ── 8. Bento grid: Zikir Clicker + Quick Doa ──
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ZikirClickerBento(
                    count = zikirCount,
                    goal = zikirGoal,
                    modifier = Modifier.weight(1f)
                )
                QuickDoaBento(
                    makan = doaMakan,
                    keluar = doaKeluar,
                    tidur = doaTidur,
                    onMakanChange = { doaMakan = it },
                    onKeluarChange = { doaKeluar = it },
                    onTidurChange = { doaTidur = it },
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(modifier = Modifier.height(20.dp))

            // ── 9. Stats Arena 2x2 ──
            MockupSectionHeader(
                text = "STATS ARENA",
                icon = "📊",
                color = TextMuted
            )
            Spacer(modifier = Modifier.height(8.dp))
            StatsArena2x2(state = state, viewModel = viewModel)
        }
    }

    // Unlog Confirm Modal
    if (showUnlogConfirm != null) {
        val prayerName = showUnlogConfirm!!
        AlertDialog(
            onDismissRequest = { showUnlogConfirm = null },
            title = { Text("⚠️ Batalin Sholat?", color = TextLight, fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    "Yakin mau batalin catatan Sholat ${prayerName.capitalizeCompat()} hari ini? " +
                        "XP dan streak bakal dikurangi ya!",
                    color = TextMuted
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.unlogPrayer(prayerName, todayStr)
                        showUnlogConfirm = null
                    }
                ) {
                    Text("Iya, Batalkan", color = RingRed, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showUnlogConfirm = null }) {
                    Text("Tutup", color = TextMuted)
                }
            },
            containerColor = DarkSurface,
            shape = RoundedCornerShape(20.dp)
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// 1. APP BAR — hex rank icon + gradient title + settings gear
// ═══════════════════════════════════════════════════════════════

@Composable
private fun MockupAppBar(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)
    val tier = rankTitle.substringBefore(" ").ifEmpty { "MUSLIM" }
    val division = rankTitle.substringAfter(" ", "").uppercase()

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(48.dp)
            .background(
                Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.8f), DarkBackground.copy(alpha = 0.8f))),
                RoundedCornerShape(12.dp)
            )
            .border(
                BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.3f)),
                RoundedCornerShape(12.dp)
            )
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Hex rank icon
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .border(BorderStroke(2.dp, IslamicGreen), CircleShape)
                        .background(DarkSurface),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "★",
                        color = GoldAccent,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Black
                    )
                }
                Text(
                    text = "MUSLIM LEVELING",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Black,
                    color = IslamicGreen,
                    letterSpacing = (-0.5).sp
                )
            }
            Icon(
                imageVector = Icons.Default.Settings,
                contentDescription = "Settings",
                tint = IslamicGreen,
                modifier = Modifier.size(28.dp)
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 2. HERO SECTION — glass-panel: CURRENT RANK + XP progress + streak pill
// ═══════════════════════════════════════════════════════════════

@Composable
private fun HeroSection(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)
    val xpInLevel = levelInfo.xpInCurrentLevel
    val xpNeeded = levelInfo.xpNeededForNextLevel
    val xpRemaining = (xpNeeded - xpInLevel).coerceAtLeast(0)

    MockupGlassPanel(modifier = Modifier.padding(horizontal = 16.dp)) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "CURRENT RANK",
                        fontSize = 11.sp,
                        color = TextMuted,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = rankTitle,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black,
                        color = IslamicGreen
                    )
                }
                // Streak pill
                Row(
                    modifier = Modifier
                        .background(DarkSurfaceElevated, RoundedCornerShape(100.dp))
                        .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.5f)), RoundedCornerShape(100.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(text = "🔥", fontSize = 12.sp)
                    Text(
                        text = "${state.heroStreak.current} Hari",
                        fontSize = 11.sp,
                        color = TextLight,
                        fontWeight = FontWeight.Black
                    )
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            // XP Progress
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "XP Progress",
                    fontSize = 11.sp,
                    color = TextMuted,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 1.sp
                )
                Text(
                    text = "$xpInLevel / $xpNeeded",
                    fontSize = 13.sp,
                    color = IslamicGreen,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(14.dp)
                    .clip(RoundedCornerShape(100.dp))
                    .background(XpBarTrack)
                    .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.5f)), RoundedCornerShape(100.dp))
            ) {
                val progressFraction = (levelInfo.progress).coerceIn(0f, 1f)
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(fraction = progressFraction)
                        .clip(RoundedCornerShape(100.dp))
                        .background(
                            Brush.horizontalGradient(listOf(IslamicGreenDim, IslamicGreen))
                        )
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "$xpRemaining XP to Next Rank",
                fontSize = 11.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.End
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 3a. NEXT MATCH bento — countdown to next prayer
// ═══════════════════════════════════════════════════════════════

@Composable
private fun NextMatchBento(
    state: MuslimLevelingData,
    checkedWajibToday: Int,
    wajibDenominator: Int,
    modifier: Modifier = Modifier
) {
    val timer = getNextPrayerTimerInfo(
        state.prayerTimesCache.timings,
        checkedWajibToday,
        wajibDenominator
    )
    val countdown = buildString {
        // timer.duration is "HH:MM" — append ":00" to match mockup "00:42:15"
        val dur = timer.duration
        if (dur.length == 5 && dur.contains(":")) {
            append(dur).append(":00")
        } else {
            append("00:00:00")
        }
    }

    val pulse = rememberInfiniteTransition(label = "next_match_pulse")
    val pulseAlpha by pulse.animateFloat(
        initialValue = 0.6f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1500, easing = LinearEasing), RepeatMode.Reverse),
        label = "pulse_alpha"
    )

    Box(
        modifier = modifier
            .height(120.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), DarkBackground.copy(alpha = 0.6f))))
            .border(
                BorderStroke(1.dp, CyanAccent.copy(alpha = 0.4f * pulseAlpha)),
                RoundedCornerShape(12.dp)
            )
            .drawBehind {
                drawRect(
                    color = CyanAccent.copy(alpha = 0.7f),
                    topLeft = Offset.Zero,
                    size = Size(4.dp.toPx(), size.height)
                )
            }
            .padding(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxSize(), verticalArrangement = Arrangement.SpaceBetween) {
            Text(
                text = "NEXT MATCH",
                fontSize = 10.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
            Column {
                Text(
                    text = timer.label.removeSuffix(" dalam").uppercase(),
                    fontSize = 22.sp,
                    color = CyanAccent,
                    fontWeight = FontWeight.Black
                )
                Text(
                    text = countdown,
                    fontSize = 18.sp,
                    color = TextLight,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 3b. STREAK bento — big number + "HARI STREAK"
// ═══════════════════════════════════════════════════════════════

@Composable
private fun StreakBento(streak: Int, modifier: Modifier = Modifier) {
    val pulse = rememberInfiniteTransition(label = "streak_pulse")
    val pulseAlpha by pulse.animateFloat(
        initialValue = 0.6f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(2000, easing = LinearEasing), RepeatMode.Reverse),
        label = "streak_pulse_alpha"
    )
    Box(
        modifier = modifier
            .height(120.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), DarkBackground.copy(alpha = 0.6f))))
            .border(
                BorderStroke(1.dp, GoldAccent.copy(alpha = 0.4f * pulseAlpha)),
                RoundedCornerShape(12.dp)
            )
            .drawBehind {
                drawRect(
                    color = GoldAccent.copy(alpha = 0.7f),
                    topLeft = Offset.Zero,
                    size = Size(4.dp.toPx(), size.height)
                )
            }
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(text = "🔥", fontSize = 22.sp)
            Text(
                text = "$streak",
                fontSize = 28.sp,
                color = GoldAccent,
                fontWeight = FontWeight.Black
            )
            Text(
                text = "HARI STREAK",
                fontSize = 10.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 4. RITUAL RINGS section — donut + legend (Wajib/Sunnah/Tilawah)
// ═══════════════════════════════════════════════════════════════

@Composable
private fun RitualRingsSection(
    checkedWajibToday: Int,
    wajibDenominator: Int,
    sunnahCount: Int,
    sunnahDenominator: Int,
    tilawahLogged: Boolean
) {
    val wajibProgress = (checkedWajibToday.toFloat() / wajibDenominator.toFloat()).coerceIn(0f, 1f)
    val sunnahProgress = (sunnahCount.toFloat() / sunnahDenominator.toFloat()).coerceIn(0f, 1f)
    val tilawahProgress = if (tilawahLogged) 1f else 0f

    MockupGlassPanel(modifier = Modifier.padding(horizontal = 16.dp)) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = "◎", color = IslamicGreen, fontSize = 14.sp)
                Text(
                    text = "RITUAL RINGS",
                    fontSize = 11.sp,
                    color = IslamicGreen,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 1.sp
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Box(
                    modifier = Modifier.size(128.dp),
                    contentAlignment = Alignment.Center
                ) {
                    RitualRingsCanvas(
                        wajibProgress = wajibProgress,
                        sunnahProgress = sunnahProgress,
                        tilawahProgress = tilawahProgress,
                        showSunnahRing = true,
                        modifier = Modifier.fillMaxSize().testTag("ritual_rings_canvas")
                    )
                }
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    RingLegendRow(color = IslamicGreen, name = "WAJIB", value = "$checkedWajibToday/$wajibDenominator")
                    RingLegendRow(color = GoldAccent, name = "SUNNAH", value = "$sunnahCount/$sunnahDenominator")
                    RingLegendRow(color = CyanAccent, name = "TILAWAH", value = if (tilawahLogged) "Lengkap" else "Belum")
                }
            }
        }
    }
}

@Composable
private fun RingLegendRow(color: Color, name: String, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .shadow(3.dp, CircleShape, ambientColor = color.copy(alpha = 0.6f))
                .background(color, CircleShape)
        )
        Column {
            Text(
                text = name,
                fontSize = 11.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
            Text(
                text = value,
                fontSize = 18.sp,
                color = color,
                fontWeight = FontWeight.Black
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 5-6. Section header — small caps with icon dot
// ═══════════════════════════════════════════════════════════════

@Composable
private fun MockupSectionHeader(text: String, icon: String, color: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(text = icon, color = color, fontSize = 14.sp)
        Text(
            text = text,
            fontSize = 12.sp,
            color = color,
            fontWeight = FontWeight.Black,
            letterSpacing = 1.2.sp
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// 7. SIDE QUEST divider + chamfer card
// ═══════════════════════════════════════════════════════════════

@Composable
private fun SideQuestDivider() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(OutlineVariant.copy(alpha = 0.5f))
        )
        Box(modifier = Modifier.padding(horizontal = 12.dp)) {
            Text(
                text = "📜 SIDE QUEST",
                fontSize = 12.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
        }
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(OutlineVariant.copy(alpha = 0.5f))
        )
    }
}

@Composable
private fun SideQuestChamferCard(isClaimed: Boolean, onLog: () -> Unit) {
    val chamferShape = RoundedCornerShape(12.dp) // ponytail: chamfer clip-path approximated via rounded shape
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(80.dp)
            .clip(chamferShape)
            .background(
                Brush.linearGradient(
                    listOf(CyanAccent.copy(alpha = 0.2f), IslamicGreen.copy(alpha = 0.1f))
                )
            )
            .border(BorderStroke(1.dp, CyanAccent.copy(alpha = 0.4f)), chamferShape)
            .shadow(8.dp, chamferShape, ambientColor = CyanAccent.copy(alpha = 0.15f))
            .clickable { if (!isClaimed) onLog() }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
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
                        .size(44.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(CyanAccent.copy(alpha = 0.2f))
                        .border(BorderStroke(1.dp, CyanAccent.copy(alpha = 0.3f)), RoundedCornerShape(8.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "📖", fontSize = 22.sp)
                }
                Column {
                    Text(
                        text = "Tilawah & Dzikir",
                        fontSize = 16.sp,
                        color = TextLight,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = if (isClaimed) "Sudah selesai hari ini ✓" else "Selesaikan juz harianmu",
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                }
            }
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(CyanAccent)
                    .shadow(8.dp, CircleShape, ambientColor = CyanAccent.copy(alpha = 0.6f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PlayArrow,
                    contentDescription = "Mulai",
                    tint = Color.Black,
                    modifier = Modifier.size(22.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 8a. ZIKIR CLICKER bento — SUBHANALLAH counter + progress
// ═══════════════════════════════════════════════════════════════

@Composable
private fun ZikirClickerBento(count: Int, goal: Int, modifier: Modifier = Modifier) {
    val progress = (count.toFloat() / goal.toFloat()).coerceIn(0f, 1f)
    Box(
        modifier = modifier
            .height(150.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), DarkBackground.copy(alpha = 0.6f))))
            .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.2f)), RoundedCornerShape(12.dp))
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier.fillMaxSize()
        ) {
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.TopEnd) {
                Text(
                    text = "DAILY",
                    fontSize = 10.sp,
                    color = TextMuted,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 1.sp
                )
            }
            Text(
                text = "SUBHANALLAH",
                fontSize = 10.sp,
                color = IslamicGreen,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
            Text(
                text = "$count",
                fontSize = 30.sp,
                color = IslamicGreen,
                fontWeight = FontWeight.Black
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(RoundedCornerShape(100.dp))
                    .background(XpBarTrack)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(fraction = progress)
                        .clip(RoundedCornerShape(100.dp))
                        .background(IslamicGreen)
                )
            }
            Text(
                text = "GOAL: $goal",
                fontSize = 10.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// 8b. QUICK DOA bento — checklist (Makan, Keluar Rumah, Tidur)
// ═══════════════════════════════════════════════════════════════

@Composable
private fun QuickDoaBento(
    makan: Boolean,
    keluar: Boolean,
    tidur: Boolean,
    onMakanChange: (Boolean) -> Unit,
    onKeluarChange: (Boolean) -> Unit,
    onTidurChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .height(150.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), DarkBackground.copy(alpha = 0.6f))))
            .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.2f)), RoundedCornerShape(12.dp))
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "QUICK DOA",
                fontSize = 10.sp,
                color = CyanAccent,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
            DoaCheckRow(label = "Makan", checked = makan, onCheckedChange = onMakanChange)
            DoaCheckRow(label = "Keluar Rumah", checked = keluar, onCheckedChange = onKeluarChange)
            DoaCheckRow(label = "Tidur", checked = tidur, onCheckedChange = onTidurChange)
        }
    }
}

@Composable
private fun DoaCheckRow(label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.clickable { onCheckedChange(!checked) }
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(if (checked) CyanAccent else DarkSurfaceVariant)
                .border(
                    BorderStroke(1.dp, if (checked) CyanAccent else OutlineDefault),
                    RoundedCornerShape(4.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            if (checked) {
                Text(text = "✓", color = Color.Black, fontSize = 10.sp, fontWeight = FontWeight.Black)
            }
        }
        Text(text = label, fontSize = 12.sp, color = TextLight)
    }
}

// ═══════════════════════════════════════════════════════════════
// 9. STATS ARENA 2x2 — TOTAL PRAYERS / BEST STREAK / TOTAL XP / RANK PROGRESS
// ═══════════════════════════════════════════════════════════════

@Composable
private fun StatsArena2x2(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val totalPrayers = state.prayerLog.count { it.type == "wajib" }
    val bestStreak = state.heroStreak.best
    val totalXp = state.user.xp
    val rankProgressPct = (levelInfo.progress * 100).toInt().coerceIn(0, 100)

    val stats = listOf(
        Triple("TOTAL PRAYERS", "$totalPrayers", IslamicGreen),
        Triple("BEST STREAK", "$bestStreak", GoldAccent),
        Triple("TOTAL XP", "$totalXp", CyanAccent),
        Triple("RANK PROGRESS", "$rankProgressPct%", TextLight)
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        stats.chunked(2).forEach { rowStats ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                rowStats.forEach { (label, value, color) ->
                    StatsArenaTile(
                        label = label,
                        value = value,
                        color = color,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun StatsArenaTile(label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .height(80.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(
                Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), Color.Transparent))
            )
            .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.2f)), RoundedCornerShape(8.dp))
            .padding(14.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = label,
                fontSize = 10.sp,
                color = TextMuted,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )
            Text(
                text = value,
                fontSize = 22.sp,
                color = color,
                fontWeight = FontWeight.Black
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// GLASS PANEL — shared container matching .glass-panel style
// ═══════════════════════════════════════════════════════════════

@Composable
private fun MockupGlassPanel(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Brush.verticalGradient(listOf(DarkSurface.copy(alpha = 0.6f), DarkSurfaceElevated.copy(alpha = 0.4f))))
            .border(BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.2f)), RoundedCornerShape(12.dp))
            .shadow(4.dp, RoundedCornerShape(12.dp), ambientColor = IslamicGreen.copy(alpha = 0.1f))
    ) {
        content()
    }
}

// ═══════════════════════════════════════════════════════════════
// RITUAL RINGS CANVAS — three concentric progress rings (Wajib outer,
// Sunnah middle, Tilawah inner). Reused from prior impl.
// ═══════════════════════════════════════════════════════════════

@Composable
fun RitualRingsCanvas(
    wajibProgress: Float,
    sunnahProgress: Float,
    tilawahProgress: Float,
    showSunnahRing: Boolean,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val center = center
        val strokeWidth = 8.dp.toPx()
        val outerRadius = (size.minDimension / 2) - 8.dp.toPx()

        // Outer ring: Wajib (emerald primary)
        drawCircle(
            color = XpBarTrack,
            radius = outerRadius,
            center = center,
            style = Stroke(width = strokeWidth)
        )
        if (wajibProgress > 0f) {
            drawArc(
                color = IslamicGreen,
                startAngle = -90f,
                sweepAngle = wajibProgress * 360f,
                useCenter = false,
                topLeft = Offset(center.x - outerRadius, center.y - outerRadius),
                size = Size(outerRadius * 2, outerRadius * 2),
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        if (showSunnahRing) {
            val midRadius = (size.minDimension / 2) - 22.dp.toPx()
            drawCircle(
                color = XpBarTrack,
                radius = midRadius,
                center = center,
                style = Stroke(width = strokeWidth)
            )
            if (sunnahProgress > 0f) {
                drawArc(
                    color = GoldAccent,
                    startAngle = -90f,
                    sweepAngle = sunnahProgress * 360f,
                    useCenter = false,
                    topLeft = Offset(center.x - midRadius, center.y - midRadius),
                    size = Size(midRadius * 2, midRadius * 2),
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }
        }

        val innerRadius = (size.minDimension / 2) - 36.dp.toPx()
        drawCircle(
            color = XpBarTrack,
            radius = innerRadius,
            center = center,
            style = Stroke(width = strokeWidth)
        )
        if (tilawahProgress > 0f) {
            drawArc(
                color = CyanAccent,
                startAngle = -90f,
                sweepAngle = tilawahProgress * 360f,
                useCenter = false,
                topLeft = Offset(center.x - innerRadius, center.y - innerRadius),
                size = Size(innerRadius * 2, innerRadius * 2),
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PRAYER ROW CARD — quest sholat (Completed / Active Now / Locked)
// ═══════════════════════════════════════════════════════════════

@Composable
fun PrayerRowCard(
    name: String,
    time: String,
    isChecked: Boolean,
    isActive: Boolean,
    isLocked: Boolean = false,
    onCheckedChange: (Boolean) -> Unit
) {
    val pulse = rememberInfiniteTransition(label = "prayer_active_pulse")
    val activePulse by pulse.animateFloat(
        initialValue = 0.5f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1100, easing = LinearEasing), RepeatMode.Reverse),
        label = "active_pulse_alpha"
    )

    val accentColor = when {
        isChecked -> IslamicGreen
        isActive -> IslamicGreen
        isLocked -> OutlineDefault
        else -> DarkSurfaceVariant
    }
    val containerColor = when {
        isChecked -> Brush.verticalGradient(listOf(IslamicGreen.copy(alpha = 0.12f), DarkSurface))
        isActive -> Brush.verticalGradient(listOf(IslamicGreen.copy(alpha = 0.1f * activePulse), DarkSurface))
        isLocked -> Brush.verticalGradient(listOf(DarkBackground.copy(alpha = 0.4f), DarkSurface.copy(alpha = 0.6f)))
        else -> Brush.verticalGradient(GradientDarkSurface)
    }
    val borderStroke = when {
        isChecked -> BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.6f))
        isActive -> BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.4f * activePulse))
        isLocked -> BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.3f))
        else -> BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.3f))
    }
    val nameColor = when {
        isChecked -> IslamicGreen
        isActive -> IslamicGreen
        isLocked -> TextMuted
        else -> TextLight
    }
    val statusText = when {
        isChecked -> "COMPLETED"
        isActive -> "ACTIVE NOW"
        isLocked -> "LOCKED"
        else -> "ACTIVE NOW"
    }
    val statusColor = when {
        isChecked -> IslamicGreen
        isActive -> IslamicGreen
        isLocked -> TextMuted
        else -> IslamicGreen
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(8.dp))
            .drawBehind {
                // Left accent bar (4dp)
                drawRect(
                    color = accentColor,
                    topLeft = Offset.Zero,
                    size = Size(4.dp.toPx(), size.height)
                )
            }
            .then(if (isLocked) Modifier.alpha(0.5f) else Modifier)
            .clickable { onCheckedChange(!isChecked) }
            .testTag("prayer_card_${name.lowercase()}")
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Status icon
                if (isChecked) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = IslamicGreen,
                        modifier = Modifier.size(22.dp)
                    )
                } else if (isLocked) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = null,
                        tint = OutlineDefault,
                        modifier = Modifier.size(22.dp)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(22.dp)
                            .border(BorderStroke(2.dp, IslamicGreen), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .background(IslamicGreen, CircleShape)
                        )
                    }
                }
                Text(
                    text = name,
                    fontSize = 16.sp,
                    color = nameColor,
                    fontWeight = FontWeight.SemiBold
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = statusText,
                    fontSize = 10.sp,
                    color = statusColor,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 1.sp
                )
                if (isActive) {
                    Text(
                        text = time,
                        fontSize = 10.sp,
                        color = TextMuted,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.sp
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// SUNNAH ROW CARD — bonus quest sunnah list
// ═══════════════════════════════════════════════════════════════

@Composable
fun SunnahRowCard(
    id: String,
    name: String,
    desc: String,
    isChecked: Boolean,
    isTimeLocked: Boolean = false,
    timeWindowHint: String = "",
    onCheckedChange: (Boolean) -> Unit
) {
    val accentColor = if (isChecked) IslamicGreen else GoldAccent
    val containerColor = when {
        isChecked -> Brush.verticalGradient(listOf(IslamicGreen.copy(alpha = 0.1f), DarkSurface))
        isTimeLocked -> Brush.verticalGradient(listOf(DarkBackground.copy(alpha = 0.4f), DarkSurface.copy(alpha = 0.6f)))
        else -> Brush.verticalGradient(GradientDarkSurface)
    }
    val borderStroke = when {
        isChecked -> BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.5f))
        isTimeLocked -> BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.3f))
        else -> BorderStroke(1.dp, GoldAccent.copy(alpha = 0.4f))
    }
    val nameColor = when {
        isChecked -> IslamicGreen
        isTimeLocked -> TextMuted
        else -> TextLight
    }
    val descText = if (isTimeLocked && !isChecked && timeWindowHint.isNotEmpty()) timeWindowHint else desc

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(8.dp))
            .drawBehind {
                if (!isChecked && !isTimeLocked) {
                    drawRect(
                        color = GoldAccent,
                        topLeft = Offset.Zero,
                        size = Size(4.dp.toPx(), size.height)
                    )
                } else if (isChecked) {
                    drawRect(
                        color = IslamicGreen,
                        topLeft = Offset.Zero,
                        size = Size(4.dp.toPx(), size.height)
                    )
                }
            }
            .then(if (isTimeLocked && !isChecked) Modifier.alpha(0.5f) else Modifier)
            .clickable { onCheckedChange(!isChecked) }
            .testTag("sunnah_card_$id")
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 14.dp, end = 14.dp, top = 12.dp, bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.weight(1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(
                            if (isChecked) IslamicGreen.copy(alpha = 0.15f)
                            else if (isTimeLocked) DarkBackground.copy(alpha = 0.3f)
                            else GoldAccent.copy(alpha = 0.12f)
                        )
                        .border(
                            BorderStroke(
                                1.dp,
                                when {
                                    isChecked -> IslamicGreen.copy(alpha = 0.3f)
                                    isTimeLocked -> OutlineVariant.copy(alpha = 0.3f)
                                    else -> GoldAccent.copy(alpha = 0.3f)
                                }
                            ),
                            RoundedCornerShape(8.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (isTimeLocked && !isChecked) "🔒" else if (isChecked) "✓" else "✦",
                        color = if (isChecked) IslamicGreen else if (isTimeLocked) OutlineDefault else GoldAccent,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Black
                    )
                }
                Column {
                    Text(
                        text = name,
                        fontSize = 14.sp,
                        fontWeight = if (isChecked) FontWeight.Bold else FontWeight.SemiBold,
                        color = nameColor
                    )
                    Text(
                        text = descText,
                        fontSize = 10.sp,
                        color = if (isTimeLocked && !isChecked) TextMuted.copy(alpha = 0.6f) else TextMuted,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 0.5.sp
                    )
                }
            }
            // Right: check icon or lock icon
            if (isChecked) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = IslamicGreen,
                    modifier = Modifier.size(20.dp)
                )
            } else if (isTimeLocked) {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = null,
                    tint = OutlineDefault,
                    modifier = Modifier.size(16.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .border(BorderStroke(2.dp, GoldAccent), CircleShape)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// HELPERS — prayer time window logic (kept from prior impl)
// ═══════════════════════════════════════════════════════════════

data class NextPrayerTimer(
    val label: String,
    val duration: String,
    val tagline: String
)

fun getNextPrayerTimerInfo(timings: Timings, currentWajib: Int, denominator: Int): NextPrayerTimer {
    val now = LocalTime.now()
    val prayerList = listOf(
        Pair("Subuh", timings.subuh),
        Pair("Dzuhur", timings.dzuhur),
        Pair("Ashar", timings.ashar),
        Pair("Maghrib", timings.maghrib),
        Pair("Isya", timings.isya)
    )
    for (p in prayerList) {
        try {
            val pTime = LocalTime.parse(p.second)
            if (now.isBefore(pTime)) {
                val diffMins = ChronoUnit.MINUTES.between(now, pTime)
                val hrs = diffMins / 60
                val mins = diffMins % 60
                val duration = String.format("%02d:%02d", hrs, mins)
                val label = "${p.first} dalam"
                val tagline = "Lengkapi ring Wajib biar streak gak putus!"
                return NextPrayerTimer(label, duration, tagline)
            }
        } catch (e: Exception) {
            // ignore
        }
    }
    return NextPrayerTimer("Subuh besok", timings.subuh, "Hari ini udah kelar! Istirahat yang cukup ya 😴")
}

fun tryParsing(timeStr: String, default: LocalTime): LocalTime {
    return try {
        LocalTime.parse(timeStr)
    } catch (e: Exception) {
        default
    }
}

fun isPrayerWindowOpen(prayer: String, timings: Timings): Boolean {
    val now = LocalTime.now()
    val subuh = tryParsing(timings.subuh, LocalTime.of(4, 30))
    val dzuhur = tryParsing(timings.dzuhur, LocalTime.of(12, 0))
    val maghrib = tryParsing(timings.maghrib, LocalTime.of(17, 50))
    return when (prayer) {
        "subuh" -> {
            val windowEnd = subuh.plusHours(2)
            if (windowEnd.isAfter(subuh)) !now.isBefore(subuh) && now.isBefore(windowEnd)
            else !now.isBefore(subuh) || now.isBefore(windowEnd)
        }
        "dzuhur", "ashar" -> !now.isBefore(dzuhur) && now.isBefore(maghrib)
        "maghrib", "isya" -> !now.isBefore(maghrib) || now.isBefore(subuh)
        else -> false
    }
}

fun isCurrentOrUpcoming(prayer: String, timings: Timings): Boolean {
    val now = LocalTime.now()
    val subuh = tryParsing(timings.subuh, LocalTime.of(4, 30))
    val dzuhur = tryParsing(timings.dzuhur, LocalTime.of(12, 0))
    val ashar = tryParsing(timings.ashar, LocalTime.of(15, 10))
    val maghrib = tryParsing(timings.maghrib, LocalTime.of(17, 50))
    val isya = tryParsing(timings.isya, LocalTime.of(19, 0))
    return when (prayer) {
        "subuh" -> now.isBefore(dzuhur) && (now.isAfter(subuh.minusMinutes(30)) || now.isBefore(subuh.plusMinutes(90)))
        "dzuhur" -> now.isAfter(subuh.plusMinutes(90)) && now.isBefore(ashar)
        "ashar" -> now.isAfter(dzuhur) && now.isBefore(maghrib)
        "maghrib" -> now.isAfter(ashar) && now.isBefore(isya)
        "isya" -> now.isAfter(maghrib) || now.isBefore(subuh.minusMinutes(30))
        else -> false
    }
}
