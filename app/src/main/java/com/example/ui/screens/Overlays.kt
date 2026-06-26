package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.rotate
import androidx.compose.foundation.border
import com.example.viewmodel.RewardRevealState
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.geometry.minDimension
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.components.NeonProgressBar
import com.example.ui.theme.*
import kotlinx.coroutines.delay
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

// ═══════════════════════════════════════════════════════════════
// LEVEL UP CELEBRATION — Bintang Seal cracks open + particle burst
// ═══════════════════════════════════════════════════════════════

@Composable
fun LevelUpCelebrationOverlay(
    unlockedLevel: Int,
    rankTitle: String,
    onDismiss: () -> Unit
) {
    var phase by remember { mutableStateOf(0) } // 0=seal forming, 1=crack, 2=burst, 3=reveal

    LaunchedEffect(Unit) {
        delay(300)
        phase = 1 // crack
        delay(500)
        phase = 2 // burst
        delay(700)
        phase = 3 // reveal new seal
    }

    // Seal scale & rotation
    val sealScale by animateFloatAsState(
        targetValue = when (phase) {
            0 -> 0.4f
            1 -> 1.1f
            2 -> 1.3f
            else -> 1f
        },
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "seal_scale"
    )
    val sealRotation by animateFloatAsState(
        targetValue = when (phase) {
            0 -> -45f
            1 -> 0f
            2 -> 15f
            else -> 0f
        },
        animationSpec = tween(durationMillis = 600, easing = FastOutSlowInEasing),
        label = "seal_rotation"
    )

    // Particle burst animation
    val particleProgress by animateFloatAsState(
        targetValue = if (phase >= 2) 1f else 0f,
        animationSpec = tween(durationMillis = 800, easing = LinearOutSlowInEasing),
        label = "particle_progress"
    )

    // Rotating glow ring (background, always on after reveal)
    val infiniteTransition = rememberInfiniteTransition(label = "overlay_seal_glow")
    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 6000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "overlay_ring_rotation"
    )

    // Crack alpha (visible only in phase 1)
    val crackAlpha by animateFloatAsState(
        targetValue = if (phase == 1) 1f else if (phase >= 2) 0f else 0f,
        animationSpec = tween(durationMillis = 300),
        label = "crack_alpha"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.88f))
            .clickable { if (phase == 3) onDismiss() }
            .testTag("level_up_overlay"),
        contentAlignment = Alignment.Center
    ) {
        // Radial glow background — gold/teal burst
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    val glowIntensity = if (phase >= 2) 0.45f else 0.2f
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                GoldAccent.copy(alpha = glowIntensity),
                                IslamicGreen.copy(alpha = glowIntensity * 0.5f),
                                Color.Transparent
                            ),
                            center = center,
                            radius = size.width / 1.4f
                        )
                    )
                }
        )

        // Particle burst canvas (behind seal)
        if (phase >= 2) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .testTag("level_up_particles")
            ) {
                drawParticleBurst(
                    center = center,
                    progress = particleProgress,
                    teal = IslamicGreen,
                    gold = GoldAccent
                )
            }
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .padding(32.dp)
                .testTag("level_up_container")
        ) {
            // ── Bintang Seal (cracks then bursts) ──
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(220.dp)
            ) {
                // Rotating glow ring (visible from phase 1)
                if (phase >= 1) {
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
                }

                // The seal itself (scales/rotates through phases)
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .scale(sealScale)
                        .rotate(sealRotation)
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

                // Crack overlay (jagged gold lines, phase 1 only)
                if (crackAlpha > 0f) {
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .scale(sealScale)
                    ) {
                        drawCracks(
                            center = center,
                            radius = size.minDimension / 2f * 0.78f,
                            alpha = crackAlpha,
                            gold = GoldAccent
                        )
                    }
                }

                // Center level number (visible in phase 0 + phase 3)
                if (phase == 0 || phase == 3) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier
                            .scale(sealScale)
                    ) {
                        Text(
                            text = "LEVEL",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Black,
                            color = GoldAccent,
                            letterSpacing = 2.sp
                        )
                        Text(
                            text = "$unlockedLevel",
                            fontSize = 42.sp,
                            fontWeight = FontWeight.Black,
                            color = TextLight,
                            letterSpacing = (-1).sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ── RANK UP banner ──
            AnimatedVisibility(
                visible = phase == 3,
                enter = fadeIn(animationSpec = tween(400)) + slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec = tween(500, easing = FastOutSlowInEasing)
                )
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "RANK UP!",
                        fontSize = 44.sp,
                        fontWeight = FontWeight.Black,
                        color = GoldAccent,
                        letterSpacing = 4.sp,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "SELAMAT, PEJUANG! 🎉",
                        fontSize = 14.sp,
                        color = TextLight,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 1.5.sp
                    )

                    Text(
                        text = rankTitle,
                        fontSize = 26.sp,
                        color = IslamicGreen,
                        fontWeight = FontWeight.ExtraBold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )

                    Text(
                        text = "Level $unlockedLevel tercapai!",
                        fontSize = 16.sp,
                        color = TextLight.copy(alpha = 0.8f),
                        fontWeight = FontWeight.SemiBold,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(40.dp))

                    Text(
                        text = "TAP DI MANA AJA BUAT LANJUT 🎮",
                        fontSize = 11.sp,
                        color = TextMuted,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }
        }
    }
}

