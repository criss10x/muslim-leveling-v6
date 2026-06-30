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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.rotate
import androidx.compose.foundation.border
import com.example.viewmodel.RewardRevealState
import com.example.viewmodel.TierUpData
import com.example.viewmodel.ChestRevealState
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
    // ponytail: mockup is a static reveal card (rank up + rewards + claim).
    // Kept one lightweight reveal animation (fade+slide). Seal/crack/burst
    // choreography removed — not in mockup, add back when motion spec lands.
    var revealed by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(120)
        revealed = true
    }

    val revealAlpha by animateFloatAsState(
        targetValue = if (revealed) 1f else 0f,
        animationSpec = tween(durationMillis = 450, easing = FastOutSlowInEasing),
        label = "rankup_alpha"
    )
    val revealOffset by animateFloatAsState(
        targetValue = if (revealed) 0f else 40f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioLowBouncy, stiffness = Spring.StiffnessMediumLow),
        label = "rankup_offset"
    )

    // Medal idle float + aura pulse (subtle, matches mockup's animate-float / glow)
    val infiniteTransition = rememberInfiniteTransition(label = "rankup_medal")
    val floatY by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = -8f,
        animationSpec = infiniteRepeatable(tween(2800, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "medal_float"
    )
    val auraScale by infiniteTransition.animateFloat(
        initialValue = 0.92f, targetValue = 1.08f,
        animationSpec = infiniteRepeatable(tween(2200, easing = LinearEasing), RepeatMode.Reverse),
        label = "medal_aura"
    )
    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(10000, easing = LinearEasing), RepeatMode.Restart),
        label = "medal_ring"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.88f))
            .clickable { if (revealed) onDismiss() }
            .testTag("level_up_overlay"),
        contentAlignment = Alignment.Center
    ) {
        // ── Soft radial glow behind card (gold→teal) ──
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                GoldGlow,
                                IslamicGreenGlow,
                                Color.Transparent
                            ),
                            center = center,
                            radius = size.width / 1.4f
                        )
                    )
                }
        )

        // ── Card ──
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .padding(20.dp)
                .fillMaxWidth()
                .offset(y = revealOffset.dp)
                .alpha(revealAlpha)
                .clip(RoundedCornerShape(28.dp))
                .background(
                    Brush.verticalGradient(GradientDarkSurface)
                )
                .border(
                    BorderStroke(1.dp, OutlineVariant.copy(alpha = 0.6f)),
                    RoundedCornerShape(28.dp)
                )
                .padding(horizontal = 24.dp, vertical = 28.dp)
                .testTag("level_up_container")
        ) {
            // ── RANK UP! header (gold gradient) + teal rank title ──
            Text(
                text = "RANK UP!",
                style = MaterialTheme.typography.displayMedium,
                fontSize = 40.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 3.sp,
                textAlign = TextAlign.Center,
                color = GoldAccent,
                modifier = Modifier
                    .fillMaxWidth()
                    .drawBehind {
                        // ponytail: gold drop-shadow glow approximated via drawBehind blur substitute
                        drawRect(
                            brush = Brush.verticalGradient(
                                listOf(GoldGlow, Color.Transparent)
                            )
                        )
                    }
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = rankTitle.uppercase(),
                fontSize = 20.sp,
                fontWeight = FontWeight.ExtraBold,
                color = IslamicGreen,
                letterSpacing = 2.sp,
                textAlign = TextAlign.Center
            )

            // ── Central medal icon (gold-glow aura + rotating ring + ribbon) ──
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .padding(vertical = 20.dp)
                    .size(160.dp)
                    .offset(y = floatY.dp)
            ) {
                // Gold glow aura (pulsing)
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .scale(auraScale)
                ) {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                GoldAccent.copy(alpha = 0.45f),
                                GoldAccent.copy(alpha = 0.12f),
                                Color.Transparent
                            ),
                            center = center,
                            radius = size.minDimension / 2f
                        )
                    )
                }
                // Rotating glow ring (teal/gold) — reuse existing helper
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
                // Medal body — gold-bordered rounded square w/ military_tech emoji
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(96.dp)
                        .clip(RoundedCornerShape(20.dp))
                        .background(
                            Brush.linearGradient(
                                listOf(DarkSurfaceVariant, DarkSurface)
                            )
                        )
                        .border(
                            BorderStroke(2.dp, GoldAccent),
                            RoundedCornerShape(20.dp)
                        )
                        .shadow(
                            elevation = 0.dp,
                            shape = RoundedCornerShape(20.dp),
                            ambientColor = GoldAccent.copy(alpha = 0.6f),
                            spotColor = GoldAccent.copy(alpha = 0.8f)
                        )
                ) {
                    // ponytail: medal icon via emoji — replace with vector asset if design demands fidelity
                    Text(text = "🎖️", fontSize = 52.sp)
                }
            }

            // ── REWARDS UNLOCKED section ──
            Text(
                text = "REWARDS UNLOCKED",
                style = MaterialTheme.typography.labelLarge,
                fontSize = 12.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))

            // ponytail: reward values are static mockup copy. VM exposes no
            // reward breakdown into this overlay; promote to params when wired.
            RewardRow(
                icon = "⭐",
                iconColor = IslamicGreen,
                iconBgTint = IslamicGreen.copy(alpha = 0.10f),
                borderColor = IslamicGreen.copy(alpha = 0.20f),
                label = "Experience",
                value = "+500 XP",
                valueColor = IslamicGreen
            )
            Spacer(modifier = Modifier.height(10.dp))
            RewardRow(
                icon = "🛡️",
                iconColor = GoldAccent,
                iconBgTint = GoldAccent.copy(alpha = 0.10f),
                borderColor = GoldAccent.copy(alpha = 0.20f),
                label = "Badge Baru",
                value = "Penjaga Subuh",
                valueColor = GoldAccent
            )
            Spacer(modifier = Modifier.height(10.dp))
            RewardRow(
                icon = "💎",
                iconColor = CyanAccent,
                iconBgTint = CyanAccent.copy(alpha = 0.10f),
                borderColor = CyanAccent.copy(alpha = 0.20f),
                label = "Nur Points",
                value = "+10",
                valueColor = CyanAccent
            )

            Spacer(modifier = Modifier.height(28.dp))

            // ── KLAIM HADIAH button (gold gradient + glow) ──
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Brush.horizontalGradient(GradientGoldAmber))
                    .clickable(enabled = revealed) { onDismiss() }
                    .testTag("level_up_claim_button"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "KLAIM HADIAH",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Black,
                    color = DarkBackground,
                    letterSpacing = 3.sp
                )
            }

            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = "Level $unlockedLevel tercapai! 🎉",
                fontSize = 11.sp,
                color = TextMuted,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.5.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Single reward row matching naik_level mockup: icon bubble (left) + label,
 * value (right) in label-caps style, tinted border.
 */
