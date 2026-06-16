package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
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
    var username by remember { mutableStateOf("") }
    var kota by remember { mutableStateOf("Jakarta") }
    var intensityMode by remember { mutableStateOf("standar") } // santai, standar, sultan
    var errorMsg by remember { mutableStateOf("") }

    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .muslimPattern()
            .drawBehind {
                // Draw very subtle Islamic geometric lines in background
                val size = size
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
            Spacer(modifier = Modifier.height(20.dp))

            // Game Logo / Decorative Icon
            Box(
                modifier = Modifier
                    .size(96.dp)
                    .drawBehind {
                        drawCircle(
                            Brush.radialGradient(
                                colors = listOf(IslamicGreen.copy(alpha = 0.5f), Color.Transparent),
                                center = center,
                                radius = size.minDimension / 1.5f
                            )
                        )
                    }
                    .background(DarkSurface, RoundedCornerShape(24.dp))
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "🕌",
                    fontSize = 44.sp,
                    textAlign = TextAlign.Center
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Game Name Display Title
            Text(
                text = "MUSLIM LEVELING",
                fontSize = 28.sp,
                fontWeight = FontWeight.ExtraBold,
                color = IslamicGreen,
                letterSpacing = 2.sp,
                textAlign = TextAlign.Center
            )

            Text(
                text = "RPG Sholat Gacha Paling Istiqomah di Sini!",
                fontSize = 13.sp,
                color = GoldAccent,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp, bottom = 24.dp)
            )

            // Onboarding Card Panel
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
                    Text(
                        text = "BUAT KARAKTER-MU",
                        fontWeight = FontWeight.Bold,
                        color = GoldAccent,
                        fontSize = 16.sp,
                        letterSpacing = 1.sp,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    // Username Input
                    Text(
                        text = "Nickname Gamer:",
                        color = TextLight,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(bottom = 6.dp)
                    )
                    OutlinedTextField(
                        value = username,
                        onValueChange = { username = it },
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
                        text = "Kota Asal (untuk Jadwal Sholat):",
                        color = TextLight,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(bottom = 6.dp)
                    )
                    OutlinedTextField(
                        value = kota,
                        onValueChange = { kota = it },
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
                        text = "Pilih Mode Leveling:",
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
                                    .clickable { intensityMode = mode }
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

                    // Expand Mode explanation text Box
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(DarkBackground, RoundedCornerShape(12.dp))
                            .padding(12.dp)
                    ) {
                        val description = when (intensityMode) {
                            "santai" -> "🔴 Ring Wajib dari 3 sholat favoritmu (Default: Subuh, Maghrib, Isya). Sholat lain tetep dapet XP bonus!"
                            "standar" -> "🔴 Ring Wajib (5 sholat) + 🟢 Ring Sunnah aktif + 🔵 Ring Tilawah aktif. Balance ibadah wajib & sunnah!"
                            "sultan" -> "🔴 Ring Wajib (5 sholat) + 🟢 Ring Sunnah aktif + 🔵 Ring Tilawah aktif. Mode gamer Muslim sejati! 🔥"
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

            // Character Creation Button
            Button(
                onClick = {
                    if (username.trim().isEmpty()) {
                        errorMsg = "Oops! Nickname-nya jangan kosong ya 😅"
                    } else if (kota.trim().isEmpty()) {
                        errorMsg = "Masukin kota asalmu dulu biar jadwal sholatnya muncul!"
                    } else {
                        onComplete(username.trim(), intensityMode, kota.trim())
                    }
                },
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
                    text = "MULAI PETUALANGAN ISTIQOMAH 🎮",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = Color.Black
                )
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}