/**
 * Draws jagged crack lines radiating from center (phase 1 effect).
 */
fun DrawScope.drawCracks(
    center: Offset,
    radius: Float,
    alpha: Float,
    gold: Color
) {
    val crackColor = gold.copy(alpha = alpha)
    val crackWidth = 2.dp.toPx()
    // 5 jagged cracks at different angles
    val angles = listOf(0f, 72f, 144f, 216f, 288f)
    angles.forEach { angleDeg ->
        val rad = Math.toRadians(angleDeg.toDouble())
        val endX = center.x + (cos(rad) * radius * 1.1f).toFloat()
        val endY = center.y + (sin(rad) * radius * 1.1f).toFloat()
        // Mid point with slight offset for jagged look
        val midRad = Math.toRadians((angleDeg + 15f).toDouble())
        val midX = center.x + (cos(midRad) * radius * 0.55f).toFloat()
        val midY = center.y + (sin(midRad) * radius * 0.55f).toFloat()

        drawLine(
            color = crackColor,
            start = center,
            end = Offset(midX, midY),
            strokeWidth = crackWidth,
            cap = StrokeCap.Round
        )
        drawLine(
            color = crackColor,
            start = Offset(midX, midY),
            end = Offset(endX, endY),
            strokeWidth = crackWidth * 0.7f,
            cap = StrokeCap.Round
        )
    }
}

/**
 * Draws a burst of teal + gold particles radiating outward.
 * Uses deterministic pseudo-random angles so it's stable across recompositions.
 */
