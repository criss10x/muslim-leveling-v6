package com.example.ui.screens

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate as drawRotate
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import com.example.ui.theme.*
import kotlin.math.*

private val ArenaBorder = TextLight.copy(alpha = 0.08f)

// ═══════════════════════════════════════════════════════════════
// QIBLA COMPASS — Kompas Kiblat
// Sensor kompas Android + visual arrow menunjuk arah Ka'bah
// ═══════════════════════════════════════════════════════════════

// Koordinat Ka'bah (Masjidil Haram, Makkah)
private const val KAABA_LAT = 21.4225
private const val KAABA_LON = 39.8262

// Koordinat kota-kota Indonesia (lat, lon)
private val CITY_COORDS = mapOf(
    // Sumatera
    "Medan" to doubleArrayOf(3.5952, 98.6722),
    "Padang" to doubleArrayOf(-0.9471, 100.4172),
    "Pekanbaru" to doubleArrayOf(0.5071, 101.4478),
    "Jambi" to doubleArrayOf(-1.6101, 103.6131),
    "Palembang" to doubleArrayOf(-2.9761, 104.7754),
    "Bengkulu" to doubleArrayOf(-3.8004, 102.2655),
    "Bandar Lampung" to doubleArrayOf(-5.3971, 105.2668),
    "Tanjung Pinang" to doubleArrayOf(0.9186, 104.4558),
    // Jawa
    "Jakarta" to doubleArrayOf(-6.2088, 106.8456),
    "Bandung" to doubleArrayOf(-6.9175, 107.6191),
    "Semarang" to doubleArrayOf(-6.9667, 110.4167),
    "Yogyakarta" to doubleArrayOf(-7.7956, 110.3695),
    "Surabaya" to doubleArrayOf(-7.2575, 112.7521),
    "Serang" to doubleArrayOf(-6.1200, 106.1503),
    "Cirebon" to doubleArrayOf(-6.7320, 108.5523),
    "Tegal" to doubleArrayOf(-6.8694, 109.1402),
    "Pekalongan" to doubleArrayOf(-6.8886, 109.6756),
    "Magelang" to doubleArrayOf(-7.4705, 110.2175),
    "Solo" to doubleArrayOf(-7.5755, 110.8243),
    "Malang" to doubleArrayOf(-7.9666, 112.6326),
    "Bogor" to doubleArrayOf(-6.5950, 106.8166),
    "Bekasi" to doubleArrayOf(-6.2383, 106.9756),
    "Depok" to doubleArrayOf(-6.4025, 106.7942),
    "Tangerang" to doubleArrayOf(-6.1783, 106.6319),
    "Tangerang Selatan" to doubleArrayOf(-6.2883, 106.7189),
    // Bali & Nusa Tenggara
    "Denpasar" to doubleArrayOf(-8.6705, 115.2126),
    "Mataram" to doubleArrayOf(-8.5833, 116.1167),
    "Kupang" to doubleArrayOf(-10.1772, 123.6070),
    // Kalimantan
    "Pontianak" to doubleArrayOf(-0.0263, 109.3425),
    "Palangka Raya" to doubleArrayOf(-2.2096, 113.9108),
    "Banjarmasin" to doubleArrayOf(-3.3186, 114.5944),
    "Samarinda" to doubleArrayOf(-0.5022, 117.1536),
    "Tanjung Selor" to doubleArrayOf(2.8500, 117.3667),
    // Sulawesi
    "Makassar" to doubleArrayOf(-5.1477, 119.4327),
    "Palu" to doubleArrayOf(-0.8917, 119.8707),
    "Kendari" to doubleArrayOf(-3.9985, 122.5130),
    "Manado" to doubleArrayOf(1.4748, 124.8421),
    "Gorontalo" to doubleArrayOf(0.5435, 123.0568),
    // Maluku & Papua
    "Ambon" to doubleArrayOf(-3.6954, 128.1814),
    "Sofifi" to doubleArrayOf(0.7333, 127.5667),
    "Jayapura" to doubleArrayOf(-2.5916, 140.6690),
    "Manokwari" to doubleArrayOf(-0.8615, 134.0630)
)

/**
 * Hitung arah kiblat (bearing) dari lokasi user ke Ka'bah.
 * Rumus: bearing = atan2(sin(Δlon)·cos(lat2), cos(lat1)·sin(lat2) − sin(lat1)·cos(lat2)·cos(Δlon))
 * @return bearing dalam derajat (0-360), di mana 0 = Utara
 */
