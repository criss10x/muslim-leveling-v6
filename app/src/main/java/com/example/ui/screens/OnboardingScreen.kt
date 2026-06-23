package com.example.ui.screens

import androidx.compose.animation.*
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.components.CityDropdownPicker
import com.example.ui.theme.*

/**
 * Futuristic onboarding flow with 2 steps:
 *   Step 0 — Welcome (hero logo, animated gradient, benefit cards with neon borders)
 *   Step 1 — Create Character (form with neon inputs + mode chooser gradient)
 */
@Composable
fun OnboardingScreen(
    onComplete: (String, String, String) -> Unit
) {
    var currentStep by remember { mutableStateOf(0) }
    var username by remember { mutableStateOf("") }
    var kota by remember { mutableStateOf("Jakarta") }
    var intensityMode by remember { mutableStateOf("standar") }
    var errorMsg by remember { mutableStateOf("") }

    val scrollState = rememberScrollState()

    // Slow rotating ambient glow behind everything
    val infiniteTransition = rememberInfiniteTransition(label = "onboard_ambient")
    val ambientRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 12000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ambient_rotation"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .futuristicBackground()
            .drawBehind {
                // Slow-rotating conic-like ambient beam (approximated by radial sweep)
                val center = Offset(size.width / 2f, size.height * 0.25f)
                drawCircle(
                    brush = Brush.sweepGradient(
                        colors = listOf(
                            IslamicGreen.copy(alpha = 0.04f),
                            Color.Transparent,
                            GoldAccent.copy(alpha = 0.03f),
                            Color.Transparent,
                            IslamicGreen.copy(alpha = 0.04f)
                        )
                    ),
                    radius = size.width * 0.9f,
                    center = center
                )
            }
            .windowInsetsPadding(WindowInsets.statusBars)
            .windowInsetsPadding(WindowInsets.navigationBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    (slideInHorizontally { it } + fadeIn()) togetherWith
                        (slideOutHorizontally { -it } + fadeOut())
                },
                label = "onboarding_step"
            ) { step ->
                when (step) {
                    0 -> WelcomeStep(onStart = { currentStep = 1 })
                    1 -> CreateCharacterStep(
                        username = username,
                        onUsernameChange = { username = it; errorMsg = "" },
                        kota = kota,
                        onKotaChange = { kota = it; errorMsg = "" },
                        intensityMode = intensityMode,
                        onIntensityModeChange = { intensityMode = it },
                        errorMsg = errorMsg,
                        onBack = { currentStep = 0 },
                        onSubmit = {
                            when {
                                username.trim().isEmpty() ->
                                    errorMsg = "Oops! Nickname-nya jangan kosong ya 😅"
                                kota.trim().isEmpty() ->
                                    errorMsg = "Masukin kota asalmu dulu biar jadwal sholatnya muncul!"
                                else -> onComplete(username.trim(), intensityMode, kota.trim())
                            }
                        }
                    )
                }
            }
        }

        // Futuristic step indicator dots
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            repeat(2) { index ->
                val isActive = index == currentStep
                Box(
                    modifier = Modifier
                        .size(if (isActive) 28.dp else 8.dp, 8.dp)
                        .clip(CircleShape)
                        .then(
                            if (isActive) Modifier
                                .shadow(
                                    elevation = 6.dp,
                                    shape = CircleShape,
                                    ambientColor = IslamicGreen.copy(alpha = 0.6f),
                                    spotColor = IslamicGreen.copy(alpha = 0.4f)
                                )
                                .background(neonGreenBrush())
                            else Modifier.background(DarkSurfaceVariant)
                        )
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// STEP 1 — Welcome
// ═══════════════════════════════════════════════════════════════

@Composable
private fun WelcomeStep(
    onStart: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // ── Hero Logo with rotating gradient ring + glow ──
        val infiniteTransition = rememberInfiniteTransition(label = "logo_ring")
        val ringRotation by infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = 4000, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            ),
            label = "ring_rotation"
        )
        val pulse by infiniteTransition.animateFloat(
            initialValue = 0.5f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(
                animation = tween(1400, easing = LinearEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "logo_pulse"
        )

        Box(
            modifier = Modifier
                .size(140.dp)
                .drawBehind {
                    val radius = size.minDimension / 2f
                    val center = Offset(size.width / 2f, size.height / 2f)

                    // Pulsing radial glow
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                IslamicGreen.copy(alpha = pulse * 0.35f),
                                Color.Transparent
                            ),
                            center = center,
                            radius = radius * 1.3f
                        ),
                        center = center,
                        radius = radius * 1.3f
                    )

                    // Static ring
                    drawCircle(
                        color = IslamicGreen.copy(alpha = 0.3f),
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
                                Color.Transparent
                            )
                        ),
                        startAngle = ringRotation,
                        sweepAngle = 240f,
                        useCenter = false,
                        topLeft = Offset(center.x - radius, center.y - radius),
                        size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
                        style = Stroke(width = 3.dp.toPx())
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .shadow(
                        elevation = 20.dp,
                        shape = RoundedCornerShape(28.dp),
                        ambientColor = IslamicGreen.copy(alpha = 0.5f),
                        spotColor = GoldAccent.copy(alpha = 0.3f)
                    )
                    .background(
                        brush = Brush.verticalGradient(listOf(DarkSurface, DarkSurfaceElevated)),
                        RoundedCornerShape(28.dp)
                    )
                    .border(
                        width = 2.dp,
                        brush = Brush.linearGradient(GradientGreenGold),
                        shape = RoundedCornerShape(28.dp)
                    )
                    .clip(RoundedCornerShape(28.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "🌙", fontSize = 48.sp)
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // App name with gradient text glow
        Text(
            text = "MUSLIM LEVELING",
            fontSize = 30.sp,
            fontWeight = FontWeight.Black,
            color = TextLight,
            letterSpacing = 3.sp,
            textAlign = TextAlign.Center
        )

        Text(
            text = "ARENA HIKMAH",
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            letterSpacing = 6.sp,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Level Up Iman, Level Up Kehidupanmu",
            fontSize = 17.sp,
            color = TextLight,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Text(
            text = "Companion sholat harian dengan cara yang seru & tanpa ribet",
            fontSize = 13.sp,
            color = TextMuted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp, start = 24.dp, end = 24.dp)
        )

        Spacer(modifier = Modifier.height(36.dp))

        // ── Benefit cards with neon gradient borders ──
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            BenefitCard(
                emoji = "🎯",
                title = "Quest Sholat Harian",
                description = "Tracking 5 waktu sholat dengan sistem XP & level",
                gradient = GradientGreenGold,
                glowColor = IslamicGreen
            )
            BenefitCard(
                emoji = "📚",
                title = "Belajar Sambil Main",
                description = "16 modul + 80 quiz bikin belajar Islam jadi asyik",
                gradient = GradientCyanGreen,
                glowColor = CyanAccent
            )
            BenefitCard(
                emoji = "🏆",
                title = "Badge & Achievement",
                description = "Dapatkan reward karena istiqomah, bukan sekadar hadir",
                gradient = GradientGoldAmber,
                glowColor = GoldAccent
            )
        }

        Spacer(modifier = Modifier.height(36.dp))

        // ── Primary CTA (neon button) ──
        NeonStartButton(onStart = onStart)

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Tanpa gacha. Tanpa gambling. 100% fokus istiqomah.",
            fontSize = 11.sp,
            color = TextMuted,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun BenefitCard(
    emoji: String,
    title: String,
    description: String,
    gradient: List<Color>,
    glowColor: Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 12.dp,
                shape = RoundedCornerShape(18.dp),
                ambientColor = glowColor.copy(alpha = 0.2f),
                spotColor = glowColor.copy(alpha = 0.12f)
            )
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(gradient),
                shape = RoundedCornerShape(18.dp)
            )
            .background(
                brush = Brush.verticalGradient(GradientDarkSurface),
                RoundedCornerShape(18.dp)
            )
            .clip(RoundedCornerShape(18.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Emoji container with subtle gradient bg
        Box(
            modifier = Modifier
                .size(44.dp)
                .shadow(
                    elevation = 6.dp,
                    shape = RoundedCornerShape(12.dp),
                    ambientColor = glowColor.copy(alpha = 0.4f),
                    spotColor = glowColor.copy(alpha = 0.25f)
                )
                .background(
                    brush = Brush.radialGradient(
                        listOf(glowColor.copy(alpha = 0.25f), Color.Transparent)
                    ),
                    RoundedCornerShape(12.dp)
                )
                .border(
                    width = 1.dp,
                    color = glowColor.copy(alpha = 0.4f),
                    shape = RoundedCornerShape(12.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(text = emoji, fontSize = 24.sp)
        }

        Spacer(modifier = Modifier.width(14.dp))

        Column {
            Text(
                text = title,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight
            )
            Text(
                text = description,
                fontSize = 12.sp,
                color = TextMuted,
                lineHeight = 18.sp,
                modifier = Modifier.padding(top = 2.dp)
            )
        }
    }
}

@Composable
private fun NeonStartButton(onStart: () -> Unit) {
    Button(
        onClick = onStart,
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
            contentColor = Color.Black
        ),
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .shadow(
                elevation = 16.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = IslamicGreen.copy(alpha = 0.55f),
                spotColor = GoldAccent.copy(alpha = 0.3f)
            )
            .testTag("start_button"),
        contentPadding = PaddingValues(0.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.horizontalGradient(GradientGreenGold),
                    RoundedCornerShape(16.dp)
                )
                .border(
                    width = 1.dp,
                    brush = Brush.linearGradient(GradientGreenGold),
                    shape = RoundedCornerShape(16.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "MULAI JOURNEY",
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = Color.Black,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = Color.Black
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// STEP 2 — Create Character
// ═══════════════════════════════════════════════════════════════

@Composable
private fun CreateCharacterStep(
    username: String,
    onUsernameChange: (String) -> Unit,
    kota: String,
    onKotaChange: (String) -> Unit,
    intensityMode: String,
    onIntensityModeChange: (String) -> Unit,
    errorMsg: String,
    onBack: () -> Unit,
    onSubmit: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Back button
        Box(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "← Kembali",
                color = TextMuted,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(vertical = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Hero icon with rotating ring
        Box(
            modifier = Modifier
                .size(90.dp)
                .drawBehind {
                    val radius = size.minDimension / 2f
                    val center = Offset(size.width / 2f, size.height / 2f)
                    drawCircle(
                        brush = Brush.radialGradient(
                            listOf(GoldAccent.copy(alpha = 0.3f), Color.Transparent),
                            center = center,
                            radius = radius * 1.2f
                        ),
                        center = center,
                        radius = radius * 1.2f
                    )
                    drawCircle(
                        color = GoldAccent.copy(alpha = 0.4f),
                        radius = radius * 1.05f,
                        center = center,
                        style = Stroke(width = 1.5.dp.toPx())
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .shadow(
                        elevation = 14.dp,
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = GoldAccent.copy(alpha = 0.4f),
                        spotColor = GoldAccent.copy(alpha = 0.25f)
                    )
                    .background(
                        brush = Brush.verticalGradient(GradientDarkSurface),
                        RoundedCornerShape(20.dp)
                    )
                    .border(
                        width = 1.5.dp,
                        brush = Brush.linearGradient(GradientGoldAmber),
                        shape = RoundedCornerShape(20.dp)
                    )
                    .clip(RoundedCornerShape(20.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = GoldAccent,
                    modifier = Modifier.size(32.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "BUAT KARAKTER-MU",
            fontSize = 24.sp,
            fontWeight = FontWeight.ExtraBold,
            color = GoldAccent,
            letterSpacing = 1.sp,
            textAlign = TextAlign.Center
        )

        Text(
            text = "Siapa nama karakter yang akan naik level bareng kamu?",
            fontSize = 13.sp,
            color = TextMuted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 6.dp, bottom = 24.dp)
        )

        // ── Form card with neon gradient border ──
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(
                    elevation = 16.dp,
                    shape = RoundedCornerShape(24.dp),
                    ambientColor = IslamicGreen.copy(alpha = 0.2f),
                    spotColor = IslamicGreen.copy(alpha = 0.12f)
                )
                .border(
                    width = 1.dp,
                    brush = Brush.linearGradient(GradientGreenGold),
                    shape = RoundedCornerShape(24.dp)
                )
                .background(
                    brush = Brush.verticalGradient(GradientDarkSurface),
                    RoundedCornerShape(24.dp)
                )
                .clip(RoundedCornerShape(24.dp))
                .testTag("onboarding_card")
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                // Username
                Text(
                    text = "Nickname Gamer",
                    color = TextLight,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 6.dp)
                )
                OutlinedTextField(
                    value = username,
                    onValueChange = onUsernameChange,
                    placeholder = { Text("Contoh: Solihin_Mythic", color = TextMuted) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = TextLight,
                        unfocusedTextColor = TextLight,
                        focusedBorderColor = IslamicGreen,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedContainerColor = DarkBackground,
                        unfocusedContainerColor = DarkBackground
                    ),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("username_input"),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(16.dp))

                // City
                Text(
                    text = "Kota Asal (untuk Jadwal Sholat)",
                    color = TextLight,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 6.dp)
                )
                CityDropdownPicker(
                    value = kota,
                    onValueChange = onKotaChange,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("kota_input")
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Intensity mode chooser
                Text(
                    text = "Pilih Mode Leveling",
                    color = TextLight,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("santai", "standar", "sultan").forEach { mode ->
                        val isSelected = intensityMode == mode
                        val displayName = when (mode) {
                            "santai" -> "Santai"
                            "standar" -> "Standar"
                            "sultan" -> "Sultan"
                            else -> mode
                        }
                        val modeColor = when (mode) {
                            "santai" -> RingBlue
                            "standar" -> IslamicGreen
                            "sultan" -> GoldAccent
                            else -> IslamicGreen
                        }
                        val modeGradient = when (mode) {
                            "santai" -> GradientBlueCyan
                            "standar" -> GradientGreenGold
                            "sultan" -> GradientGoldAmber
                            else -> GradientGreenGold
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .then(
                                    if (isSelected) Modifier
                                        .shadow(
                                            elevation = 8.dp,
                                            shape = RoundedCornerShape(12.dp),
                                            ambientColor = modeColor.copy(alpha = 0.45f),
                                            spotColor = modeColor.copy(alpha = 0.25f)
                                        )
                                    else Modifier
                                )
                                .clip(RoundedCornerShape(12.dp))
                                .background(
                                    if (isSelected)
                                        Brush.radialGradient(
                                            listOf(modeColor.copy(alpha = 0.25f), DarkBackground)
                                        )
                                    else
                                        Brush.verticalGradient(GradientDarkSurface)
                                )
                                .border(
                                    width = if (isSelected) 2.dp else 1.dp,
                                    brush = if (isSelected) Brush.linearGradient(modeGradient)
                                    else Brush.linearGradient(listOf(DarkSurfaceVariant, DarkSurfaceVariant)),
                                    shape = RoundedCornerShape(12.dp)
                                )
                                .clickable { onIntensityModeChange(mode) }
                                .padding(vertical = 12.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = displayName,
                                fontWeight = FontWeight.Bold,
                                color = if (isSelected) modeColor else TextLight,
                                fontSize = 14.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Mode description box
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.verticalGradient(listOf(DarkBackground, DarkSurfaceVariant)),
                            RoundedCornerShape(12.dp)
                        )
                        .border(
                            width = 1.dp,
                            color = DarkSurfaceVariant,
                            shape = RoundedCornerShape(12.dp)
                        )
                        .padding(12.dp)
                ) {
                    val description = when (intensityMode) {
                        "santai" -> "🔴 Ring Wajib: 3 sholat pilihanmu (default Subuh, Maghrib, Isya). Sholat lain tetep dapet XP bonus!"
                        "standar" -> "🔴 Ring Wajib: 5 sholat + 🟢 Ring Sunnah aktif. Balance ibadah wajib & sunnah!"
                        "sultan" -> "🔴 Ring Wajib: 5 sholat + 🟢 Ring Sunnah aktif. Mode gamer Muslim sejati! 🔥"
                        else -> ""
                    }
                    Text(
                        text = description,
                        fontSize = 11.sp,
                        color = TextLight.copy(alpha = 0.8f),
                        lineHeight = 16.sp
                    )
                }

                if (errorMsg.isNotEmpty()) {
                    Text(
                        text = errorMsg,
                        color = RingRed,
                        fontSize = 12.sp,
                        modifier = Modifier.padding(top = 10.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Submit button (neon)
        Button(
            onClick = onSubmit,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .shadow(
                    elevation = 16.dp,
                    shape = RoundedCornerShape(16.dp),
                    ambientColor = IslamicGreen.copy(alpha = 0.55f),
                    spotColor = GoldAccent.copy(alpha = 0.3f)
                )
                .testTag("submit_button"),
            contentPadding = PaddingValues(0.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.horizontalGradient(GradientGreenGold),
                        RoundedCornerShape(16.dp)
                    )
                    .border(
                        width = 1.dp,
                        brush = Brush.linearGradient(GradientGreenGold),
                        shape = RoundedCornerShape(16.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "BUAT KARAKTER & MULAI",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = Color.Black,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        tint = Color.Black
                    )
                }
            }
        }
    }
}