fun DrawScope.drawParticleBurst(
    center: Offset,
    progress: Float,
    teal: Color,
    gold: Color
) {
    val particleCount = 28
    val maxDistance = size.minDimension * 0.55f
    val particleSize = 4.dp.toPx()

    // Deterministic seed so particles don't jump around
    val random = Random(seed = 42L)

    for (i in 0 until particleCount) {
        val angle = (i.toFloat() / particleCount) * 360f + random.nextFloat() * 12f
        val rad = Math.toRadians(angle.toDouble())
        val distance = maxDistance * progress * (0.6f + random.nextFloat() * 0.4f)
        val px = center.x + (cos(rad) * distance).toFloat()
        val py = center.y + (sin(rad) * distance).toFloat()

        // Alternate teal and gold
        val color = if (i % 2 == 0) teal else gold
        // Fade out as they travel
        val alpha = (1f - progress).coerceIn(0f, 1f) * 0.9f

        // Particle as small circle with glow
        drawCircle(
            color = color.copy(alpha = alpha * 0.3f),
            radius = particleSize * 2f,
            center = Offset(px, py)
        )
        drawCircle(
            color = color.copy(alpha = alpha),
            radius = particleSize,
            center = Offset(px, py)
        )
    }

    // Central flash (bright at start, fades)
    val flashAlpha = (1f - progress * 2f).coerceIn(0f, 1f)
    if (flashAlpha > 0f) {
        drawCircle(
            color = Color.White.copy(alpha = flashAlpha * 0.8f),
            radius = maxDistance * 0.15f * (1f - progress),
            center = center
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// REWARD REVEAL OVERLAY (restyled with Arena Hikmah palette)
// ═══════════════════════════════════════════════════════════════

@Composable
fun RewardRevealOverlay(
    state: RewardRevealState,
    onDismiss: () -> Unit
) {
    // We have 5 steps. Step 3 (timely bonus) is conditional (only if ≤30min after adzan),
    // Step 4 (5/5 bonus) is conditional, Step 5 (gacha) is conditional.
    // Step index goes from 1 to 5
    val stepsSequence = remember(state) {
        val list = mutableListOf(1, 2)
        if (state.isTimelyBonus) list.add(3)
        if (state.isFiveOfFiveCompleted) list.add(4)
        if (state.unlockedRewardName != null) list.add(5)
        list
    }

    var currentStepIdx by remember { mutableStateOf(0) }
    val currentStep = stepsSequence.getOrElse(currentStepIdx) { -1 }
    val isLastStep = currentStepIdx >= stepsSequence.size - 1

    // Tap-to-advance only — no auto-advance timer, user controls pacing
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .clickable {
                if (currentStepIdx < stepsSequence.size - 1) {
                    currentStepIdx++
                } else {
                    onDismiss()
                }
            }
            .testTag("reward_reveal_overlay"),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            // Step indicator dots — Arena Hikmah styled
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 16.dp)
            ) {
                stepsSequence.forEachIndexed { index, _ ->
                    Box(
                        modifier = Modifier
                            .size(if (index == currentStepIdx) 10.dp else 7.dp)
                            .background(
                                if (index == currentStepIdx) Brush.horizontalGradient(GradientGreenGold)
                                else Brush.horizontalGradient(listOf(DarkSurfaceVariant, DarkSurfaceVariant)),
                                CircleShape
                            )
                            .then(
                                if (index == currentStepIdx) Modifier.shadow(6.dp, CircleShape, ambientColor = IslamicGreen.copy(alpha = 0.5f))
                                else Modifier
                            )
                    )
                }
            }

            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    slideInHorizontally { width -> width / 2 } + fadeIn() togetherWith
                    slideOutHorizontally { width -> -width / 2 } + fadeOut()
                },
                label = "StepTransition"
            ) { targetStep ->
                when (targetStep) {
                    1 -> RewardStepCard_Confirm(state.prayerName, isLastStep)
                    2 -> RewardStepCard_Xp(state.prayerName, state.xpGained, isLastStep)
                    3 -> RewardStepCard_TimelyBonus(isLastStep)
                    4 -> RewardStepCard_FiveOfFive(isLastStep)
                    5 -> RewardStepCard_GachaUnlock(state.unlockedRewardName ?: "", state.rewardIndex, isLastStep)
                    else -> Box(modifier = Modifier.size(1.dp))
                }
            }
        }
    }
}

