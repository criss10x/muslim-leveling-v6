package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.border
import com.example.viewmodel.RewardRevealState
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import kotlinx.coroutines.delay

@Composable
fun LevelUpCelebrationOverlay(
    unlockedLevel: Int,
    rankTitle: String,
    onDismiss: () -> Unit
) {
    var animateStart by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        animateStart = true
    }

    // Scale & rotation animations
    val scale by animateFloatAsState(
        targetValue = if (animateStart) 1f else 0.4f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow)
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .clickable { onDismiss() }
            .testTag("level_up_overlay"),
        contentAlignment = Alignment.Center
    ) {
        // Confetti / glow background Canvas
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    val size = size
                    val center = center
                    val colors = listOf(GoldAccent.copy(alpha = 0.35f), Color.Transparent)
                    drawCircle(
                        brush = Brush.radialGradient(colors, center, size.width / 1.5f)
                    )
                }
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .padding(32.dp)
                .scale(scale)
                .testTag("level_up_container")
        ) {
            // Rank Up Banner Header
            Text(
                text = "RANK UP!",
                fontSize = 44.sp,
                fontWeight = FontWeight.Black,
                color = GoldAccent,
                letterSpacing = 4.sp,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Rank Badge Shape
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .background(IslamicGreen.copy(alpha = 0.2f), CircleShape)
                    .border(BorderStroke(4.dp, GoldAccent), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "🏅",
                    fontSize = 68.sp
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Subtitles
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
                color = GoldAccent,
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

@Composable
fun RewardRevealOverlay(
    state: RewardRevealState,
    onDismiss: () -> Unit
) {
    // We have 4 steps. Step 3 is conditional (only if 5/5 completed), Step 4 is conditional (only if reward is rolled)
    // Step index goes from 1 to 4
    val stepsSequence = remember(state) {
        val list = mutableListOf(1, 2)
        if (state.isFiveOfFiveCompleted) list.add(3)
        if (state.unlockedRewardName != null) list.add(4)
        list
    }

    var currentStepIdx by remember { mutableStateOf(0) }
    val currentStep = stepsSequence.getOrElse(currentStepIdx) { -1 }

    // Auto-advance timer: 1.5 seconds per card
    LaunchedEffect(currentStep) {
        if (currentStep != -1) {
            delay(1500)
            if (currentStepIdx < stepsSequence.size - 1) {
                currentStepIdx++
            } else {
                onDismiss()
            }
        }
    }

    // Screen tap skip trigger
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.82f))
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
        AnimatedContent(
            targetState = currentStep,
            transitionSpec = {
                slideInHorizontally { width -> width / 2 } + fadeIn() togetherWith
                slideOutHorizontally { width -> -width / 2 } + fadeOut()
            },
            label = "StepTransition"
        ) { targetStep ->
            when (targetStep) {
                1 -> RewardStepCard_Confirm(state.prayerName)
                2 -> RewardStepCard_Xp(state.prayerName, state.xpGained)
                3 -> RewardStepCard_FiveOfFive()
                4 -> RewardStepCard_GachaUnlock(state.unlockedRewardName ?: "", state.rewardIndex)
                else -> Box(modifier = Modifier.size(1.dp))
            }
        }
    }
}

@Composable
fun RewardStepCard_Confirm(prayerName: String) {
    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_1"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.dp, IslamicGreen)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(IslamicGreen.copy(alpha = 0.15f), CircleShape)
                    .border(BorderStroke(2.dp, IslamicGreen), CircleShape),
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
        }
    }
}

@Composable
fun RewardStepCard_Xp(prayerName: String, xpGained: Int) {
    var progressVal by remember { mutableStateOf(0f) }

    LaunchedEffect(Unit) {
        delay(100)
        progressVal = 0.75f // simulate progress animation bar
    }

    val animProgress by animateFloatAsState(
        targetValue = progressVal,
        animationSpec = tween(durationMillis = 1000)
    )

    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_2"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.dp, IslamicGreen)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(IslamicGreen.copy(alpha = 0.15f), CircleShape)
                    .border(BorderStroke(2.dp, IslamicGreen), CircleShape),
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

            LinearProgressIndicator(
                progress = { animProgress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(CircleShape),
                color = IslamicGreen,
                trackColor = DarkSurfaceVariant
            )

            Text(
                text = "Karaktermu makin kuat! Level up udah deket nih 🔥",
                fontSize = 11.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 10.dp)
            )
        }
    }
}

@Composable
fun RewardStepCard_FiveOfFive() {
    Card(
        modifier = Modifier
            .width(310.dp)
            .padding(16.dp)
            .testTag("reward_step_3"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(2.5.dp, Brush.linearGradient(listOf(GoldAccent, OrangeFlame)))
    ) {
        Column(
            modifier = Modifier
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(OrangeFlame.copy(alpha = 0.15f), Color.Transparent),
                            center = center,
                            radius = size.width
                        )
                    )
                }
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(OrangeFlame.copy(alpha = 0.2f), CircleShape),
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
                color = OrangeFlame,
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
        }
    }
}

@Composable
fun RewardStepCard_GachaUnlock(rewardName: String, iconIndex: Int) {
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
        border = BorderStroke(2.dp, GoldAccent)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(GoldAccent.copy(alpha = 0.15f), CircleShape)
                    .border(BorderStroke(2.dp, GoldAccent), CircleShape),
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
        }
    }
}