@Composable
private fun RewardRow(
    icon: String,
    iconColor: Color,
    iconBgTint: Color,
    borderColor: Color,
    label: String,
    value: String,
    valueColor: Color
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(DarkSurfaceElevated)
            .border(BorderStroke(1.dp, borderColor), RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(iconBgTint)
            ) {
                Text(text = icon, fontSize = 18.sp)
            }
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = label,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextLight
            )
        }
        Text(
            text = value,
            style = MaterialTheme.typography.labelLarge,
            fontSize = 12.sp,
            color = valueColor,
            fontWeight = FontWeight.Bold
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// TIER UP CELEBRATION — Epic tier transition with beam & emblem
// ═══════════════════════════════════════════════════════════════

/**
 * Returns the primary and secondary colors for a given tier name.
 * Used to theme the TierUpCelebrationOverlay per tier.
 */
private fun getTierColors(tierName: String): Pair<Color, Color> {
    return when (tierName) {
        "Warrior"           -> Color(0xFF8B5CF6) to Color(0xFF6366F1)  // Purple→Indigo
        "Elite"             -> Color(0xFF3B82F6) to Color(0xFF06B6D4)  // Blue→Cyan
        "Master"            -> Color(0xFF14E8C8) to Color(0xFF10B981)  // Teal→Emerald
        "Grandmaster"       -> Color(0xFFFFB627) to Color(0xFFFF8A00)  // Gold→Amber
        "Epic"              -> Color(0xFFFF3D5A) to Color(0xFFEC4899)  // Crimson→Pink
        "Legend"            -> Color(0xFFE8EDF5) to Color(0xFFFFB627)  // White→Gold
        "Mythic"            -> Color(0xFFFF3D5A) to Color(0xFFFFB627)  // Crimson→Gold
        "Mythic Honor"      -> Color(0xFFFFB627) to Color(0xFFFF3D5A)  // Gold→Crimson
        "Mythic Glory"      -> Color(0xFFE8EDF5) to Color(0xFFFF3D5A)  // White→Crimson
        "Mythic Immortal"   -> Color(0xFFFFB627) to Color(0xFFE8EDF5)  // Gold→White
        else                -> Color(0xFF14E8C8) to Color(0xFFFFB627)  // Default teal→gold
    }
}

/**
 * Returns a single emoji/icon symbol for the tier (rendered as text in the emblem).
 */
private fun getTierEmoji(tierName: String): String {
    return when (tierName) {
        "Warrior"           -> "⚔️"
        "Elite"             -> "🛡️"
        "Master"            -> "🎓"
        "Grandmaster"       -> "👑"
        "Epic"              -> "🔥"
        "Legend"            -> "⭐"
        "Mythic"            -> "💎"
        "Mythic Honor"      -> "💎"
        "Mythic Glory"      -> "🏆"
        "Mythic Immortal"   -> "🌟"
        else                -> "✨"
    }
}

@Composable
fun TierUpCelebrationOverlay(
    tierUpData: TierUpData,
    onDismiss: () -> Unit
) {
    var phase by remember { mutableStateOf(0) }
    // 0 = dark w/ subtle glow + "TIER UP" text incoming
    // 1 = old tier name fades out, beam sweeps
    // 2 = burst particles + new tier emblem slams in
    // 3 = full reveal with congratulatory text

    val (primaryColor, secondaryColor) = getTierColors(tierUpData.newTierName)
    val tierEmoji = getTierEmoji(tierUpData.newTierName)

    LaunchedEffect(Unit) {
        delay(400)
        phase = 1   // old tier fade out + beam
        delay(600)
        phase = 2   // burst + emblem
        delay(800)
        phase = 3   // reveal
    }

    // Emblem scale (slam-in effect)
    val emblemScale by animateFloatAsState(
        targetValue = when (phase) {
            0, 1 -> 0f
            2 -> 1.4f
            else -> 1f
        },
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "tier_emblem_scale"
    )

    // Emblem rotation (slight tilt on slam, settle to 0)
    val emblemRotation by animateFloatAsState(
        targetValue = when (phase) {
            2 -> -8f
            else -> 0f
        },
        animationSpec = tween(durationMillis = 500, easing = FastOutSlowInEasing),
        label = "tier_emblem_rotation"
    )

    // Particle burst progress
    val particleProgress by animateFloatAsState(
        targetValue = if (phase >= 2) 1f else 0f,
        animationSpec = tween(durationMillis = 900, easing = LinearOutSlowInEasing),
        label = "tier_particle_progress"
    )

    // Rotating glow ring (infinite, visible from phase 2)
    val infiniteTransition = rememberInfiniteTransition(label = "tier_overlay_glow")
    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "tier_ring_rotation"
    )

    // Beam sweep (phase 1 → 2 transition)
    val beamProgress by animateFloatAsState(
        targetValue = when (phase) {
            0 -> 0f
            1 -> 0.5f
            else -> 1f
        },
        animationSpec = tween(durationMillis = 800, easing = LinearOutSlowInEasing),
        label = "tier_beam_progress"
    )

    // Old tier alpha (fades out during phase 1)
    val oldTierAlpha by animateFloatAsState(
        targetValue = when (phase) {
            0 -> 1f
            1 -> 0f
            else -> 0f
        },
        animationSpec = tween(durationMillis = 500),
        label = "old_tier_alpha"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.92f))
            .clickable { if (phase == 3) onDismiss() }
            .testTag("tier_up_overlay"),
        contentAlignment = Alignment.Center
    ) {
        // ── Radial glow background (tier-colored) ──
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    val glowIntensity = when {
                        phase >= 2 -> 0.55f
                        phase >= 1 -> 0.35f
                        else -> 0.15f
                    }
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                primaryColor.copy(alpha = glowIntensity),
                                secondaryColor.copy(alpha = glowIntensity * 0.4f),
                                Color.Transparent
                            ),
                            center = center,
                            radius = size.width / 1.3f
                        )
                    )
                }
        )

        // ── Beam sweep (diagonal light, phase 1→2) ──
        if (beamProgress in 0.01f..0.99f) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .testTag("tier_beam")
            ) {
                val beamWidth = size.width * 0.3f
                val beamX = -beamWidth + (size.width + beamWidth * 2) * beamProgress
                drawRect(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color.Transparent,
                            primaryColor.copy(alpha = 0.15f),
                            Color.White.copy(alpha = 0.3f),
                            primaryColor.copy(alpha = 0.15f),
                            Color.Transparent
                        ),
                        start = Offset(beamX - beamWidth, 0f),
                        end = Offset(beamX + beamWidth, size.height)
                    ),
                    size = size
                )
            }
        }

        // ── Particle burst (phase ≥ 2) ──
        if (phase >= 2) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .testTag("tier_particles")
            ) {
                drawParticleBurst(
                    center = center,
                    progress = particleProgress,
                    teal = primaryColor,
                    gold = secondaryColor
                )
            }
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .padding(32.dp)
                .testTag("tier_up_container")
        ) {
            // ── Old tier name (fades out in phase 1) ──
            if (oldTierAlpha > 0.01f) {
                Text(
                    text = tierUpData.oldTierName.uppercase(),
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextMuted.copy(alpha = oldTierAlpha),
                    letterSpacing = 3.sp,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            // ── Tier Emblem (phase ≥ 2) ──
            if (phase >= 2) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(240.dp)
                ) {
                    // Rotating glow ring (outer)
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .rotate(ringRotation)
                    ) {
                        drawRotatingGlowRing(
                            center = center,
                            radius = size.minDimension / 2f * 0.95f,
                            teal = primaryColor,
                            gold = secondaryColor
                        )
                    }

                    // Emblem disc (scales & rotates in)
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .scale(emblemScale)
                            .rotate(emblemRotation)
                    ) {
                        // Outer ring
                        drawCircle(
                            color = primaryColor.copy(alpha = 0.3f),
                            radius = size.minDimension / 2f * 0.85f,
                            style = Stroke(width = 3.dp.toPx())
                        )
                        // Filled disc with gradient
                        drawCircle(
                            brush = Brush.radialGradient(
                                colors = listOf(
                                    secondaryColor.copy(alpha = 0.4f),
                                    primaryColor.copy(alpha = 0.2f),
                                    DarkSurface.copy(alpha = 0.9f)
                                ),
                                center = center,
                                radius = size.minDimension / 2f * 0.78f
                            ),
                            radius = size.minDimension / 2f * 0.78f
                        )
                        // Inner decorative ring
                        drawCircle(
                            color = primaryColor.copy(alpha = 0.5f),
                            radius = size.minDimension / 2f * 0.65f,
                            style = Stroke(width = 1.5.dp.toPx())
                        )
                    }

                    // Tier emoji in center (scales with emblem)
                    Text(
                        text = tierEmoji,
                        fontSize = 56.sp,
                        modifier = Modifier.scale(emblemScale)
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // ── TIER UP banner (phase ≥ 2) ──
            AnimatedVisibility(
                visible = phase >= 2,
                enter = fadeIn(animationSpec = tween(500)) + scaleIn(
                    initialScale = 0.5f,
                    animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy)
                )
            ) {
                Text(
                    text = "TIER UP!",
                    fontSize = 48.sp,
                    fontWeight = FontWeight.Black,
                    color = primaryColor,
                    letterSpacing = 4.sp,
                    textAlign = TextAlign.Center
                )
            }

            // ── New tier name + rank (phase 3) ──
            AnimatedVisibility(
                visible = phase == 3,
                enter = fadeIn(animationSpec = tween(400)) + slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec = tween(500, easing = FastOutSlowInEasing)
                )
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "SELAMAT, PEJUANG! 🎉",
                        fontSize = 14.sp,
                        color = TextLight,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 1.5.sp
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // New tier name (big)
                    Text(
                        text = tierUpData.newTierName.uppercase(),
                        fontSize = 32.sp,
                        color = secondaryColor,
                        fontWeight = FontWeight.Black,
                        textAlign = TextAlign.Center,
                        letterSpacing = 2.sp
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Full rank title
                    Text(
                        text = tierUpData.rankTitle,
                        fontSize = 18.sp,
                        color = primaryColor,
                        fontWeight = FontWeight.ExtraBold,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = "Tier baru tercapai di Level ${tierUpData.unlockedLevel}!",
                        fontSize = 14.sp,
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
    // We have 4 steps. Step 3 (timely bonus) is conditional (only if ≤30min after adzan),
    // Step 4 (5/5 bonus) is conditional. Gacha step removed — replaced by Daily Reward Chest.
    // Step index goes from 1 to 4
    val stepsSequence = remember(state) {
        val list = mutableListOf(1, 2)
        if (state.isTimelyBonus) list.add(3)
        if (state.isFiveOfFiveCompleted) list.add(4)
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

// ═══════════════════════════════════════════════════════════════
// DAILY REWARD CHEST OVERLAY
// Triggered when user claims daily chest after completing 5/5 wajib prayers.
// 3-phase animation: 1) Glow + shake build-up  2) Chest burst open  3) Reward reveal
// ═══════════════════════════════════════════════════════════════
@Composable
fun DailyChestOverlay(
    state: ChestRevealState,
    onDismiss: () -> Unit
) {
    // Phase: 0 = glow+shake build-up (2s), 1 = burst reveal (rest)
    var phase by remember { mutableStateOf(0) }
    LaunchedEffect(state) {
        delay(2000)
        phase = 1
    }

    // Shake animation during phase 0
    val shakeTransition = rememberInfiniteTransition(label = "chest_shake")
    val shakeOffset by shakeTransition.animateFloat(
        initialValue = -3f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(
            animation = tween(80, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "shake_x"
    )
    val glowAlpha by shakeTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glow_pulse"
    )

    // Burst scale animation during phase 1
    val burstScale by animateFloatAsState(
        targetValue = if (phase == 1) 1f else 0.3f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "burst_scale"
    )
    val revealAlpha by animateFloatAsState(
        targetValue = if (phase == 1) 1f else 0f,
        animationSpec = tween(400, delayMillis = 200),
        label = "reveal_alpha"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f))
            .clickable {
                if (phase == 1) onDismiss()
            },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(24.dp)
        ) {
            // ─── Chest emoji / Reward emoji ───
            Box(
                modifier = Modifier.size(180.dp),
                contentAlignment = Alignment.Center
            ) {
                if (phase == 0) {
                    // Phase 0: shaking chest with glow
                    Box(
                        modifier = Modifier
                            .offset(x = shakeOffset.dp)
                            .size(140.dp)
                            .shadow(
                                24.dp,
                                RoundedCornerShape(24.dp),
                                ambientColor = GoldAccent.copy(alpha = glowAlpha * 0.6f)
                            )
                            .background(
                                Brush.radialGradient(
                                    listOf(
                                        GoldAccent.copy(alpha = glowAlpha * 0.3f),
                                        Color.Transparent
                                    )
                                ),
                                RoundedCornerShape(24.dp)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = "📦", fontSize = 80.sp)
                    }
                } else {
                    // Phase 1: burst reveal — reward emoji with spring scale
                    Box(
                        modifier = Modifier
                            .scale(burstScale)
                            .size(140.dp)
                            .shadow(
                                32.dp,
                                CircleShape,
                                ambientColor = GoldAccent.copy(alpha = 0.5f)
                            )
                            .background(
                                Brush.radialGradient(
                                    listOf(GoldAccent.copy(alpha = 0.25f), Color.Transparent)
                                ),
                                CircleShape
                            )
                            .border(
                                BorderStroke(3.dp, Brush.linearGradient(GradientGoldAmber)),
                                CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = state.rewardEmoji, fontSize = 72.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            if (phase == 0) {
                // Phase 0: build-up text
                Text(
                    text = "MEMBUKA PETI...",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Black,
                    color = GoldAccent,
                    letterSpacing = 3.sp
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = "🎁 ✨ 🎁",
                    fontSize = 24.sp,
                    color = TextMuted
                )
            } else {
                // Phase 1: reveal content
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.alpha(revealAlpha)
                ) {
                    Text(
                        text = "🎉 PETI DIBUKA! 🎉",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black,
                        color = GoldAccent,
                        letterSpacing = 2.sp
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // XP reward pill
                    Box(
                        modifier = Modifier
                            .background(
                                Brush.horizontalGradient(GradientGreenGold),
                                RoundedCornerShape(100.dp)
                            )
                            .padding(horizontal = 20.dp, vertical = 8.dp)
                    ) {
                        Text(
                            text = "+${state.xpReward} XP BONUS",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Black,
                            color = Color.Black
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Reward name
                    Text(
                        text = state.rewardName,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextLight,
                        textAlign = TextAlign.Center
                    )

                    if (state.isDuplicate) {
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "(Item duplikat — koleksi kamu udah lengkap!)",
                            fontSize = 11.sp,
                            color = TextMuted,
                            textAlign = TextAlign.Center
                        )
                    } else {
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "✨ Item baru masuk koleksi! Cek di tab Profil ✨",
                            fontSize = 11.sp,
                            color = TextMuted,
                            textAlign = TextAlign.Center
                        )
                    }

                    Spacer(modifier = Modifier.height(28.dp))

                    Text(
                        text = "👇 TAP DI MANA AJA BUAT TUTUP",
                        fontSize = 10.sp,
                        color = GoldAccent.copy(alpha = 0.7f),
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }
        }
    }
}

// Helper: draw a rotating neon glow ring (used in celebration overlays)
private fun DrawScope.drawRotatingGlowRing(
    center: Offset,
    radius: Float,
    teal: Color,
    gold: Color,
    strokeWidth: Float = 3.dp.toPx()
) {
    // Outer teal arc
    drawArc(
        color = teal.copy(alpha = 0.6f),
        startAngle = 0f,
        sweepAngle = 120f,
        useCenter = false,
        topLeft = Offset(center.x - radius, center.y - radius),
        size = Size(radius * 2f, radius * 2f),
        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
    )
    // Middle gold arc
    drawArc(
        color = gold.copy(alpha = 0.8f),
        startAngle = 120f,
        sweepAngle = 120f,
        useCenter = false,
        topLeft = Offset(center.x - radius, center.y - radius),
        size = Size(radius * 2f, radius * 2f),
        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
    )
    // Inner teal arc
    drawArc(
        color = teal.copy(alpha = 0.6f),
        startAngle = 240f,
        sweepAngle = 120f,
        useCenter = false,
        topLeft = Offset(center.x - radius, center.y - radius),
        size = Size(radius * 2f, radius * 2f),
        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
    )
}
