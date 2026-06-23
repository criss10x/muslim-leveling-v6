package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import kotlinx.coroutines.delay

/**
 * Futuristic splash screen with animated neon glow rings, rotating arc,
 * pulse animation, and shimmer reveal of logo + app name.
 *
 * Phases:
 *   - Phase 1 (0–700ms):   outer ring scales in, glow pulses
 *   - Phase 2 (700–1400ms): rotating arc sweeps around
 *   - Phase 3 (1400–2100ms): logo + app name fade/scale in
 *   - Phase 4 (2100–2700ms): tagline appears
 *   - Phase 5 (2700ms):     onTimeout invoked
 */
@Composable
fun SplashScreen(
    onTimeout: () -> Unit
) {
    var phase by remember { mutableStateOf(0) }

    // Drive phase progression
    LaunchedEffect(Unit) {
        delay(700);   phase = 1
        delay(700);   phase = 2
        delay(700);   phase = 3
        delay(600);   phase = 4
        delay(400);   onTimeout()
    }

    // Rotating arc infinite animation (starts once phase >= 1)
    val infiniteTransition = rememberInfiniteTransition(label = "splash_arc")
    val arcRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1800, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "arc_rotation"
    )

    // Pulse glow infinite animation
    val pulseGlow by infiniteTransition.animateFloat(
        initialValue = 0.45f,
        targetValue = 0.85f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1400, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_glow"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .futuristicBackground(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // ── Hero logo container with rotating neon ring + glow ──
            Box(
                modifier = Modifier
                    .size(180.dp)
                    .drawBehind {
                        val radius = size.minDimension / 2f
                        val center = Offset(size.width / 2f, size.height / 2f)

                        // Outer radial glow (pulsing)
                        drawCircle(
                            brush = Brush.radialGradient(
                                colors = listOf(
                                    IslamicGreen.copy(alpha = pulseGlow * 0.5f),
                                    IslamicGreen.copy(alpha = 0.05f),
                                    Color.Transparent
                                ),
                                center = center,
                                radius = radius * 1.3f
                            ),
                            center = center,
                            radius = radius * 1.3f
                        )

                        // Dashed outer ring (subtle)
                        drawCircle(
                            color = IslamicGreen.copy(alpha = 0.25f),
                            radius = radius * 1.05f,
                            center = center,
                            style = Stroke(width = 1.5.dp.toPx())
                        )

                        // Rotating gradient arc
                        drawArc(
                            brush = Brush.sweepGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    IslamicGreen,
                                    GoldAccent,
                                    CyanAccent,
                                    Color.Transparent
                                )
                            ),
                            startAngle = arcRotation,
                            sweepAngle = 270f,
                            useCenter = false,
                            topLeft = Offset(center.x - radius, center.y - radius),
                            size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
                            style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
                        )

                        // Inner counter-rotating ring (gold)
                        drawArc(
                            color = GoldAccent.copy(alpha = 0.6f),
                            startAngle = -arcRotation * 1.5f,
                            sweepAngle = 60f,
                            useCenter = false,
                            topLeft = Offset(center.x - radius * 0.85f, center.y - radius * 0.85f),
                            size = androidx.compose.ui.geometry.Size(radius * 1.7f, radius * 1.7f),
                            style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round)
                        )
                    },
                contentAlignment = Alignment.Center
            ) {
                // Inner logo box (animated reveal)
                androidx.compose.animation.AnimatedVisibility(
                    visible = phase >= 2,
                    enter = scaleIn(animationSpec = tween(600)) + fadeIn(),
                    exit = scaleOut() + fadeOut()
                ) {
                    Box(
                        modifier = Modifier
                            .size(108.dp)
                            .shadow(
                                elevation = 24.dp,
                                shape = CircleShape,
                                ambientColor = IslamicGreen.copy(alpha = 0.6f),
                                spotColor = GoldAccent.copy(alpha = 0.4f)
                            )
                            .background(
                                brush = Brush.verticalGradient(
                                    listOf(DarkSurface, DarkSurfaceElevated)
                                ),
                                CircleShape
                            )
                            .border(
                                width = 2.dp,
                                brush = Brush.linearGradient(GradientGreenGold),
                                shape = CircleShape
                            )
                            .clip(CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "⭐",
                            fontSize = 56.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // ── App name (animated reveal) ──
            AnimatedVisibility(
                visible = phase >= 3,
                enter = fadeIn(tween(500)) + scaleIn(tween(500), initialScale = 0.85f)
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "MUSLIM LEVELING",
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Black,
                        color = TextLight,
                        letterSpacing = 4.sp,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.drawBehind {
                            // Subtle gradient text shadow glow
                            drawRect(Brush.verticalGradient(
                                listOf(IslamicGreenGlow.copy(alpha = 0.1f), Color.Transparent)
                            ))
                        }
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = "ARENA HIKMAH",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = GoldAccent,
                        letterSpacing = 8.sp,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── Tagline (phase 4) ──
            AnimatedVisibility(
                visible = phase >= 4,
                enter = fadeIn(tween(500))
            ) {
                Text(
                    text = "Level Up Iman, Level Up Kehidupanmu",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextMuted,
                    textAlign = TextAlign.Center
                )
            }
        }

        // ── Loading dots bottom indicator ──
        if (phase < 4) {
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 64.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                repeat(3) { index ->
                    val bounce = infiniteTransition.animateFloat(
                        initialValue = 0.3f,
                        targetValue = 1f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(
                                durationMillis = 700,
                                delayMillis = index * 200,
                                easing = LinearEasing
                            ),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "dot_$index"
                    )
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .shadow(
                                elevation = 6.dp,
                                shape = CircleShape,
                                ambientColor = IslamicGreen.copy(alpha = 0.6f),
                                spotColor = IslamicGreen.copy(alpha = 0.4f)
                            )
                            .background(
                                IslamicGreen.copy(alpha = bounce.value),
                                CircleShape
                            )
                    )
                }
            }
        }
    }
}
