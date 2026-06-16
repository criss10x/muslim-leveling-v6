package com.example.ui.screens

import androidx.compose.animation.*
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
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
            .background(DarkBackground)
            .muslimPattern()
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header
            GameHeaderView(state, viewModel)

            Spacer(modifier = Modifier.height(8.dp))

            // ═══ RITUAL RINGS — Gaming Card ═══
            Text(
                text = "⚔ RITUAL RING HARIAN",
                fontSize = 11.sp,
                fontWeight = FontWeight.Black,
                color = IslamicGreen,
                letterSpacing = 2.sp,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Main rings card with glow border
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .shadow(
                        elevation = 16.dp,
                        shape = RoundedCornerShape(24.dp),
                        ambientColor = IslamicGreen.copy(alpha = 0.15f),
                        spotColor = IslamicGreen.copy(alpha = 0.1f)
                    ),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.2f))
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
                            // Center text with glow
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "$checkedTrackedWajibToday/$wajibDenominator",
                                    fontSize = 22.sp,
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

                        // Right side: Countdown
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(start = 20.dp)
                        ) {
                            val timer = getNextPrayerTimerInfo(state.prayerTimesCache.timings, checkedTrackedWajibToday, wajibDenominator)
                            Text(
                                text = timer.label,
                                fontSize = 12.sp,
                                color = TextMuted,
                                fontWeight = FontWeight.Medium
                            )
                            Text(
                                text = timer.duration,
                                fontSize = 32.sp,
                                fontWeight = FontWeight.Black,
                                color = GoldAccent,
                                letterSpacing = (-1).sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = timer.tagline,
                                fontSize = 10.sp,
                                color = IslamicGreen.copy(alpha = 0.9f),
                                lineHeight = 14.sp,
                                style = androidx.compose.ui.text.TextStyle(
                                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                                )
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Ring labels with neon dots
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RingLabelView(color = RingRed, name = "Wajib", value = "$checkedTrackedWajibToday/$wajibDenominator")
                        if (isSultanMode || isStandarMode) {
                            RingLabelView(color = RingGreen, name = "Sunnah", value = "$sunnahCount/8")
                        }
                        RingLabelView(color = RingBlue, name = "Tilawah", value = if (tilawahLogged) "Lengkap" else "Belum")
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
                Text(
                    text = "🕐 JADWAL SHOLAT HARI INI",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Black,
                    color = GoldAccent,
                    letterSpacing = 1.5.sp
                )
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
                    Text(
                        text = if (isSultanMode) "🌙 CHECKLIST SUNNAH (SULTAN)" else "🌙 CHECKLIST SUNNAH & RAWATIB",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        color = RingGreen,
                        letterSpacing = 1.5.sp
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
                Box(modifier = Modifier.weight(1f).height(1.dp).background(RingBlue.copy(alpha = 0.3f)))
                Text(
                    text = "📜 SIDE QUEST",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Black,
                    color = RingBlue,
                    letterSpacing = 2.sp
                )
                Box(modifier = Modifier.weight(1f).height(1.dp).background(RingBlue.copy(alpha = 0.3f)))
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
    val levelInfo = viewModel.getLevelInfo(state.user.xp)
    val rankTitle = viewModel.getRankTitle(levelInfo.level)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.weight(1f)
        ) {
            // Level badge with neon glow
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .shadow(
                        elevation = 8.dp,
                        shape = CircleShape,
                        ambientColor = IslamicGreen.copy(alpha = 0.4f),
                        spotColor = IslamicGreen.copy(alpha = 0.2f)
                    )
                    .background(
                        Brush.radialGradient(
                            colors = listOf(IslamicGreen.copy(alpha = 0.2f), DarkSurfaceVariant),
                            radius = 60f
                        ),
                        CircleShape
                    )
                    .border(2.dp, IslamicGreen, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "LV",
                    fontSize = 9.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = IslamicGreen,
                    letterSpacing = 0.5.sp
                )
                Text(
                    text = "${levelInfo.level}",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Black,
                    color = TextLight,
                    modifier = Modifier.offset(y = 10.dp)
                )
            }

            Column {
                Text(
                    text = rankTitle.uppercase(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = GoldAccent,
                    letterSpacing = 1.5.sp
                )
                Text(
                    text = state.user.username,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextLight
                )
            }
        }

        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "XP ${levelInfo.xpInCurrentLevel}/${levelInfo.xpNeededForNextLevel}",
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                color = IslamicGreen
            )
            Spacer(modifier = Modifier.height(4.dp))
            // Neon XP bar
            Box(
                modifier = Modifier
                    .width(100.dp)
                    .height(8.dp)
                    .clip(RoundedCornerShape(100.dp))
                    .background(XpBarTrack)
                    .shadow(4.dp, RoundedCornerShape(100.dp), ambientColor = IslamicGreen.copy(alpha = 0.3f))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(fraction = levelInfo.progress)
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(IslamicGreen, IslamicGreen.copy(alpha = 0.7f))
                            ),
                            RoundedCornerShape(100.dp)
                        )
                )
            }
        }
    }
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
            color = RingRed.copy(alpha = 0.08f),
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
                color = RingGreen.copy(alpha = 0.06f),
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
            color = RingBlue.copy(alpha = 0.06f),
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
        val heroGradient = Brush.linearGradient(
            colors = listOf(Color(0xFF00E68A), Color(0xFF004D31))
        )

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .shadow(
                    elevation = 20.dp,
                    shape = RoundedCornerShape(24.dp),
                    ambientColor = IslamicGreen.copy(alpha = 0.2f),
                    spotColor = IslamicGreen.copy(alpha = 0.15f)
                )
                .testTag("hero_streak_card_active"),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = Color.Transparent),
            border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.3f))
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
                                color = TextLight,
                                letterSpacing = (-1).sp
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "🏆 REKOR: ${hero.best} HARI",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = GoldAccent.copy(alpha = 0.9f),
                                letterSpacing = 0.7.sp
                            )
                        }

                        val freezeText = if (hero.freezeAvailable) "❄ FREEZE READY" else "COOLDOWN"
                        val freezeBgColor = if (hero.freezeAvailable) Color.Black.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f)

                        Box(
                            modifier = Modifier
                                .background(freezeBgColor, RoundedCornerShape(100.dp))
                                .border(BorderStroke(1.dp, if (hero.freezeAvailable) CyanAccent.copy(alpha = 0.5f) else Color.Transparent), RoundedCornerShape(100.dp))
                                .padding(horizontal = 12.dp, vertical = 6.dp)
                        ) {
                            Text(
                                text = freezeText,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = if (hero.freezeAvailable) CyanAccent else TextMuted
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Per-prayer streaks
                    Box(
                        modifier = Modifier
                            .background(Color.Black.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
                            .border(BorderStroke(1.dp, Color.White.copy(alpha = 0.08f)), RoundedCornerShape(16.dp))
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
    val borderStroke = when {
        isChecked -> BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.3f))
        isActive -> BorderStroke(2.dp, GoldAccent)
        else -> BorderStroke(1.dp, DarkSurfaceVariant)
    }

    val containerColor = when {
        isChecked -> IslamicGreen.copy(alpha = 0.08f)
        isActive -> DarkSurface
        else -> DarkSurface.copy(alpha = 0.7f)
    }

    val textColor = when {
        isChecked -> IslamicGreen.copy(alpha = 0.7f)
        isActive -> GoldAccent
        else -> TextLight
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .then(
                if (isActive) Modifier.shadow(
                    elevation = 8.dp,
                    shape = RoundedCornerShape(16.dp),
                    ambientColor = GoldAccent.copy(alpha = 0.2f),
                    spotColor = GoldAccent.copy(alpha = 0.1f)
                ) else Modifier
            )
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(16.dp))
            .testTag("prayer_card_${name.lowercase()}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .drawBehind {
                    if (isActive) {
                        drawCircle(
                            Brush.radialGradient(
                                listOf(GoldAccent.copy(alpha = 0.06f), Color.Transparent),
                                center = Offset(size.width * 0.15f, size.height * 0.5f),
                                radius = size.height * 1.5f
                            )
                        )
                    }
                }
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Checkbox with glow
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .then(
                            if (isChecked) Modifier.shadow(4.dp, RoundedCornerShape(8.dp), ambientColor = IslamicGreen.copy(alpha = 0.5f))
                            else if (isActive) Modifier.shadow(4.dp, RoundedCornerShape(8.dp), ambientColor = GoldAccent.copy(alpha = 0.3f))
                            else Modifier
                        )
                        .background(if (isChecked) IslamicGreen else Color.Transparent)
                        .border(
                            BorderStroke(
                                width = if (isChecked) 0.dp else 2.dp,
                                color = if (isActive) GoldAccent else DarkSurfaceVariant
                            ),
                            RoundedCornerShape(8.dp)
                        )
                        .clickable { onCheckedChange(!isChecked) },
                    contentAlignment = Alignment.Center
                ) {
                    if (isChecked) {
                        Text(
                            text = "✓",
                            color = Color.Black,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 14.sp
                        )
                    }
                }

                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = name,
                            fontSize = 15.sp,
                            fontWeight = if (isActive || isChecked) FontWeight.Bold else FontWeight.SemiBold,
                            color = textColor
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

            Text(
                text = time,
                fontSize = 13.sp,
                color = if (isActive) GoldAccent else TextMuted,
                fontWeight = if (isActive) FontWeight.Bold else FontWeight.Normal,
                fontFamily = FontFamily.Monospace
            )
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
    val cardBg = accentColor.copy(alpha = 0.05f)
    val cardBorder = accentColor.copy(alpha = 0.2f)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .then(
                if (!isClaimed) Modifier.shadow(6.dp, RoundedCornerShape(16.dp), ambientColor = accentColor.copy(alpha = 0.15f))
                else Modifier
            )
            .background(cardBg)
            .border(BorderStroke(1.dp, cardBorder), RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.weight(1f),
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
        isChecked -> BorderStroke(1.dp, RingGreen.copy(alpha = 0.3f))
        else -> BorderStroke(1.dp, DarkSurfaceVariant)
    }

    val containerColor = when {
        isChecked -> RingGreen.copy(alpha = 0.06f)
        else -> DarkSurface.copy(alpha = 0.7f)
    }

    val textColor = when {
        isChecked -> RingGreen.copy(alpha = 0.7f)
        else -> TextLight
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(containerColor)
            .border(borderStroke, RoundedCornerShape(16.dp))
            .testTag("sunnah_card_${id}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(22.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .then(
                            if (isChecked) Modifier.shadow(4.dp, RoundedCornerShape(6.dp), ambientColor = RingGreen.copy(alpha = 0.4f))
                            else Modifier
                        )
                        .background(if (isChecked) RingGreen else Color.Transparent)
                        .border(
                            BorderStroke(
                                width = if (isChecked) 0.dp else 2.dp,
                                color = DarkSurfaceVariant
                            ),
                            RoundedCornerShape(6.dp)
                        )
                        .clickable { onCheckedChange(!isChecked) },
                    contentAlignment = Alignment.Center
                ) {
                    if (isChecked) {
                        Text(
                            text = "✓",
                            color = Color.Black,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 12.sp
                        )
                    }
                }

                Column {
                    Text(
                        text = name,
                        fontSize = 14.sp,
                        fontWeight = if (isChecked) FontWeight.Normal else FontWeight.Bold,
                        color = textColor
                    )
                    Text(
                        text = desc,
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                }
            }
        }
    }
}
