package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.components.NeonProgressBar
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

@OptIn(ExperimentalAnimationApi::class)
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

    val isSantaiMode = state.user.intensityMode == "santai"
    val isStandarMode = state.user.intensityMode == "standar"
    val isSultanMode = state.user.intensityMode == "sultan"

    val wajibDenominator = if (isSantaiMode) {
        state.user.santaiTrackedPrayers.size.coerceAtLeast(1)
    } else 5

    val checkedTrackedWajibToday = if (isSantaiMode) {
        state.user.santaiTrackedPrayers.count { p ->
            state.prayerLog.any { it.date == todayStr && it.prayer == p }
        }
    } else checkedWajibToday

    val wajibProgress = (checkedTrackedWajibToday.toFloat() / wajibDenominator.toFloat()).coerceIn(0f, 1f)

    val sunnahCount = state.prayerLog.count {
        it.date == todayStr && (
            it.type == "sunnah" ||
            it.prayer == "dhuha" ||
            it.prayer == "rawatib" ||
            it.prayer == "tahajjud" ||
            it.prayer.startsWith("rawatib_")
        )
    }
    val sunnahDenominator = 8f
    val sunnahProgress = (sunnahCount.toFloat() / sunnahDenominator).coerceIn(0f, 1f)

    val tilawahLogged = state.prayerLog.any { it.date == todayStr && it.prayer == "tilawah" }
    val tilawahProgress = if (tilawahLogged) 1f else 0f

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
                .padding(bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ═══ BINTANG SEAL — Hero ═══
            BintangSealHero(state, viewModel)

            Spacer(modifier = Modifier.height(16.dp))

            // ═══ COUNTDOWN CARD — Next Prayer Match Timer ═══
            CountdownCard(
                state = state,
                checkedTrackedWajibToday = checkedTrackedWajibToday,
                wajibDenominator = wajibDenominator
            )

            Spacer(modifier = Modifier.height(20.dp))

            // ═══ RITUAL RINGS ═══
            SectionPill(text = "⚔ DAILY QUEST", gradient = GradientGreenGold)

            Spacer(modifier = Modifier.height(10.dp))

            // Main rings card with neon gradient border + glow
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .shadow(
                        elevation = 22.dp,
                        shape = RoundedCornerShape(24.dp),
                        ambientColor = IslamicGreen.copy(alpha = 0.35f),
                        spotColor = CyanAccent.copy(alpha = 0.2f)
                    ),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                border = BorderStroke(
                    1.5.dp,
                    Brush.linearGradient(listOf(IslamicGreen, CyanAccent, IslamicGreen))
                )
            ) {
                Box(
                    modifier = Modifier
                        .background(Brush.verticalGradient(GradientDarkSurface))
                ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Rings with neon glow
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier.size(120.dp)
                        ) {
                            RitualRingsCanvas(
                                wajibProgress = wajibProgress,
                                sunnahProgress = sunnahProgress,
                                tilawahProgress = tilawahProgress,
                                showSunnahRing = isSultanMode || isStandarMode,
                                modifier = Modifier.fillMaxSize().testTag("ritual_rings_canvas")
                            )
                            // Center text — persentase (bukan 5/5, biar gak tabrakan sama label kanan)
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                val pct = if (wajibDenominator > 0) {
                                    (checkedTrackedWajibToday * 100 / wajibDenominator)
                                } else 0
                                Text(
                                    text = "$pct%",
                                    fontSize = 24.sp,
                                    fontWeight = FontWeight.Black,
                                    color = IslamicGreen
                                )
                                Text(
                                    text = "WAJIB",
                                    fontSize = 8.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = TextMuted,
                                    letterSpacing = 1.sp
                                )
                            }
                        }

                        // Right side: compact ring labels (timer moved to CountdownCard)
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(start = 24.dp)
                        ) {
                            Text(
                                text = "RITUAL PROGRESS",
                                fontSize = 10.sp,
                                color = TextMuted,
                                fontWeight = FontWeight.ExtraBold,
                                letterSpacing = 1.2.sp
                            )
                            Spacer(modifier = Modifier.height(10.dp))
                            RingLabelRow(color = RingRed, name = "Wajib", value = "$checkedTrackedWajibToday/$wajibDenominator")
                            if (isSultanMode || isStandarMode) {
                                Spacer(modifier = Modifier.height(6.dp))
                                RingLabelRow(color = RingGreen, name = "Sunnah", value = "$sunnahCount/8")
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            RingLabelRow(color = RingBlue, name = "Tilawah", value = if (tilawahLogged) "Lengkap" else "Belum")
                        }
                    }
                }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Hero Streak Card
            HeroStreakCard(state = state, isSantaiMode = isSantaiMode)

            Spacer(modifier = Modifier.height(20.dp))

            // ═══ JADWAL SHOLAT ═══
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                SectionPill(text = "🕐 QUEST SHOLAT HARI INI", gradient = GradientGreenGold)
                val modeLabel = when (state.user.intensityMode) {
                    "santai" -> "🎮 SANTAI"
                    "sultan" -> "👑 SULTAN"
                    else -> "⚔ STANDAR"
                }
                Box(
                    modifier = Modifier
                        .background(IslamicGreen.copy(alpha = 0.1f), RoundedCornerShape(100.dp))
                        .border(1.dp, IslamicGreen.copy(alpha = 0.3f), RoundedCornerShape(100.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = modeLabel,
                        fontSize = 9.sp,
                        color = IslamicGreen,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // 5 prayers list
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val timings = state.prayerTimesCache.timings
                val prayers = listOf(
                    Pair("Subuh", timings.subuh),
                    Pair("Dzuhur", timings.dzuhur),
                    Pair("Ashar", timings.ashar),
                    Pair("Maghrib", timings.maghrib),
                    Pair("Isya", timings.isya)
                )

                prayers.forEach { (name, time) ->
                    val lowerName = name.lowercase()
                    val isChecked = state.prayerLog.any { it.date == todayStr && it.prayer == lowerName }
                    val isActive = isCurrentOrUpcoming(lowerName, timings)
                    val isTrackedInSantai = if (isSantaiMode) {
                        state.user.santaiTrackedPrayers.contains(lowerName)
                    } else true

                    PrayerRowCard(
                        name = name,
                        time = time,
                        isChecked = isChecked,
                        isActive = isActive,
                        isTrackedInSantai = isTrackedInSantai,
                        isSantaiMode = isSantaiMode,
                        onCheckedChange = { check ->
                            if (check) {
                                viewModel.logPrayer(lowerName, "wajib")
                            } else {
                                showUnlogConfirm = lowerName
                            }
                        }
                    )
                }
            }

            if (isSultanMode || isStandarMode) {
                Spacer(modifier = Modifier.height(24.dp))

                // Sunnah section header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SectionPill(
                        text = if (isSultanMode) "🌙 BONUS QUEST — SUNNAH SULTAN" else "🌙 BONUS QUEST — SUNNAH",
                        gradient = GradientCyanGreen
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp),
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

                        SunnahRowCard(
                            id = id,
                            name = name,
                            desc = desc,
                            isChecked = isChecked,
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
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Side Quest Divider
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(modifier = Modifier.weight(1f).height(1.dp).background(Brush.horizontalGradient(listOf(Color.Transparent, RingBlue.copy(alpha = 0.6f), Color.Transparent))))
                SectionPill(text = "📜 SIDE QUEST", gradient = GradientBlueCyan, compact = true)
                Box(modifier = Modifier.weight(1f).height(1.dp).background(Brush.horizontalGradient(listOf(Color.Transparent, RingBlue.copy(alpha = 0.6f), Color.Transparent))))
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                val tilawahDone = state.prayerLog.any { it.date == todayStr && it.prayer == "tilawah" }
                SunnahActionCard(
                    title = "Tilawah & Dzikir",
                    description = "Baca Al-Qur'an / Dzikir Pagi & Petang",
                    icon = "📖",
                    isClaimed = tilawahDone,
                    accentColor = RingBlue,
                    onLog = { viewModel.logPrayer("tilawah", "tilawah") }
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ═══ QUEST HARIAN (dipindah dari Quest tab) ═══
            SectionPill(text = "⚔️ QUEST HARIAN", gradient = GradientGreenGold)

            Spacer(modifier = Modifier.height(10.dp))

            // Dzikir Clicker Widget
            val zikirQuestActive = state.quests.list.any { it.id == "quest_zikir_after_prayer" }
            if (zikirQuestActive) {
                InteractiveZikirWidget(state, viewModel)
                Spacer(modifier = Modifier.height(10.dp))
            }

            // Doa Quick Checker Widget
            val doaQuestActive = state.quests.list.any { it.id == "quest_doa_solat" }
            if (doaQuestActive) {
                val doaQuest = state.quests.list.find { it.id == "quest_doa_solat" }
                if (doaQuest != null && !doaQuest.completed) {
                    InteractiveDoaWidget(viewModel)
                    Spacer(modifier = Modifier.height(10.dp))
                }
            }

            // Quest Cards
            if (state.quests.list.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(DarkSurface, RoundedCornerShape(16.dp))
                        .border(BorderStroke(1.dp, TextLight.copy(alpha = 0.08f)), RoundedCornerShape(16.dp))
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Belum ada quest nih. Masukin kota asal di Profil dulu ya!",
                        color = TextMuted,
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center
                    )
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    state.quests.list.forEach { quest ->
                        QuestRowCard(
                            quest = quest,
                            onClaim = { viewModel.claimQuest(quest.id) }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ═══ STATS GRID 2x2 ═══
            SectionPill(text = "📊 STATS ARENA", gradient = GradientGreenGold)

            Spacer(modifier = Modifier.height(10.dp))

            StatsGrid2x2(state = state, viewModel = viewModel)

            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    // Unlog Confirm Modal
    if (showUnlogConfirm != null) {
        val prayerName = showUnlogConfirm!!
        AlertDialog(
            onDismissRequest = { showUnlogConfirm = null },
            title = { Text("⚠️ Batalin Sholat?", color = TextLight, fontWeight = FontWeight.Bold) },
            text = { Text("Yakin mau batalin catatan Sholat ${prayerName.capitalizeCompat()} hari ini? XP dan streak bakal dikurangi ya!", color = TextMuted) },
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
            shape = RoundedCornerShape(20.dp),
            
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// BINTANG SEAL — Signature 8-point Islamic star medal
// ═══════════════════════════════════════════════════════════════

/**
 * Hero Bintang Seal: 8-point Islamic star medal with rotating glow ring,
 * center level circle, LEVEL label, rank name. Replaces GameHeaderView.
 */
@Composable
fun BintangSealHero(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)
    // Short rank name (e.g. "MUSAFIR", "WARRIOR") — first word, uppercased
    val rankShort = rankTitle.split(" ").take(2).joinToString(" ").uppercase()

    val modeLabel = when (state.user.intensityMode) {
        "santai" -> "🎮 SANTAI"
        "sultan" -> "👑 SULTAN"
        else -> "⚔ STANDAR"
    }

    // Rotating glow ring animation
    val infiniteTransition = rememberInfiniteTransition(label = "seal_glow")
    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ring_rotation"
    )
    // Pulse for inner glow
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.06f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "seal_pulse"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp)
            .shadow(
                elevation = 24.dp,
                shape = RoundedCornerShape(28.dp),
                ambientColor = IslamicGreen.copy(alpha = 0.32f),
                spotColor = GoldAccent.copy(alpha = 0.22f)
            ),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = BorderStroke(
            1.5.dp,
            Brush.linearGradient(GradientGreenGold)
        )
    ) {
        Box(
            modifier = Modifier
                .background(Brush.verticalGradient(GradientDarkSurface))
                .fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // ── Top row: username + mode ──
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = state.user.username.uppercase(),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Black,
                        color = TextLight,
                        letterSpacing = 1.5.sp
                    )
                    Box(
                        modifier = Modifier
                            .background(IslamicGreen.copy(alpha = 0.12f), RoundedCornerShape(100.dp))
                            .border(1.dp, IslamicGreen.copy(alpha = 0.35f), RoundedCornerShape(100.dp))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = modeLabel,
                            fontSize = 9.sp,
                            color = IslamicGreen,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                // ── Bintang Seal Canvas ──
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(180.dp)
                ) {
                    // Rotating conic-style glow ring (drawn behind)
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .rotate(ringRotation)
                    ) {
                        drawRotatingGlowRing(
                            center = center,
                            radius = size.minDimension / 2f * 0.92f,
                            teal = IslamicGreen,
                            gold = GoldAccent
                        )
                    }

                    // Pulse-scaled 8-point star
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .scale(pulseScale)
                    ) {
                        drawBintangSeal(
                            center = center,
                            outerRadius = size.minDimension / 2f * 0.78f,
                            innerRadius = size.minDimension / 2f * 0.42f,
                            teal = IslamicGreen,
                            gold = GoldAccent,
                            surface = DarkSurface
                        )
                    }

                    // Center text overlay (LEVEL / number / rank)
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier
                            .background(DarkSurface.copy(alpha = 0.9f), CircleShape)
                            .size(86.dp),
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = "LEVEL",
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Black,
                            color = GoldAccent,
                            letterSpacing = 2.sp
                        )
                        Text(
                            text = "${levelInfo.level}",
                            fontSize = 34.sp,
                            fontWeight = FontWeight.Black,
                            color = TextLight,
                            letterSpacing = (-1).sp
                        )
                    }

                    // Rank name below the seal center
                    Text(
                        text = rankShort,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = IslamicGreen,
                        letterSpacing = 2.sp,
                        modifier = Modifier
                            .padding(top = 116.dp)
                            .background(DarkSurface.copy(alpha = 0.85f), RoundedCornerShape(100.dp))
                            .border(1.dp, IslamicGreen.copy(alpha = 0.4f), RoundedCornerShape(100.dp))
                            .padding(horizontal = 10.dp, vertical = 3.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // ── XP bar ──
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "LV ${levelInfo.level}",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = TextMuted
                    )
                    Text(
                        text = "XP ${levelInfo.xpInCurrentLevel}/${levelInfo.xpNeededForNextLevel}",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = IslamicGreen
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                NeonProgressBar(
                    progress = levelInfo.progress,
                    modifier = Modifier.fillMaxWidth(),
                    height = 10.dp,
                    brush = Brush.horizontalGradient(listOf(IslamicGreen, GoldAccent, IslamicGreen)),
                    glowColor = IslamicGreen
                )
            }
        }
    }
}

/**
 * Draws the 8-point Islamic star as two overlapping rotated squares,
 * with a teal-to-gold gradient stroke.
 */
fun DrawScope.drawBintangSeal(
    center: Offset,
    outerRadius: Float,
    innerRadius: Float,
    teal: Color,
    gold: Color,
    surface: Color
) {
    val starStrokeWidth = 3.dp.toPx()

    // Filled center disc (subtle)
    drawCircle(
        color = surface.copy(alpha = 0.6f),
        radius = innerRadius,
        center = center
    )

    // Two overlapping rotated squares forming 8-point star
    val half = outerRadius
    val starGradient = Brush.linearGradient(
        colors = listOf(teal, gold, teal),
        start = Offset(center.x - half, center.y - half),
        end = Offset(center.x + half, center.y + half)
    )

    // Square 1 (axis-aligned)
    drawRect(
        brush = starGradient,
        topLeft = Offset(center.x - half, center.y - half),
        size = Size(half * 2, half * 2),
        style = Stroke(width = starStrokeWidth)
    )
    // Square 2 (rotated 45°)
    rotate(degrees = 45f, pivot = center) {
        drawRect(
            brush = starGradient,
            topLeft = Offset(center.x - half, center.y - half),
            size = Size(half * 2, half * 2),
            style = Stroke(width = starStrokeWidth)
        )
    }

    // Inner ring stroke (gold) around the center disc
    drawCircle(
        brush = Brush.linearGradient(
            colors = listOf(gold, teal, gold),
            start = Offset(center.x - innerRadius, center.y),
            end = Offset(center.x + innerRadius, center.y)
        ),
        radius = innerRadius,
        center = center,
        style = Stroke(width = 2.dp.toPx())
    )

    // Subtle outer glow ring
    drawCircle(
        color = teal.copy(alpha = 0.15f),
        radius = outerRadius + 6.dp.toPx(),
        center = center,
        style = Stroke(width = 8.dp.toPx())
    )
}

/**
 * Draws a rotating conic-gradient style glow ring using segmented arcs.
 * Approximates conic gradient with 8 alternating teal/gold segments.
 */
fun DrawScope.drawRotatingGlowRing(
    center: Offset,
    radius: Float,
    teal: Color,
    gold: Color
) {
    val segments = 8
    val sweep = 360f / segments
    val strokeWidth = 4.dp.toPx()
    val arcSize = Size(radius * 2, radius * 2)
    val topLeft = Offset(center.x - radius, center.y - radius)

    for (i in 0 until segments) {
        val color = if (i % 2 == 0) teal.copy(alpha = 0.55f) else gold.copy(alpha = 0.55f)
        drawArc(
            color = color,
            startAngle = i * sweep,
            sweepAngle = sweep,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )
    }
    // Outer faint halo
    drawCircle(
        color = teal.copy(alpha = 0.08f),
        radius = radius + 8.dp.toPx(),
        center = center,
        style = Stroke(width = 14.dp.toPx())
    )
}

// ═══════════════════════════════════════════════════════════════
// COUNTDOWN CARD — ML-style match timer for next prayer
// ═══════════════════════════════════════════════════════════════

@Composable
fun CountdownCard(
    state: MuslimLevelingData,
    checkedTrackedWajibToday: Int,
    wajibDenominator: Int
) {
    val timer = getNextPrayerTimerInfo(
        state.prayerTimesCache.timings,
        checkedTrackedWajibToday,
        wajibDenominator
    )

    // Tick animation pulse
    val infiniteTransition = rememberInfiniteTransition(label = "countdown_pulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.4f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 900, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "countdown_pulse_alpha"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(
                elevation = 14.dp,
                shape = RoundedCornerShape(20.dp),
                ambientColor = IslamicGreen.copy(alpha = 0.28f),
                spotColor = IslamicGreen.copy(alpha = 0.15f)
            ),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = BorderStroke(
            1.5.dp,
            Brush.linearGradient(listOf(IslamicGreen.copy(alpha = 0.5f), IslamicGreen.copy(alpha = 0.15f), IslamicGreen.copy(alpha = 0.5f)))
        )
    ) {
        Box(
            modifier = Modifier
                .background(Brush.verticalGradient(listOf(DarkSurfaceElevated, DarkSurface)))
                .fillMaxWidth()
                .drawBehind {
                    // Subtle arena spotlight from left (tosca)
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(IslamicGreen.copy(alpha = 0.06f), Color.Transparent),
                            center = Offset(size.width * 0.1f, size.height * 0.5f),
                            radius = size.height * 1.8f
                        ),
                        radius = size.height * 1.8f,
                        center = Offset(size.width * 0.1f, size.height * 0.5f)
                    )
                }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Left: label
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .background(RingRed.copy(alpha = pulseAlpha), CircleShape)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "NEXT MATCH",
                            fontSize = 9.sp,
                            color = TextMuted,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 1.5.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = timer.label,
                        fontSize = 14.sp,
                        color = TextLight,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = timer.tagline,
                        fontSize = 10.sp,
                        color = IslamicGreen.copy(alpha = 0.85f),
                        lineHeight = 13.sp,
                        maxLines = 2,
                        style = androidx.compose.ui.text.TextStyle(
                            fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                        )
                    )
                }

                // Right: timer (big, tosca, monospace)
                Text(
                    text = timer.duration,
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Black,
                    color = IslamicGreen,
                    letterSpacing = (-1).sp,
                    fontFamily = FontFamily.Monospace,
                    textAlign = TextAlign.End
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// SECTION PILL — gradient bg, black text (replaces plain titles)
// ═══════════════════════════════════════════════════════════════

@Composable
fun SectionPill(
    text: String,
    gradient: List<Color>,
    compact: Boolean = false
) {
    val glowColor = gradient.first()
    Box(
        modifier = Modifier
            .shadow(
                if (compact) 5.dp else 6.dp,
                RoundedCornerShape(100.dp),
                ambientColor = glowColor.copy(alpha = 0.4f)
            )
            .background(Brush.horizontalGradient(gradient), RoundedCornerShape(100.dp))
            .padding(horizontal = if (compact) 10.dp else 12.dp, vertical = if (compact) 3.dp else 4.dp)
    ) {
        Text(
            text = text,
            fontSize = if (compact) 10.sp else 11.sp,
            fontWeight = FontWeight.Black,
            color = Color.Black,
            letterSpacing = if (compact) 2.sp else 1.5.sp
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// STATS GRID 2x2 — accent left bars (teal, gold, crimson, violet)
// ═══════════════════════════════════════════════════════════════

@Composable
fun StatsGrid2x2(state: MuslimLevelingData, viewModel: GameViewModel) {
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val todayStr = LocalDate.now().toString()
    val todayWajib = listOf("subuh", "dzuhur", "ashar", "maghrib", "isya").count { p ->
        state.prayerLog.any { it.date == todayStr && it.prayer == p }
    }
    val todaySunnah = state.prayerLog.count {
        it.date == todayStr && (it.type == "sunnah" || it.prayer == "dhuha" || it.prayer.startsWith("rawatib"))
    }
    val totalXp = state.user.xp
    val bestStreak = state.heroStreak.best

    val stats = listOf(
        StatItem("LEVEL", "${levelInfo.level}", IslamicGreen),
        StatItem("XP TOTAL", "$totalXp", GoldAccent),
        StatItem("STREAK", "${state.heroStreak.current}🔥", RingRed),
        StatItem("BEST", "${bestStreak}🏆", PurpleNeon)
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        stats.chunked(2).forEach { rowStats ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                rowStats.forEach { stat ->
                    StatCard(stat = stat, modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

data class StatItem(val label: String, val value: String, val accent: Color)

@Composable
fun StatCard(stat: StatItem, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier
            .height(72.dp)
            .shadow(
                elevation = 6.dp,
                shape = RoundedCornerShape(14.dp),
                ambientColor = stat.accent.copy(alpha = 0.2f)
            ),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = BorderStroke(1.dp, DarkSurfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .background(Brush.verticalGradient(GradientDarkSurface))
        ) {
            // Left accent bar
            Box(
                modifier = Modifier
                    .width(5.dp)
                    .fillMaxHeight()
                    .background(stat.accent)
            )
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(start = 12.dp, top = 10.dp, bottom = 10.dp, end = 8.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = stat.label,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Black,
                    color = TextMuted,
                    letterSpacing = 1.2.sp
                )
                Text(
                    text = stat.value,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Black,
                    color = stat.accent,
                    letterSpacing = (-0.5).sp
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// RING LABEL ROW — compact label + value with neon dot
// ═══════════════════════════════════════════════════════════════

@Composable
fun RingLabelRow(color: Color, name: String, value: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .shadow(3.dp, CircleShape, ambientColor = color.copy(alpha = 0.5f))
                .background(color, CircleShape)
        )
        Text(
            text = name,
            fontSize = 11.sp,
            color = TextMuted,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            fontSize = 12.sp,
            color = color,
            fontWeight = FontWeight.ExtraBold
        )
    }
}

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

@Composable
fun GameHeaderView(state: MuslimLevelingData, viewModel: GameViewModel) {
    // Preserved for backward compat — delegates to BintangSealHero
    BintangSealHero(state, viewModel)
}

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
        val strokeWidth = 10.dp.toPx()

        // Outer Ring: Wajib (Red Neon)
        val outerRadius = (size.minDimension / 2) - 8.dp.toPx()

        // Glow effect
        drawCircle(
            color = RingRed.copy(alpha = 0.15f),
            radius = outerRadius + 4.dp.toPx(),
            center = center,
            style = Stroke(width = strokeWidth + 8.dp.toPx())
        )
        // Track
        drawCircle(
            color = RingRed.copy(alpha = 0.1f),
            radius = outerRadius,
            center = center,
            style = Stroke(width = strokeWidth)
        )
        // Progress with glow
        if (wajibProgress > 0f) {
            drawArc(
                color = RingRed,
                startAngle = -90f,
                sweepAngle = wajibProgress * 360f,
                useCenter = false,
                topLeft = Offset(center.x - outerRadius, center.y - outerRadius),
                size = Size(outerRadius * 2, outerRadius * 2),
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        val middleRadius = if (showSunnahRing) {
            val r = (size.minDimension / 2) - 22.dp.toPx()
            // Glow
            drawCircle(
                color = RingGreen.copy(alpha = 0.12f),
                radius = r + 4.dp.toPx(),
                center = center,
                style = Stroke(width = strokeWidth + 6.dp.toPx())
            )
            drawCircle(
                color = RingGreen.copy(alpha = 0.1f),
                radius = r,
                center = center,
                style = Stroke(width = strokeWidth)
            )
            if (sunnahProgress > 0f) {
                drawArc(
                    color = RingGreen,
                    startAngle = -90f,
                    sweepAngle = sunnahProgress * 360f,
                    useCenter = false,
                    topLeft = Offset(center.x - r, center.y - r),
                    size = Size(r * 2, r * 2),
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }
            r
        } else {
            outerRadius
        }

        // Inner Ring: Tilawah (Blue Neon)
        val innerRadius = if (showSunnahRing) {
            (size.minDimension / 2) - 36.dp.toPx()
        } else {
            (size.minDimension / 2) - 22.dp.toPx()
        }

        drawCircle(
            color = RingBlue.copy(alpha = 0.12f),
            radius = innerRadius + 4.dp.toPx(),
            center = center,
            style = Stroke(width = strokeWidth + 6.dp.toPx())
        )
        drawCircle(
            color = RingBlue.copy(alpha = 0.1f),
            radius = innerRadius,
            center = center,
            style = Stroke(width = strokeWidth)
        )
        if (tilawahProgress > 0f) {
            drawArc(
                color = RingBlue,
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

@Composable
fun RingLabelView(color: Color, name: String, value: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        // Neon dot with glow
        Box(
            modifier = Modifier
                .size(10.dp)
                .shadow(4.dp, CircleShape, ambientColor = color.copy(alpha = 0.5f))
                .background(color, CircleShape)
        )
        Text(
            text = name,
            fontSize = 11.sp,
            color = TextMuted,
            fontWeight = FontWeight.Medium
        )
        Text(
            text = value,
            fontSize = 11.sp,
            color = color,
            fontWeight = FontWeight.ExtraBold
        )
    }
}

@Composable
fun HeroStreakCard(state: MuslimLevelingData, isSantaiMode: Boolean) {
    val hero = state.heroStreak

    if (isSantaiMode) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .testTag("hero_streak_card_locked"),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurface.copy(alpha = 0.5f)),
            border = BorderStroke(1.dp, DarkSurfaceVariant)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "🔒", fontSize = 28.sp, modifier = Modifier.padding(end = 12.dp))
                    Column {
                        Text(
                            text = "HERO STREAK [LOCKED]",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Black,
                            color = TextMuted,
                            letterSpacing = 1.sp
                        )
                        Text(
                            text = "Lengkapin 5 sholat wajib dulu buat buka ini! 🔓",
                            fontSize = 11.sp,
                            color = TextMuted,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
        }
    } else {
        // Arena Hikmah hero streak — crimson/gold esports gradient
        val heroGradient = Brush.linearGradient(
            colors = listOf(DarkSurfaceElevated, DarkSurface)
        )

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .shadow(
                    elevation = 24.dp,
                    shape = RoundedCornerShape(24.dp),
                    ambientColor = RingRed.copy(alpha = 0.35f),
                    spotColor = GoldAccent.copy(alpha = 0.2f)
                )
                .testTag("hero_streak_card_active"),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = Color.Transparent),
            border = BorderStroke(1.5.dp, Brush.linearGradient(listOf(RingRed, GoldAccent)))
        ) {
            Box(
                modifier = Modifier
                    .background(heroGradient)
                    .fillMaxWidth()
            ) {
                // Background mosque icon
                Text(
                    text = "🕋",
                    fontSize = 120.sp,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = 15.dp, y = (-25).dp),
                    color = Color.White.copy(alpha = 0.06f)
                )

                Column(
                    modifier = Modifier.padding(20.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(bottom = 12.dp)
                    ) {
                        Text(text = "🔥", fontSize = 24.sp)
                        Text(
                            text = "SHOLAT 5/5 STREAK",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Black,
                            color = TextLight,
                            letterSpacing = 1.sp
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.Bottom,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "${hero.current} HARI",
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Black,
                                color = GoldAccent,
                                letterSpacing = (-1).sp
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "🏆 REKOR: ${hero.best} HARI",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = IslamicGreen.copy(alpha = 0.9f),
                                letterSpacing = 0.7.sp
                            )
                        }

                        val freezeText = if (hero.freezeAvailable) "❄ FREEZE READY" else "COOLDOWN"
                        val freezeBgColor = if (hero.freezeAvailable) RingRed.copy(alpha = 0.15f) else Color.White.copy(alpha = 0.1f)

                        Box(
                            modifier = Modifier
                                .background(freezeBgColor, RoundedCornerShape(100.dp))
                                .border(BorderStroke(1.dp, if (hero.freezeAvailable) RingRed.copy(alpha = 0.5f) else Color.Transparent), RoundedCornerShape(100.dp))
                                .padding(horizontal = 12.dp, vertical = 6.dp)
                        ) {
                            Text(
                                text = freezeText,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = if (hero.freezeAvailable) RingRed else TextMuted
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Per-prayer streaks
                    Box(
                        modifier = Modifier
                            .background(Color.Black.copy(alpha = 0.25f), RoundedCornerShape(16.dp))
                            .border(BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.15f)), RoundedCornerShape(16.dp))
                            .padding(14.dp)
                    ) {
                        Column {
                            Text(
                                text = "⚔ STREAK PER-SHOLAT:",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = GoldAccent,
                                letterSpacing = 1.5.sp,
                                modifier = Modifier.padding(bottom = 10.dp)
                            )

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                listOf("subuh", "dzuhur", "ashar", "maghrib", "isya").forEach { prayer ->
                                    val streakObj = state.perPrayerStreaks[prayer] ?: StreakState()
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Text(
                                            text = prayer.substring(0, 1).uppercase() + prayer.substring(1, 3),
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = TextLight.copy(alpha = 0.7f)
                                        )
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.Center,
                                            modifier = Modifier.padding(top = 2.dp)
                                        ) {
                                            Text(text = "🔥", fontSize = 10.sp)
                                            Spacer(modifier = Modifier.width(2.dp))
                                            Text(
                                                text = "${streakObj.current}",
                                                fontSize = 13.sp,
                                                fontWeight = FontWeight.ExtraBold,
                                                color = if (streakObj.current > 0) IslamicGreen else TextMuted
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PrayerRowCard(
    name: String,
    time: String,
    isChecked: Boolean,
    isActive: Boolean,
    isTrackedInSantai: Boolean,
    isSantaiMode: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    // Arena Hikmah states:
    //  - Done    = teal border + glow
    //  - Active  = gold border + pulse
    //  - Locked  = muted
    val infiniteTransition = rememberInfiniteTransition(label = "prayer_active_pulse")
    val activePulse by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1100, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "active_pulse_alpha"
    )

    val borderStroke = when {
        isChecked -> BorderStroke(1.5.dp, Brush.linearGradient(listOf(IslamicGreen, CyanAccent)))
        isActive -> BorderStroke(1.5.dp, Brush.linearGradient(GradientGoldAmber))
        else -> BorderStroke(1.dp, DarkSurfaceVariant)
    }

    val containerColor = when {
        isChecked -> Brush.verticalGradient(listOf(IslamicGreen.copy(alpha = 0.12f), DarkSurface))
        isActive -> Brush.verticalGradient(listOf(GoldAccent.copy(alpha = 0.08f), DarkSurface))
        else -> Brush.verticalGradient(GradientDarkSurface)
    }

    val timeColor = when {
        isChecked -> IslamicGreen.copy(alpha = 0.7f)
        isActive -> GoldAccent
        else -> TextMuted
    }

    val prayerEmoji = when (name.lowercase()) {
        "subuh" -> "🌙"
        "dzuhur" -> "☀️"
        "ashar" -> "🌤"
        "maghrib" -> "🌇"
        "isya" -> "🌃"
        else -> "🕌"
    }

    val accentBarColor = when {
        isChecked -> IslamicGreen
        isActive -> GoldAccent
        else -> DarkSurfaceVariant
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .then(
                if (isChecked) Modifier.shadow(
                    elevation = 8.dp,
                    shape = RoundedCornerShape(18.dp),
                    ambientColor = IslamicGreen.copy(alpha = 0.3f),
                    spotColor = IslamicGreen.copy(alpha = 0.15f)
                ) else if (isActive) Modifier.shadow(
                    elevation = 10.dp,
                    shape = RoundedCornerShape(18.dp),
                    ambientColor = GoldAccent.copy(alpha = 0.25f * activePulse),
                    spotColor = GoldAccent.copy(alpha = 0.15f * activePulse)
                ) else Modifier.shadow(
                    elevation = 4.dp,
                    shape = RoundedCornerShape(18.dp),
                    ambientColor = Color.Black.copy(alpha = 0.2f),
                    spotColor = Color.Black.copy(alpha = 0.1f)
                )
            )
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(18.dp))
            .testTag("prayer_card_${name.lowercase()}"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
                .drawBehind {
                    if (isActive) {
                        drawCircle(
                            Brush.radialGradient(
                                listOf(GoldAccent.copy(alpha = 0.08f * activePulse), Color.Transparent),
                                center = Offset(size.width * 0.1f, size.height * 0.5f),
                                radius = size.height * 2f
                            )
                        )
                    }
                },
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left accent bar
            Box(
                modifier = Modifier
                    .width(5.dp)
                    .fillMaxHeight()
                    .background(accentBarColor)
            )

            Row(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 14.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Prayer emoji icon
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(
                            if (isChecked) IslamicGreen.copy(alpha = 0.15f)
                            else if (isActive) GoldAccent.copy(alpha = 0.1f)
                            else DarkBackground.copy(alpha = 0.5f),
                            RoundedCornerShape(12.dp)
                        )
                        .border(
                            BorderStroke(
                                1.dp,
                                if (isChecked) IslamicGreen.copy(alpha = 0.3f)
                                else if (isActive) GoldAccent.copy(alpha = 0.25f)
                                else DarkSurfaceVariant
                            ),
                            RoundedCornerShape(12.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = prayerEmoji,
                        fontSize = 20.sp
                    )
                }

                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = name,
                            fontSize = 15.sp,
                            fontWeight = if (isActive || isChecked) FontWeight.ExtraBold else FontWeight.SemiBold,
                            color = if (isChecked) IslamicGreen else if (isActive) GoldAccent else TextLight
                        )
                        if (isSantaiMode && !isTrackedInSantai) {
                            Text(
                                text = " (bonus)",
                                fontSize = 10.sp,
                                color = TextMuted
                            )
                        }
                    }
                    Text(
                        text = "Jam $time WIB",
                        fontSize = 11.sp,
                        color = TextMuted,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }

            // Right side: time + XP pill + check circle
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(end = 14.dp)
            ) {
                // XP pill
                Box(
                    modifier = Modifier
                        .background(
                            if (isChecked) IslamicGreen.copy(alpha = 0.15f)
                            else GoldAccent.copy(alpha = 0.1f),
                            RoundedCornerShape(100.dp)
                        )
                        .border(
                            1.dp,
                            if (isChecked) IslamicGreen.copy(alpha = 0.3f)
                            else GoldAccent.copy(alpha = 0.25f),
                            RoundedCornerShape(100.dp)
                        )
                        .padding(horizontal = 8.dp, vertical = 3.dp)
                ) {
                    Text(
                        text = if (isChecked) "+XP ✓" else "+XP",
                        fontSize = 9.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = if (isChecked) IslamicGreen else GoldAccent
                    )
                }

                // Gaming check circle
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .then(
                            if (isChecked) Modifier.shadow(
                                6.dp,
                                RoundedCornerShape(10.dp),
                                ambientColor = IslamicGreen.copy(alpha = 0.6f)
                            )
                            else if (isActive) Modifier.shadow(
                                4.dp,
                                RoundedCornerShape(10.dp),
                                ambientColor = GoldAccent.copy(alpha = 0.4f * activePulse)
                            )
                            else Modifier
                        )
                        .background(if (isChecked) IslamicGreen else Color.Transparent)
                        .border(
                            BorderStroke(
                                width = if (isChecked) 0.dp else 2.dp,
                                color = if (isActive) GoldAccent else DarkSurfaceVariant
                            ),
                            RoundedCornerShape(10.dp)
                        )
                        .clickable { onCheckedChange(!isChecked) },
                    contentAlignment = Alignment.Center
                ) {
                    if (isChecked) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = Color.Black,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SunnahActionCard(
    title: String,
    description: String,
    icon: String,
    isClaimed: Boolean,
    accentColor: Color,
    buttonLabel: String = "Catat ✅",
    onLog: () -> Unit
) {
    val cardBg = Brush.verticalGradient(listOf(accentColor.copy(alpha = 0.08f), DarkSurface))
    val cardBorder = Brush.linearGradient(listOf(accentColor.copy(alpha = 0.6f), accentColor.copy(alpha = 0.2f), accentColor.copy(alpha = 0.6f)))

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .then(
                if (!isClaimed) Modifier.shadow(8.dp, RoundedCornerShape(16.dp), ambientColor = accentColor.copy(alpha = 0.25f))
                else Modifier
            )
            .background(cardBg)
            .border(BorderStroke(1.5.dp, cardBorder), RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Left accent bar
            Box(
                modifier = Modifier
                    .width(5.dp)
                    .fillMaxHeight()
                    .background(accentColor)
            )

            Row(
                modifier = Modifier
                    .weight(1f)
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(42.dp)
                        .background(accentColor.copy(alpha = 0.12f), RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = icon, fontSize = 20.sp)
                }

                Column {
                    Text(
                        text = title,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = accentColor
                    )
                    Text(
                        text = description,
                        fontSize = 11.sp,
                        color = TextMuted,
                        lineHeight = 15.sp
                    )
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            if (isClaimed) {
                Box(
                    modifier = Modifier
                        .padding(end = 14.dp)
                        .background(accentColor.copy(alpha = 0.15f), RoundedCornerShape(100.dp))
                        .border(1.dp, accentColor.copy(alpha = 0.3f), RoundedCornerShape(100.dp))
                        .padding(horizontal = 14.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = "✓ Selesai",
                        color = accentColor,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.ExtraBold
                    )
                }
            } else {
                Button(
                    onClick = onLog,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = accentColor,
                        contentColor = Color.Black
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 4.dp),
                    modifier = Modifier
                        .padding(end = 14.dp)
                        .height(32.dp)
                        .shadow(4.dp, RoundedCornerShape(10.dp), ambientColor = accentColor.copy(alpha = 0.3f))
                ) {
                    Text(
                        text = if (buttonLabel == "Catat ✅") "+ Claim" else buttonLabel,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.Black
                    )
                }
            }
        }
    }
}

// Helpers
fun getNextPrayerCountdown(timings: Timings, currentWajib: Int, denominator: Int): String {
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
                val timeNeeded = if (diffMins >= 60) {
                    val hrs = diffMins / 60
                    val mins = diffMins % 60
                    "$hrs jam $mins menit"
                } else {
                    "$diffMins menit"
                }
                return "${p.first} dalam $timeNeeded — lengkapi = ring Wajib jadi $currentWajib/$denominator!"
            }
        } catch (e: Exception) {
            // ignore
        }
    }
    return "Sholat fardhu hari ini udah lengkap! Subuh besok jam ${timings.subuh} ✨"
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

fun tryParsing(timeStr: String, default: LocalTime): LocalTime {
    return try {
        LocalTime.parse(timeStr)
    } catch (e: Exception) {
        default
    }
}

@Composable
fun SunnahRowCard(
    id: String,
    name: String,
    desc: String,
    isChecked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    val borderStroke = when {
        isChecked -> BorderStroke(1.5.dp, Brush.linearGradient(GradientCyanGreen))
        else -> BorderStroke(1.dp, DarkSurfaceVariant)
    }

    val containerColor = when {
        isChecked -> Brush.verticalGradient(listOf(RingGreen.copy(alpha = 0.12f), DarkSurface))
        else -> Brush.verticalGradient(GradientDarkSurface)
    }

    val accentBarColor = if (isChecked) RingGreen else DarkSurfaceVariant

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .shadow(
                elevation = if (isChecked) 6.dp else 3.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = if (isChecked) RingGreen.copy(alpha = 0.2f) else Color.Black.copy(alpha = 0.15f),
                spotColor = if (isChecked) RingGreen.copy(alpha = 0.1f) else Color.Black.copy(alpha = 0.08f)
            )
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(16.dp))
            .testTag("sunnah_card_${id}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Left accent bar
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .fillMaxHeight()
                    .background(accentBarColor)
            )

            Row(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Icon box
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(
                            if (isChecked) RingGreen.copy(alpha = 0.15f) else DarkBackground.copy(alpha = 0.5f),
                            RoundedCornerShape(10.dp)
                        )
                        .border(
                            BorderStroke(
                                1.dp,
                                if (isChecked) RingGreen.copy(alpha = 0.3f) else DarkSurfaceVariant
                            ),
                            RoundedCornerShape(10.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "✨",
                        fontSize = 16.sp
                    )
                }

                Column {
                    Text(
                        text = name,
                        fontSize = 14.sp,
                        fontWeight = if (isChecked) FontWeight.ExtraBold else FontWeight.Bold,
                        color = if (isChecked) RingGreen else TextLight
                    )
                    Text(
                        text = desc,
                        fontSize = 11.sp,
                        color = TextMuted,
                        lineHeight = 15.sp
                    )
                }
            }

            // Gaming checkbox
            Box(
                modifier = Modifier
                    .padding(end = 14.dp)
                    .size(28.dp)
                    .clip(RoundedCornerShape(9.dp))
                    .then(
                        if (isChecked) Modifier.shadow(
                            5.dp,
                            RoundedCornerShape(9.dp),
                            ambientColor = RingGreen.copy(alpha = 0.5f)
                        ) else Modifier
                    )
                    .background(if (isChecked) RingGreen else Color.Transparent)
                    .border(
                        BorderStroke(
                            width = if (isChecked) 0.dp else 2.dp,
                            color = DarkSurfaceVariant
                        ),
                        RoundedCornerShape(9.dp)
                    )
                    .clickable { onCheckedChange(!isChecked) },
                contentAlignment = Alignment.Center
            ) {
                if (isChecked) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color.Black,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}
