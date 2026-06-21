package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*

@Composable
fun OnboardingScreen(
    onComplete: (String, String, String) -> Unit
) {
    var currentStep by remember { mutableStateOf(0) } // 0 = welcome, 1 = create character
    var username by remember { mutableStateOf("") }
    var kota by remember { mutableStateOf("Jakarta") }
    var intensityMode by remember { mutableStateOf("standar") }
    var errorMsg by remember { mutableStateOf("") }

    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .muslimPattern()
            .drawBehind {
                drawIslamicGeometricBackground()
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
                    0 -> WelcomeStep(
                        onStart = { currentStep = 1 }
                    )
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

        // Step indicator dots
        if (currentStep == 1) {
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                repeat(2) { index ->
                    Box(
                        modifier = Modifier
                            .size(if (index == currentStep) 24.dp else 8.dp, 8.dp)
                            .clip(CircleShape)
                            .background(
                                if (index == currentStep) IslamicGreen else DarkSurfaceVariant
                            )
                    )
                }
            }
        }
    }
}

@Composable
private fun WelcomeStep(
    onStart: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // Hero Logo with glowing ring
        Box(
            modifier = Modifier
                .size(120.dp)
                .drawBehind {
                    // Outer glow
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(IslamicGreen.copy(alpha = 0.3f), Color.Transparent),
                            center = center,
                            radius = size.minDimension / 1.2f
                        )
                    )
                    // Progress ring
                    drawCircle(
                        color = IslamicGreen.copy(alpha = 0.6f),
                        radius = size.minDimension / 2f,
                        style = Stroke(width = 3.dp.toPx())
                    )
                    drawArc(
                        color = GoldAccent,
                        startAngle = -90f,
                        sweepAngle = 270f,
                        useCenter = false,
                        style = Stroke(width = 3.dp.toPx())
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(96.dp)
                    .background(DarkSurface, RoundedCornerShape(28.dp))
                    .border(
                        BorderStroke(2.dp, IslamicGreen.copy(alpha = 0.5f)),
                        RoundedCornerShape(28.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "🌙",
                    fontSize = 52.sp,
                    textAlign = TextAlign.Center
                )
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // App name with stronger presence
        Text(
            text = "MUSLIM LEVELING",
            fontSize = 32.sp,
            fontWeight = FontWeight.ExtraBold,
            color = IslamicGreen,
            letterSpacing = 2.sp,
            textAlign = TextAlign.Center
        )

        Text(
            text = "QUSHO",
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = GoldAccent,
            letterSpacing = 8.sp,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // New tagline
        Text(
            text = "Level Up Iman, Level Up Kehidupanmu",
            fontSize = 18.sp,
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

        Spacer(modifier = Modifier.height(40.dp))

        // Benefit cards
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            BenefitItem(
                emoji = "🎯",
                title = "Quest Sholat Harian",
                description = "Tracking 5 waktu sholat dengan sistem XP & level"
            )
            BenefitItem(
                emoji = "📚",
                title = "Belajar Sambil Main",
                description = "16 modul + 80 quiz bikin belajar Islam jadi asyik"
            )
            BenefitItem(
                emoji = "🏆",
                title = "Badge & Achievement",
                description = "Dapatkan reward karena istiqomah, bukan sekadar hadir"
            )
        }

        Spacer(modifier = Modifier.height(40.dp))

        // Primary CTA
        Button(
            onClick = onStart,
            colors = ButtonDefaults.buttonColors(
                containerColor = IslamicGreen,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .testTag("start_button"),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = 6.dp)
        ) {
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
        Box(
            modifier = Modifier.fillMaxWidth()
        ) {
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

        // Hero icon
        Box(
            modifier = Modifier
                .size(80.dp)
                .background(DarkSurface, RoundedCornerShape(20.dp))
                .border(
                    BorderStroke(1.5.dp, GoldAccent.copy(alpha = 0.5f)),
                    RoundedCornerShape(20.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = GoldAccent,
                modifier = Modifier.size(40.dp)
            )
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

        // Form card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("onboarding_card"),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurface),
            border = BorderStroke(1.5.dp, IslamicGreen.copy(alpha = 0.5f)),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.Start
            ) {
                // Username Input
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

                // City Location
                Text(
                    text = "Kota Asal (untuk Jadwal Sholat)",
                    color = TextLight,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 6.dp)
                )
                OutlinedTextField(
                    value = kota,
                    onValueChange = onKotaChange,
                    placeholder = { Text("Ketik kota kamu...", color = TextMuted) },
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
                        .testTag("kota_input"),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Intensity Mode chooser
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

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(12.dp))
                                .background(if (isSelected) modeColor.copy(alpha = 0.25f) else DarkBackground)
                                .border(
                                    BorderStroke(
                                        if (isSelected) 2.dp else 1.dp,
                                        if (isSelected) modeColor else DarkSurfaceVariant
                                    ),
                                    RoundedCornerShape(12.dp)
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

                // Mode explanation text Box
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(DarkBackground, RoundedCornerShape(12.dp))
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

        // Submit button
        Button(
            onClick = onSubmit,
            colors = ButtonDefaults.buttonColors(
                containerColor = IslamicGreen,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .testTag("submit_button"),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = 6.dp)
        ) {
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

@Composable
private fun BenefitItem(
    emoji: String,
    title: String,
    description: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(DarkSurface, RoundedCornerShape(16.dp))
            .border(
                BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.2f)),
                RoundedCornerShape(16.dp)
            )
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = emoji,
            fontSize = 28.sp,
            modifier = Modifier.padding(end = 16.dp)
        )
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

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawIslamicGeometricBackground() {
    val pathColor = Color(0x1200A86B)
    val linesCount = 8
    for (i in 0..linesCount) {
        val x = size.width * (i.toFloat() / linesCount)
        drawLine(
            color = pathColor,
            start = Offset(x, 0f),
            end = Offset(size.width - x, size.height),
            strokeWidth = 1.5f
        )
        val y = size.height * (i.toFloat() / linesCount)
        drawLine(
            color = pathColor,
            start = Offset(0f, y),
            end = Offset(size.width, size.height - y),
            strokeWidth = 1.5f
        )
    }
}
