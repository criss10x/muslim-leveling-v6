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
import androidx.compose.material.icons.filled.LocationOn
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.IndonesianCities
import com.example.ui.components.CityDropdownPicker
import com.example.ui.theme.*

/**
 * Nur Quest onboarding — 2 step wizard per mockup:
 *   Step 0 — Welcome (⚡ MUSLIM LEVELING + 3 benefit cards + MULAI PETUALANGAN →)
 *   Step 1 — BUAT KARAKTERMU (form: nickname + kota + SIMPAN & LANJUT ➔ + ➔ KEMBALI)
 */
@Composable
fun OnboardingScreen(
    viewModel: com.example.viewmodel.GameViewModel,
    onComplete: (String, String, String) -> Unit
) {
    var currentStep by remember { mutableStateOf(0) }
    var username by remember { mutableStateOf("") }
    var kota by remember { mutableStateOf("KOTA DENPASAR") }
    var kotaId by remember { mutableStateOf("6a9aeddfc689c1d0e3b9ccc3ab651bc5") }
    var errorMsg by remember { mutableStateOf("") }

    val scrollState = rememberScrollState()

    // Load daftar kota dari KEMENAG saat onboarding dibuka
    LaunchedEffect(Unit) {
        viewModel.loadCitiesFromKemenag()
    }
    val cities by viewModel.kemenagCities.collectAsState()
    val isLoadingCities by viewModel.isLoadingCities.collectAsState()

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
                // Slow-rotating conic-like ambient beam
                val center = Offset(size.width / 2f, size.height * 0.25f)
                drawCircle(
                    brush = Brush.sweepGradient(
                        colors = listOf(
                            IslamicGreen.copy(alpha = 0.04f),
                            Color.Transparent,
                            CyanAccent.copy(alpha = 0.03f),
                            Color.Transparent,
                            IslamicGreen.copy(alpha = 0.04f)
                        )
                    ),
                    radius = size.width * 0.9f,
                    center = center
                )
            }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = 20.dp)
                .padding(top = 40.dp, bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    fadeIn(tween(300)) togetherWith fadeOut(tween(300))
                },
                label = "step_transition"
            ) { step ->
                when (step) {
                    0 -> WelcomeStep(
                        onStart = { currentStep = 1 }
                    )
                    1 -> CreateCharacterStep(
                        username = username,
                        onUsernameChange = { username = it; errorMsg = "" },
                        kota = kota,
                        onKotaChange = { kota = it },
                        kotaId = kotaId,
                        onKotaIdChange = { kotaId = it },
                        cities = cities,
                        isLoadingCities = isLoadingCities,
                        errorMsg = errorMsg,
                        onBack = { currentStep = 0 },
                        onSubmit = {
                            if (username.isBlank()) {
                                errorMsg = "Nickname tidak boleh kosong"
                            } else {
                                onComplete(username, kota, kotaId)
                            }
                        }
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// STEP 0 — WELCOME
// ⚡ MUSLIM LEVELING (cyan) + 3 benefit cards + MULAI PETUALANGAN →
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

        // ── Hero Logo: ⚡ in rounded box with rotating ring ──
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
                .size(120.dp)
                .drawBehind {
                    val radius = size.minDimension / 2f
                    val center = Offset(size.width / 2f, size.height / 2f)

                    // Pulsing radial glow
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                CyanAccent.copy(alpha = pulse * 0.35f),
                                Color.Transparent
                            ),
                            center = center,
                            radius = radius * 1.3f
                        ),
                        center = center,
                        radius = radius * 1.3f
                    )

                    // Rotating gradient arc
                    drawArc(
                        brush = Brush.sweepGradient(
                            colors = listOf(
                                Color.Transparent,
                                CyanAccent,
                                IslamicGreen,
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
                    .size(88.dp)
                    .shadow(
                        elevation = 18.dp,
                        shape = RoundedCornerShape(20.dp),
                        ambientColor = CyanAccent.copy(alpha = 0.5f),
                        spotColor = IslamicGreen.copy(alpha = 0.3f)
                    )
                    .background(
                        brush = Brush.verticalGradient(listOf(DarkSurface, DarkSurfaceElevated)),
                        RoundedCornerShape(20.dp)
                    )
                    .border(
                        width = 2.dp,
                        brush = Brush.linearGradient(listOf(CyanAccent, IslamicGreen)),
                        shape = RoundedCornerShape(20.dp)
                    )
                    .clip(RoundedCornerShape(20.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "⚡", fontSize = 40.sp)
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // ── MUSLIM LEVELING (white + cyan LEVELING) ──
        Text(
            text = "MUSLIM",
            fontSize = 32.sp,
            fontWeight = FontWeight.Black,
            color = TextLight,
            letterSpacing = 2.sp,
            textAlign = TextAlign.Center
        )
        Text(
            text = "LEVELING",
            fontSize = 32.sp,
            fontWeight = FontWeight.Black,
            color = CyanAccent,
            letterSpacing = 2.sp,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = "Fun way to 100% fokus istiqomah.",
            fontSize = 13.sp,
            color = TextMuted,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(36.dp))

        // ── 3 Benefit Cards (simple: emoji + title + arrow) ──
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            BenefitCard(
                emoji = "🕌",
                title = "Quest Sholat",
                gradient = listOf(IslamicGreen, IslamicGreen.copy(alpha = 0.3f))
            )
            BenefitCard(
                emoji = "📖",
                title = "Belajar yang Fun",
                gradient = listOf(CyanAccent, CyanAccent.copy(alpha = 0.3f))
            )
            BenefitCard(
                emoji = "🏆",
                title = "Badge & Achievement",
                gradient = listOf(GoldAccent, GoldAccent.copy(alpha = 0.3f))
            )
        }

        Spacer(modifier = Modifier.height(36.dp))

        // ── MULAI PETUALANGAN → button ──
        Button(
            onClick = onStart,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp)
                .shadow(
                    elevation = 14.dp,
                    shape = RoundedCornerShape(12.dp),
                    ambientColor = IslamicGreen.copy(alpha = 0.5f),
                    spotColor = CyanAccent.copy(alpha = 0.3f)
                )
                .testTag("start_button"),
            contentPadding = PaddingValues(0.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.horizontalGradient(listOf(IslamicGreen, CyanAccent)),
                        RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "MULAI PETUALANGAN",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = Color.Black,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "→",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }
        }
    }
}

@Composable
private fun BenefitCard(
    emoji: String,
    title: String,
    gradient: List<Color>
) {
    val cardShape = RoundedCornerShape(12.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(6.dp, cardShape, ambientColor = gradient.first().copy(alpha = 0.15f)),
        shape = cardShape,
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(
            width = 1.dp,
            brush = Brush.horizontalGradient(gradient)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left accent bar
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(32.dp)
                    .background(gradient.first(), RoundedCornerShape(100.dp))
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(text = emoji, fontSize = 24.sp)
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = ">",
                fontSize = 16.sp,
                color = gradient.first().copy(alpha = 0.6f),
                fontWeight = FontWeight.Bold
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// STEP 1 — BUAT KARAKTERMU
// Form: nickname + kota + SIMPAN & LANJUT ➔ + ➔ KEMBALI (ghost)
// ═══════════════════════════════════════════════════════════════

@Composable
private fun CreateCharacterStep(
    username: String,
    onUsernameChange: (String) -> Unit,
    kota: String,
    onKotaChange: (String) -> Unit,
    kotaId: String,
    onKotaIdChange: (String) -> Unit,
    cities: List<com.example.data.KemenagCity>,
    isLoadingCities: Boolean,
    errorMsg: String,
    onBack: () -> Unit,
    onSubmit: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // ── Ghost back button: ➔ KEMBALI ──
        Box(modifier = Modifier.fillMaxWidth()) {
            OutlinedButton(
                onClick = onBack,
                shape = RoundedCornerShape(10.dp),
                border = BorderStroke(1.dp, CyanAccent.copy(alpha = 0.5f)),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = CyanAccent
                ),
                modifier = Modifier.padding(vertical = 4.dp)
            ) {
                Text(text = "➔", fontSize = 14.sp)
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "KEMBALI",
                    fontFamily = FontFamily.Monospace,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // ── Title ──
        Text(
            text = "BUAT KARAKTERMU",
            fontSize = 26.sp,
            fontWeight = FontWeight.ExtraBold,
            color = CyanAccent,
            letterSpacing = 1.sp,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = "Tentukan identitas perjalanan spiritualmu di alam Ascension.",
            fontSize = 13.sp,
            color = TextMuted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(28.dp))

        // ── Form card ──
        val cardShape = RoundedCornerShape(16.dp)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(
                    elevation = 14.dp,
                    shape = cardShape,
                    ambientColor = IslamicGreen.copy(alpha = 0.18f)
                ),
            shape = cardShape,
            colors = CardDefaults.cardColors(containerColor = DarkSurface),
            border = BorderStroke(
                1.dp,
                Brush.linearGradient(listOf(IslamicGreen.copy(alpha = 0.4f), CyanAccent.copy(alpha = 0.2f)))
            )
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                // ── Nickname ──
                Text(
                    text = "NICKNAME GAMER",
                    fontFamily = FontFamily.Monospace,
                    color = CyanAccent,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                OutlinedTextField(
                    value = username,
                    onValueChange = onUsernameChange,
                    placeholder = { Text("Masukkan Nickname", color = TextMuted) },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = CyanAccent.copy(alpha = 0.6f),
                            modifier = Modifier.size(20.dp)
                        )
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = TextLight,
                        unfocusedTextColor = TextLight,
                        focusedBorderColor = CyanAccent,
                        unfocusedBorderColor = OutlineVariant,
                        focusedContainerColor = DarkBackground,
                        unfocusedContainerColor = DarkBackground
                    ),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("username_input"),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(16.dp))

                // ── Kota ──
                Text(
                    text = "KOTA ASAL",
                    fontFamily = FontFamily.Monospace,
                    color = CyanAccent,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                CityDropdownPicker(
                    value = kota,
                    onValueChange = onKotaChange,
                    onCitySelected = { selected -> onKotaIdChange(selected.id) },
                    cities = cities,
                    isLoading = isLoadingCities,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("kota_input")
                )

                Spacer(modifier = Modifier.height(6.dp))

                // Helper text
                Text(
                    text = "*Untuk menyesuaikan jadwal sholat harian",
                    fontSize = 10.sp,
                    color = TextMuted,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                )

                Spacer(modifier = Modifier.height(16.dp))

                if (errorMsg.isNotEmpty()) {
                    Text(
                        text = errorMsg,
                        color = RingRed,
                        fontSize = 12.sp,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // ── SIMPAN & LANJUT ➔ (primary) ──
        Button(
            onClick = onSubmit,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp)
                .shadow(
                    elevation = 14.dp,
                    shape = RoundedCornerShape(12.dp),
                    ambientColor = CyanAccent.copy(alpha = 0.5f)
                )
                .testTag("submit_button"),
            contentPadding = PaddingValues(0.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.horizontalGradient(listOf(CyanAccent, IslamicGreen)),
                        RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "SIMPAN & LANJUT",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = Color.Black,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "➔",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }
        }
    }
}