private fun calculateQiblaDirection(userLat: Double, userLon: Double): Double {
    val lat1 = Math.toRadians(userLat)
    val lat2 = Math.toRadians(KAABA_LAT)
    val dLon = Math.toRadians(KAABA_LON - userLon)

    val y = sin(dLon) * cos(lat2)
    val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    var bearing = Math.toDegrees(atan2(y, x))
    bearing = (bearing + 360) % 360
    return bearing
}

/**
 * Hitung jarak ke Ka'bah (km) — rumus Haversine
 */
private fun haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
    val r = 6371.0 // radius bumi (km)
    val dLat = Math.toRadians(lat2 - lat1)
    val dLon = Math.toRadians(lon2 - lon1)
    val a = sin(dLat / 2) * sin(dLat / 2) +
        cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2)
    val c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return r * c
}

// ═══════════════════════════════════════════════════════════════
// QIBLA SCREEN — Full screen composable
// ═══════════════════════════════════════════════════════════════

@Composable
fun QiblaScreen(
    cityName: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current

    // Dapatkan koordinat kota
    val coords = CITY_COORDS[cityName]
    val userLat = coords?.get(0) ?: -6.2088 // default Jakarta
    val userLon = coords?.get(1) ?: 106.8456

    // Hitung arah kiblat & jarak
    val qiblaBearing = remember(userLat, userLon) { calculateQiblaDirection(userLat, userLon) }
    val distance = remember(userLat, userLon) { haversineDistance(userLat, userLon, KAABA_LAT, KAABA_LON) }

    // Sensor kompas
    val sensorManager = remember { context.getSystemService(Context.SENSOR_SERVICE) as SensorManager }
    val accelerometer = remember { sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) }
    val magnetometer = remember { sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) }

    var azimuth by remember { mutableFloatStateOf(0f) }
    var sensorAvailable by remember { mutableStateOf(true) }

    // Gravity & geomagnetic data buffers
    val gravity = remember { FloatArray(3) }
    val geomagnetic = remember { FloatArray(3) }
    val rotationMatrix = remember { FloatArray(9) }
    val orientation = remember { FloatArray(3) }
    var lastAccelUpdate = remember { false }
    var lastMagUpdate = remember { false }

    val sensorListener = remember {
        object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                when (event.sensor.type) {
                    Sensor.TYPE_ACCELEROMETER -> {
                        System.arraycopy(event.values, 0, gravity, 0, 3)
                        lastAccelUpdate = true
                    }
                    Sensor.TYPE_MAGNETIC_FIELD -> {
                        System.arraycopy(event.values, 0, geomagnetic, 0, 3)
                        lastMagUpdate = true
                    }
                }

                if (lastAccelUpdate && lastMagUpdate) {
                    val success = SensorManager.getRotationMatrix(
                        rotationMatrix, null, gravity, geomagnetic
                    )
                    if (success) {
                        SensorManager.getOrientation(rotationMatrix, orientation)
                        // orientation[0] = azimuth dalam radian, konversi ke derajat
                        var az = Math.toDegrees(orientation[0].toDouble()).toFloat()
                        az = (az + 360) % 360
                        azimuth = az
                    }
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
    }

    DisposableEffect(Unit) {
        sensorAvailable = accelerometer != null && magnetometer != null
        if (sensorAvailable) {
            sensorManager.registerListener(
                sensorListener, accelerometer, SensorManager.SENSOR_DELAY_UI
            )
            sensorManager.registerListener(
                sensorListener, magnetometer, SensorManager.SENSOR_DELAY_UI
            )
        }
        onDispose {
            sensorManager.unregisterListener(sensorListener)
        }
    }

    // Smooth rotation animation
    val animatedAzimuth by animateFloatAsState(
        targetValue = azimuth,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "azimuth"
    )

    // Sudut arrow relatif terhadap utara (qiblaBearing - azimuth)
    val relativeAngle = qiblaBearing.toFloat() - animatedAzimuth

    // Cek apakah sudah menghadap kiblat (toleransi ±5°)
    val isAligned = abs(relativeAngle % 360) < 5f || abs(relativeAngle % 360) > 355f

    Box(
        modifier = Modifier
            .fillMaxSize()
            .futuristicBackground()
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp)
                .padding(top = 28.dp, bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ─── Header ───
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(DarkSurface.copy(alpha = 0.6f))
                        .border(1.dp, ArenaBorder, CircleShape)
                        .clickable { onBack() },
                    contentAlignment = Alignment.Center
                ) {
                    Text("←", fontSize = 20.sp, color = TextLight)
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "🧭 Kompas Kiblat",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Black,
                        color = TextLight
                    )
                    Text(
                        text = "📍 $cityName",
                        fontSize = 11.sp,
                        color = IslamicGreen,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            if (!sensorAvailable) {
                // ─── Sensor not available ───
                Spacer(modifier = Modifier.height(60.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    border = androidx.compose.foundation.BorderStroke(1.dp, AmberFlame.copy(alpha = 0.4f))
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("⚠️", fontSize = 48.sp)
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Sensor Kompas Tidak Tersedia",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = AmberFlame,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Perangkat ini tidak memiliki sensor magnetometer. Gunakan kalkulator arah kiblat di bawah ini sebagai alternatif.",
                            fontSize = 12.sp,
                            color = TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 18.sp
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                        Text(
                            text = "Arah Kiblat dari $cityName:",
                            fontSize = 13.sp,
                            color = TextLight,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "${qiblaBearing.toInt()}° dari Utara",
                            fontSize = 36.sp,
                            fontWeight = FontWeight.Black,
                            color = GoldAccent,
                            fontFamily = FontFamily.Monospace
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "🌐 Jarak ke Ka'bah: ${"%,.0f".format(distance)} km",
                            fontSize = 12.sp,
                            color = IslamicGreen
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Putar perangkat ${qiblaBearing.toInt()}° searah jarum jam dari utara untuk menghadap kiblat.",
                            fontSize = 11.sp,
                            color = TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 16.sp
                        )
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            } else {
                // ─── Compass ───
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    QiblaCompass(
                        azimuth = animatedAzimuth,
                        qiblaBearing = qiblaBearing.toFloat(),
                        isAligned = isAligned,
                        modifier = Modifier.size(300.dp)
                    )
                }
            }

            // ─── Info cards ───
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Alignment status
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(
                            if (isAligned && sensorAvailable)
                                Brush.horizontalGradient(listOf(IslamicGreen.copy(alpha = 0.2f), GoldAccent.copy(alpha = 0.15f)))
                            else
                                Brush.horizontalGradient(listOf(DarkSurface, DarkSurface.copy(alpha = 0.6f)))
                        )
                        .border(
                            1.dp,
                            if (isAligned && sensorAvailable) IslamicGreen.copy(alpha = 0.5f) else ArenaBorder,
                            RoundedCornerShape(14.dp)
                        )
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (isAligned && sensorAvailable) "✅" else "🧭",
                        fontSize = 28.sp
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = if (isAligned && sensorAvailable) "Sudah Menghadap Kiblat!"
                                   else "Arahkan Perangkat ke Kiblat",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Black,
                            color = if (isAligned && sensorAvailable) IslamicGreen else TextLight
                        )
                        Text(
                            text = if (sensorAvailable)
                                "Sudut: ${"%.1f".format(relativeAngle % 360)}° dari kiblat"
                                   else "Gunakan kompas manual di atas",
                            fontSize = 11.sp,
                            color = TextMuted,
                            modifier = Modifier.padding(top = 2.dp)
                        )
                    }
                }

                // Qibla bearing info
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(DarkSurface.copy(alpha = 0.6f))
                        .border(1.dp, ArenaBorder, RoundedCornerShape(14.dp))
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Arah Kiblat",
                            fontSize = 11.sp,
                            color = TextMuted
                        )
                        Text(
                            text = "${qiblaBearing.toInt()}°",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black,
                            color = GoldAccent,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Jarak ke Ka'bah",
                            fontSize = 11.sp,
                            color = TextMuted
                        )
                        Text(
                            text = "${"%,.0f".format(distance)} km",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black,
                            color = IslamicGreen,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }

                // Tip
                Text(
                    text = "💡 Kalibrasi kompas: putar perangkat dalam pola angka 8 beberapa kali untuk akurasi terbaik.",
                    fontSize = 10.sp,
                    color = TextMuted,
                    textAlign = TextAlign.Center,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// QIBLA COMPASS — Visual kompas dengan arrow ke Ka'bah
// ═══════════════════════════════════════════════════════════════

@Composable
private fun QiblaCompass(
    azimuth: Float,
    qiblaBearing: Float,
    isAligned: Boolean,
    modifier: Modifier = Modifier
) {
    val compassColor = if (isAligned) IslamicGreen else GoldAccent
    val arrowColor = if (isAligned) IslamicGreen else AmberFlame

    Canvas(
        modifier = modifier
            .shadow(16.dp, CircleShape, ambientColor = compassColor.copy(alpha = 0.3f))
            .clip(CircleShape)
            .background(
                Brush.radialGradient(
                    listOf(DarkSurface, DarkBackground),
                    radius = 500f
                )
            )
            .border(2.dp, compassColor.copy(alpha = 0.4f), CircleShape)
    ) {
        val centerX = size.width / 2
        val centerY = size.height / 2
        val radius = min(centerX, centerY) - 20

        // ─── Outer ring tick marks (0-360, every 30°) ───
        drawRotate(azimuth) {
            for (i in 0 until 360 step 30) {
                val angle = Math.toRadians(i.toDouble() - 90)
                val startX = (centerX + cos(angle) * radius).toFloat()
                val startY = (centerY + sin(angle) * radius).toFloat()
                val endX = (centerX + cos(angle) * (radius - 15)).toFloat()
                val endY = (centerY + sin(angle) * (radius - 15)).toFloat()

                val isMain = i % 90 == 0
                drawLine(
                    color = if (isMain) compassColor.copy(alpha = 0.8f) else TextMuted.copy(alpha = 0.5f),
                    start = androidx.compose.ui.geometry.Offset(startX, startY),
                    end = androidx.compose.ui.geometry.Offset(endX, endY),
                    strokeWidth = if (isMain) 3f else 1.5f
                )
            }
        }

        // ─── Cardinal directions (N, E, S, W) ───
        drawRotate(azimuth) {
            val cardinals = listOf(
                "N" to 0, "E" to 90, "S" to 180, "W" to 270
            )
            cardinals.forEach { (label, angle) ->
                val radAngle = Math.toRadians((angle - 90).toDouble())
                val textX = (centerX + cos(radAngle) * (radius - 35)).toFloat()
                val textY = (centerY + sin(radAngle) * (radius - 35)).toFloat()

                drawIntoCanvas {
                    val paint = android.graphics.Paint().apply {
                        color = if (label == "N") android.graphics.Color.parseColor("#FFD700")
                                else android.graphics.Color.parseColor("#888888")
                        textAlign = android.graphics.Paint.Align.CENTER
                        textSize = 36f
                        isFakeBoldText = true
                    }
                    it.nativeCanvas.drawText(label, textX, textY + 12, paint)
                }
            }
        }

        // ─── Inner circle ───
        drawCircle(
            color = ArenaBorder.copy(alpha = 0.3f),
            radius = radius - 50,
            style = Stroke(width = 1f)
        )

        // ─── Center Ka'bah icon ───
        drawCircle(
            color = GoldAccent.copy(alpha = 0.15f),
            radius = 30f,
            center = androidx.compose.ui.geometry.Offset(centerX, centerY)
        )
        drawCircle(
            color = GoldAccent.copy(alpha = 0.5f),
            radius = 20f,
            center = androidx.compose.ui.geometry.Offset(centerX, centerY),
            style = Stroke(width = 2f)
        )

        // ─── Qibla arrow ───
        val relativeAngle = qiblaBearing - azimuth
        drawRotate(relativeAngle) {
            val arrowLength = radius - 55
            val arrowStart = 0f
            val arrowEnd = -arrowLength

            // Arrow line
            drawLine(
                color = arrowColor,
                start = androidx.compose.ui.geometry.Offset(centerX, centerY + arrowStart),
                end = androidx.compose.ui.geometry.Offset(centerX, centerY + arrowEnd),
                strokeWidth = 5f
            )

            // Arrow head (triangle)
            val headPath = androidx.compose.ui.graphics.Path().apply {
                moveTo(centerX, centerY + arrowEnd - 5)
                lineTo(centerX - 12, centerY + arrowEnd + 18)
                lineTo(centerX + 12, centerY + arrowEnd + 18)
                close()
            }
            drawPath(headPath, arrowColor)

            // Small tail circle
            drawCircle(
                color = arrowColor.copy(alpha = 0.6f),
                radius = 6f,
                center = androidx.compose.ui.geometry.Offset(centerX, centerY + 10)
            )
        }

        // ─── Ka'bah emoji at arrow tip ───
        val tipRadAngle = Math.toRadians((relativeAngle - 90).toDouble())
        val tipX = (centerX + cos(tipRadAngle) * (radius - 80)).toFloat()
        val tipY = (centerY + sin(tipRadAngle) * (radius - 80)).toFloat()
        drawIntoCanvas {
            val paint = android.graphics.Paint().apply {
                textSize = 32f
                textAlign = android.graphics.Paint.Align.CENTER
            }
            it.nativeCanvas.drawText("🕋", tipX, tipY + 12, paint)
        }
    }
}