@Composable
fun RewardStepCard_Confirm(prayerName: String, isLastStep: Boolean) {
    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_1"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.dp, Brush.linearGradient(GradientGreenGold))
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Arena Hikmah: teal-glowing icon disc
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .shadow(12.dp, CircleShape, ambientColor = IslamicGreen.copy(alpha = 0.4f))
                    .background(
                        Brush.radialGradient(listOf(IslamicGreen.copy(alpha = 0.3f), Color.Transparent)),
                        CircleShape
                    )
                    .border(
                        BorderStroke(
                            2.dp,
                            Brush.linearGradient(GradientGreenGold)
                        ),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "✅", fontSize = 38.sp)
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "IBADAH TERCATAT! ✅",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = GoldAccent,
                letterSpacing = 1.5.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Sholat $prayerName Selesai!",
                fontSize = 20.sp,
                fontWeight = FontWeight.ExtraBold,
                color = TextLight,
                textAlign = TextAlign.Center
            )

            Text(
                text = "Semoga diterima ya! Ring ritual harian udah ke-update 🌟",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 10.dp)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = if (isLastStep) "👇 TAP DI MANA AJA BUAT TUTUP" else "👇 TAP DI MANA AJA BUAT LANJUT",
                fontSize = 10.sp,
                color = IslamicGreen.copy(alpha = 0.7f),
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
fun RewardStepCard_Xp(prayerName: String, xpGained: Int, isLastStep: Boolean) {
    var progressVal by remember { mutableStateOf(0f) }

    LaunchedEffect(Unit) {
        delay(400)
        progressVal = 0.75f // simulate progress animation bar
    }

    val animProgress by animateFloatAsState(
        targetValue = progressVal,
        animationSpec = tween(durationMillis = 2200)
    )

    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_2"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.dp, Brush.linearGradient(GradientGreenGold))
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .shadow(12.dp, CircleShape, ambientColor = IslamicGreen.copy(alpha = 0.4f))
                    .background(
                        Brush.radialGradient(listOf(IslamicGreen.copy(alpha = 0.3f), Color.Transparent)),
                        CircleShape
                    )
                    .border(
                        BorderStroke(
                            2.dp,
                            Brush.linearGradient(GradientGreenGold)
                        ),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "⚡", fontSize = 42.sp)
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "+$xpGained XP!",
                fontSize = 26.sp,
                fontWeight = FontWeight.ExtraBold,
                color = IslamicGreen
            )

            Text(
                text = "Bonus Loot ($prayerName) 🎁",
                fontSize = 12.sp,
                color = TextMuted,
                modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
            )

            NeonProgressBar(
                progress = animProgress,
                modifier = Modifier.fillMaxWidth(),
                height = 9.dp,
                brush = Brush.horizontalGradient(listOf(IslamicGreen, GoldAccent, IslamicGreen)),
                glowColor = IslamicGreen,
                trackColor = DarkSurfaceVariant
            )

            Text(
                text = "Karaktermu makin kuat! Level up udah deket nih 🔥",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 10.dp)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = if (isLastStep) "👇 TAP DI MANA AJA BUAT TUTUP" else "👇 TAP DI MANA AJA BUAT LANJUT",
                fontSize = 10.sp,
                color = IslamicGreen.copy(alpha = 0.7f),
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
fun RewardStepCard_TimelyBonus(isLastStep: Boolean) {
    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_3"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.5.dp, Brush.linearGradient(GradientGreenGold))
    ) {
        Column(
            modifier = Modifier
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(IslamicGreen.copy(alpha = 0.18f), Color.Transparent),
                            center = center,
                            radius = size.width
                        )
                    )
                }
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Icon: glowing clock to symbolize timeliness
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .shadow(12.dp, CircleShape, ambientColor = IslamicGreen.copy(alpha = 0.4f))
                    .background(
                        Brush.radialGradient(listOf(IslamicGreen.copy(alpha = 0.3f), Color.Transparent)),
                        CircleShape
                    )
                    .border(
                        BorderStroke(2.dp, Brush.linearGradient(GradientGreenGold)),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "⏰", fontSize = 42.sp)
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "TEPAT WAKTU! ⚡",
                fontSize = 16.sp,
                fontWeight = FontWeight.Black,
                color = IslamicGreen,
                letterSpacing = 1.sp
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "Sholat Tepat Waktu",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight
            )

            Text(
                text = "+15 XP Bonus Tepat Waktu! 🌟",
                fontSize = 12.sp,
                color = IslamicGreen,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 4.dp)
            )

            Text(
                text = "Mantap! Sholat dalam 30 menit pertama setelah adzan. Pertahanin terus ya! 💪",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 12.dp)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = if (isLastStep) "👇 TAP DI MANA AJA BUAT TUTUP" else "👇 TAP DI MANA AJA BUAT LANJUT",
                fontSize = 10.sp,
                color = IslamicGreen.copy(alpha = 0.7f),
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
fun RewardStepCard_FiveOfFive(isLastStep: Boolean) {
    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_3"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.5.dp, Brush.linearGradient(GradientGoldAmber))
    ) {
        Column(
            modifier = Modifier
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(AmberFlame.copy(alpha = 0.15f), Color.Transparent),
                            center = center,
                            radius = size.width
                        )
                    )
                }
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Arena Hikmah: crimson/gold streak icon
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .shadow(12.dp, CircleShape, ambientColor = RingRed.copy(alpha = 0.4f))
                    .background(
                        Brush.radialGradient(listOf(RingRed.copy(alpha = 0.25f), Color.Transparent)),
                        CircleShape
                    )
                    .border(
                        BorderStroke(2.dp, Brush.linearGradient(GradientGoldAmber)),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "🔥", fontSize = 44.sp)
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "5/5 LENGKAP HARI INI!",
                fontSize = 16.sp,
                fontWeight = FontWeight.Black,
                color = GoldAccent,
                letterSpacing = 1.sp
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "Hero Streak +1",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight
            )

            Text(
                text = "+50 XP Bonus 5/5 Aktif! 🔥",
                fontSize = 12.sp,
                color = RingRed,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 4.dp)
            )

            Text(
                text = "Keren! Pertahanin streak 5/5 besok ya biar bonus gila ini tetep aktif! 🔥",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 12.dp)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = if (isLastStep) "👇 TAP DI MANA AJA BUAT TUTUP" else "👇 TAP DI MANA AJA BUAT LANJUT",
                fontSize = 10.sp,
                color = GoldAccent.copy(alpha = 0.7f),
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
fun RewardStepCard_GachaUnlock(rewardName: String, iconIndex: Int, isLastStep: Boolean) {
    val bEmoji = when (iconIndex) {
        1 -> "🌙"
        2 -> "🔱"
        3 -> "🖼️"
        4 -> "⚔️"
        5 -> "🧪"
        6 -> "🌌"
        7 -> "☄️"
        8 -> "🥋"
        9 -> "👼"
        else -> "🗡️"
    }

    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_4"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.dp, Brush.linearGradient(GradientGoldAmber))
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .shadow(12.dp, CircleShape, ambientColor = GoldAccent.copy(alpha = 0.4f))
                    .background(
                        Brush.radialGradient(listOf(GoldAccent.copy(alpha = 0.2f), Color.Transparent)),
                        CircleShape
                    )
                    .border(BorderStroke(2.dp, Brush.linearGradient(GradientGoldAmber)), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(text = bEmoji, fontSize = 40.sp)
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "🎁 UNLOCK BONUS LOOT!",
                fontSize = 13.sp,
                fontWeight = FontWeight.ExtraBold,
                color = GoldAccent,
                letterSpacing = 1.5.sp
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = rewardName,
                fontSize = 18.sp,
                fontWeight = FontWeight.Black,
                color = TextLight,
                textAlign = TextAlign.Center
            )

            Text(
                text = "Item langka udah masuk koleksi profil kamu! Cek di tab Profil ya 🎁",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 10.dp)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = if (isLastStep) "👇 TAP DI MANA AJA BUAT TUTUP" else "👇 TAP DI MANA AJA BUAT LANJUT",
                fontSize = 10.sp,
                color = GoldAccent.copy(alpha = 0.7f),
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}
