package com.example.ui.screens

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.MuslimLevelingData
import com.example.data.Quest
import com.example.ui.components.NeonProgressBar
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel

// ═══════════════════════════════════════════════════════════════
// ARENA HIKMAH — QUEST SCREEN
// Battle quests with esports-card styling: status glow, gold XP pills,
// mono stat readouts, shimmer progress, and a tap-to-increment zikir wheel.
// ═══════════════════════════════════════════════════════════════

// Subtle card border equivalent (rgba(232,237,245,0.08))
private val ArenaBorder = TextLight.copy(alpha = 0.08f)

@Composable
fun QuestScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
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
                .padding(horizontal = 20.dp)
                .padding(top = 28.dp, bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Section title pill: gold-to-teal gradient, black text, 10sp bold, letter-spacing 2sp
            ArenaSectionTitlePill(text = "BATTLE QUESTS", gradient = GradientGreenGold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Misi Harian 📋",
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                color = TextLight,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Selesaikan misi-misi di bawah buat ngumpulin XP hari ini!",
                fontSize = 12.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp, bottom = 22.dp)
            )

            // Dzikir Clicker Companion Widget
            val zikirQuestActive = state.quests.list.any { it.id == "quest_zikir_after_prayer" }
            if (zikirQuestActive) {
                InteractiveZikirWidget(state, viewModel)
                Spacer(modifier = Modifier.height(14.dp))
            }

            // Doa Quick Checker Widget
            val doaQuestActive = state.quests.list.any { it.id == "quest_doa_solat" }
            if (doaQuestActive) {
                val doaQuest = state.quests.list.find { it.id == "quest_doa_solat" }
                if (doaQuest != null && !doaQuest.completed) {
                    InteractiveDoaWidget(viewModel)
                    Spacer(modifier = Modifier.height(14.dp))
                }
            }

            // Section header label with gradient line
            ArenaSectionHeaderLine(text = "TARGET HARI INI (RESET JAM 24:00)")

            // Quest Listings
            if (state.quests.list.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(DarkSurface, RoundedCornerShape(16.dp))
                        .border(BorderStroke(1.dp, ArenaBorder), RoundedCornerShape(16.dp))
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Belum ada quest nih. Masukin kota asal di Pengaturan dulu ya biar quest-nya muncul!",
                        color = TextMuted,
                        fontSize = 13.sp,
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
        }
    }
}

// ─── Section title pill (teal-to-gold horizontal gradient, black text, 10sp bold) ───
@Composable
private fun ArenaSectionTitlePill(
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

// ─── Section header label + thin gradient underline ───
@Composable
private fun ArenaSectionHeaderLine(text: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = text,
            fontSize = 10.sp,
            fontWeight = FontWeight.ExtraBold,
            color = GoldAccent,
            letterSpacing = 1.5.sp
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(
                    Brush.horizontalGradient(
                        listOf(GoldAccent.copy(alpha = 0.5f), IslamicGreen.copy(alpha = 0.2f), Color.Transparent)
                    )
                )
        )
    }
}

@Composable
fun QuestRowCard(
    quest: Quest,
    onClaim: () -> Unit
) {
    val isCompleted = quest.completed
    val isClaimed = quest.claimed
    val progressPercent = if (quest.target > 0) {
        (quest.progress.toFloat() / quest.target.toFloat()).coerceIn(0f, 1f)
    } else 0f

    // Per-status accent: active=gold, done=teal, claimed=muted
    val accentColor = when {
        isClaimed -> TextMuted
        isCompleted -> GoldAccent
        else -> IslamicGreen
    }
    val accentGlow = when {
        isClaimed -> Color.Transparent
        isCompleted -> GoldGlow
        else -> IslamicGreenGlow
    }
    val cardShape = RoundedCornerShape(16.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("quest_card_${quest.id}")
            .then(
                if (!isClaimed) Modifier.shadow(
                    elevation = 12.dp,
                    shape = cardShape,
                    ambientColor = accentColor.copy(alpha = 0.22f),
                    spotColor = accentColor.copy(alpha = 0.12f)
                ) else Modifier
            ),
        shape = cardShape,
        colors = CardDefaults.cardColors(
            containerColor = if (isClaimed) DarkSurface.copy(alpha = 0.6f) else DarkSurface
        ),
        border = BorderStroke(
            1.dp,
            if (isClaimed) Brush.linearGradient(listOf(ArenaBorder, ArenaBorder))
            else Brush.linearGradient(
                listOf(accentColor.copy(alpha = 0.55f), accentColor.copy(alpha = 0.15f), accentColor.copy(alpha = 0.55f))
            )
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left accent bar (2dp, colored per status)
            Box(
                modifier = Modifier
                    .width(2.dp)
                    .fillMaxHeight()
                    .padding(end = 0.dp)
                    .background(accentColor, RoundedCornerShape(100.dp))
            )
            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                // Title
                Text(
                    text = quest.desc,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (isClaimed) TextMuted else TextLight,
                    lineHeight = 18.sp
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Progress row: label + fraction text
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Progres".uppercase(),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Medium,
                        color = TextMuted,
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = "${quest.progress}/${quest.target}",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        fontFamily = FontFamily.Monospace,
                        color = if (isCompleted) GoldAccent else TextLight
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Shimmer progress bar
                NeonProgressBar(
                    progress = progressPercent,
                    modifier = Modifier.fillMaxWidth(),
                    height = 6.dp,
                    brush = if (isCompleted) Brush.horizontalGradient(
                        listOf(GoldAccent, AmberFlame, GoldAccent)
                    ) else Brush.horizontalGradient(
                        listOf(IslamicGreen, IslamicGreenDim, IslamicGreen)
                    ),
                    glowColor = if (isCompleted) GoldAccent else IslamicGreen,
                    trackColor = DarkSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            // Right column: XP pill + action button
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.width(76.dp)
            ) {
                // XP pill: gold bg 10% opacity, gold text, mono font
                Box(
                    modifier = Modifier
                        .background(GoldAccent.copy(alpha = 0.10f), RoundedCornerShape(8.dp))
                        .border(BorderStroke(1.dp, GoldAccent.copy(alpha = 0.25f)), RoundedCornerShape(8.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "+${quest.xpReward} XP",
                        color = GoldAccent,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold,
                        fontFamily = FontFamily.Monospace
                    )
                }

                // Action button
                when {
                    isClaimed -> {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(30.dp)
                                .background(DarkSurfaceVariant, RoundedCornerShape(10.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Diklaim ✓", fontSize = 10.sp, color = TextMuted, fontWeight = FontWeight.Medium)
                        }
                    }
                    isCompleted -> {
                        // Gold gradient claim button with glow
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(30.dp)
                                .testTag("claim_btn_${quest.id}")
                                .shadow(8.dp, RoundedCornerShape(10.dp), ambientColor = GoldAccent.copy(alpha = 0.5f))
                                .background(Brush.horizontalGradient(GradientGoldAmber), RoundedCornerShape(10.dp))
                                .clickable { onClaim() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Klaim XP", fontSize = 10.sp, fontWeight = FontWeight.Black, color = Color.Black)
                        }
                    }
                    else -> {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(30.dp)
                                .background(DarkSurfaceVariant, RoundedCornerShape(10.dp))
                                .border(BorderStroke(1.dp, ArenaBorder), RoundedCornerShape(10.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Belum Selesai", fontSize = 9.sp, color = TextMuted, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }
        }
    }
}

// ─── Zikir widget: large counter, tap to increment, circular progress ───
@Composable
fun InteractiveZikirWidget(
    state: MuslimLevelingData,
    viewModel: GameViewModel
) {
    val count = if (state.zikirCounter.date == java.time.LocalDate.now().toString()) state.zikirCounter.count else 0
    val target = 3
    val progress = (count.toFloat() / target.toFloat()).coerceIn(0f, 1f)

    val cardShape = RoundedCornerShape(18.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(14.dp, cardShape, ambientColor = IslamicGreen.copy(alpha = 0.22f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, Brush.linearGradient(listOf(IslamicGreen.copy(alpha = 0.5f), IslamicGreen.copy(alpha = 0.1f), IslamicGreen.copy(alpha = 0.5f))))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "📿 Tasbih Dzikir",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = IslamicGreen
                )
                Text(
                    text = "Tap buat nambah dzikir setelah sholat (1x per sholat)",
                    fontSize = 11.sp,
                    color = TextMuted,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Circular progress + tap-to-increment counter
            ZikirCounterWheel(
                count = count,
                target = target,
                progress = progress,
                enabled = count < target,
                onTap = { viewModel.incrementZikirQuestCounter() }
            )
        }
    }
}

@Composable
private fun ZikirCounterWheel(
    count: Int,
    target: Int,
    progress: Float,
    enabled: Boolean,
    onTap: () -> Unit
) {
    val transition = rememberInfiniteTransition(label = "zikir_pulse")
    val pulseScale by transition.animateFloat(
        initialValue = 1f,
        targetValue = if (enabled) 1.06f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "zikir_pulse_scale"
    )

    val wheelSize = 64.dp
    val ringColor = if (count >= target) GoldAccent else IslamicGreen
    val trackColor = DarkSurfaceVariant

    Box(
        modifier = Modifier
            .size(wheelSize * pulseScale)
            .shadow(12.dp, CircleShape, ambientColor = ringColor.copy(alpha = 0.45f))
            .clip(CircleShape)
            .background(DarkBackground)
            .border(BorderStroke(1.5.dp, ringColor.copy(alpha = 0.4f)), CircleShape)
            .clickable(enabled = enabled) { onTap() },
        contentAlignment = Alignment.Center
    ) {
        // Circular progress arc (drawn behind content)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    val stroke = 4.dp.toPx()
                    val diameter = size.minDimension - stroke
                    val topLeft = androidx.compose.ui.geometry.Offset(
                        (size.width - diameter) / 2f,
                        (size.height - diameter) / 2f
                    )
                    val arcSize = androidx.compose.ui.geometry.Size(diameter, diameter)
                    // Track
                    drawArc(
                        color = trackColor,
                        startAngle = -90f,
                        sweepAngle = 360f,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = stroke, cap = StrokeCap.Round)
                    )
                    // Progress
                    drawArc(
                        brush = Brush.sweepGradient(listOf(ringColor, GoldAccent, ringColor)),
                        startAngle = -90f,
                        sweepAngle = 360f * progress,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = stroke, cap = StrokeCap.Round)
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "$count/$target",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Black,
                    fontFamily = FontFamily.Monospace,
                    color = TextLight
                )
                Text(
                    text = if (count >= target) "✓" else "TAP",
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold,
                    color = ringColor,
                    letterSpacing = 1.sp
                )
            }
        }
    }
}

@Composable
fun InteractiveDoaWidget(
    viewModel: GameViewModel
) {
    val cardShape = RoundedCornerShape(18.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(14.dp, cardShape, ambientColor = GoldAccent.copy(alpha = 0.22f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, Brush.linearGradient(listOf(GoldAccent.copy(alpha = 0.5f), GoldAccent.copy(alpha = 0.1f), GoldAccent.copy(alpha = 0.5f))))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "🙏 Doa Setelah Sholat",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = GoldAccent
                )
                Text(
                    text = "Udah berdoa setelah sholat belum? Tap Selesai buat klaim quest!",
                    fontSize = 11.sp,
                    color = TextMuted,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Box(
                modifier = Modifier
                    .height(36.dp)
                    .shadow(8.dp, RoundedCornerShape(10.dp), ambientColor = GoldAccent.copy(alpha = 0.5f))
                    .background(Brush.horizontalGradient(GradientGoldAmber), RoundedCornerShape(10.dp))
                    .clickable { viewModel.triggerManualDoaQuest() }
                    .padding(horizontal = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text("Selesai", fontSize = 12.sp, fontWeight = FontWeight.Black, color = Color.Black)
            }
        }
    }
}
