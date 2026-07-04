import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Koordinat Ka'bah (Masjidil Haram, Makkah)
const _kaabaLat = 21.4225;
const _kaabaLon = 39.8262;

/// Koordinat kota-kota Indonesia (lat, lon)
const _cityCoords = <String, List<double>>{
  // Sumatera
  'Medan': [3.5952, 98.6722],
  'Padang': [-0.9471, 100.4172],
  'Pekanbaru': [0.5071, 101.4478],
  'Jambi': [-1.6101, 103.6131],
  'Palembang': [-2.9761, 104.7754],
  'Bengkulu': [-3.8004, 102.2655],
  'Bandar Lampung': [-5.3971, 105.2668],
  'Tanjung Pinang': [0.9186, 104.4558],
  // Jawa
  'Jakarta': [-6.2088, 106.8456],
  'Bandung': [-6.9175, 107.6191],
  'Semarang': [-6.9667, 110.4167],
  'Yogyakarta': [-7.7956, 110.3695],
  'Surabaya': [-7.2575, 112.7521],
  'Serang': [-6.1200, 106.1503],
  'Cirebon': [-6.7320, 108.5523],
  'Tegal': [-6.8694, 109.1402],
  'Pekalongan': [-6.8886, 109.6756],
  'Magelang': [-7.4705, 110.2175],
  'Solo': [-7.5755, 110.8243],
  'Malang': [-7.9666, 112.6326],
  'Bogor': [-6.5950, 106.8166],
  'Bekasi': [-6.2383, 106.9756],
  'Depok': [-6.4025, 106.7942],
  'Tangerang': [-6.1783, 106.6319],
  'Tangerang Selatan': [-6.2883, 106.7189],
  // Bali & Nusa Tenggara
  'Denpasar': [-8.6705, 115.2126],
  'Mataram': [-8.5833, 116.1167],
  'Kupang': [-10.1772, 123.6070],
  // Kalimantan
  'Pontianak': [-0.0263, 109.3425],
  'Palangka Raya': [-2.2096, 113.9108],
  'Banjarmasin': [-3.3186, 114.5944],
  'Samarinda': [-0.5022, 117.1536],
  'Tanjung Selor': [2.8500, 117.3667],
  // Sulawesi
  'Makassar': [-5.1477, 119.4327],
  'Palu': [-0.8917, 119.8707],
  'Kendari': [-3.9985, 122.5130],
  'Manado': [1.4748, 124.8421],
  'Gorontalo': [0.5435, 123.0568],
  // Maluku & Papua
  'Ambon': [-3.6954, 128.1814],
  'Sofifi': [0.7333, 127.5667],
  'Jayapura': [-2.5916, 140.6690],
  'Manokwari': [-0.8615, 134.0630],
};

/// Hitung arah kiblat (bearing) dari lokasi user ke Ka'bah.
/// @return bearing dalam derajat (0-360), di mana 0 = Utara
double _calculateQiblaBearing(double userLat, double userLon) {
  final lat1 = userLat * math.pi / 180;
  final lat2 = _kaabaLat * math.pi / 180;
  final dLon = (_kaabaLon - userLon) * math.pi / 180;

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  var bearing = math.atan2(y, x) * 180 / math.pi;
  bearing = (bearing + 360) % 360;
  return bearing;
}

/// Hitung jarak ke Ka'bah (km) — rumus Haversine
double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // radius bumi (km)
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

/// Cari koordinat kota berdasarkan nama — match flexible
List<double>? _findCityCoords(String cityName) {
  final lower = cityName.toLowerCase();
  // Exact match
  for (final entry in _cityCoords.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  // Contains match (mis. "Kota Denpasar" → "Denpasar")
  for (final entry in _cityCoords.entries) {
    if (lower.contains(entry.key.toLowerCase())) return entry.value;
  }
  // Reverse: city name contains the query
  for (final entry in _cityCoords.entries) {
    if (entry.key.toLowerCase().contains(lower)) return entry.value;
  }
  return null;
}

/// Qibla Screen — full screen compass dengan arrow ke Ka'bah
class QiblaScreen extends StatefulWidget {
  final String cityName;

  const QiblaScreen({super.key, required this.cityName});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double _azimuth = 0;
  bool _sensorAvailable = true;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  final List<double> _gravity = [0, 0, 0];
  final List<double> _geomagnetic = [0, 0, 0];
  bool _hasAccel = false;
  bool _hasMag = false;

  late final double _qiblaBearing;
  late final double _distance;

  @override
  void initState() {
    super.initState();
    final coords = _findCityCoords(widget.cityName) ?? [-6.2088, 106.8456];
    _qiblaBearing = _calculateQiblaBearing(coords[0], coords[1]);
    _distance = _haversineDistance(coords[0], coords[1], _kaabaLat, _kaabaLon);
    _initSensors();
  }

  void _initSensors() async {
    _accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      (event) {
        _gravity[0] = event.x;
        _gravity[1] = event.y;
        _gravity[2] = event.z;
        _hasAccel = true;
        _updateOrientation();
      },
      onError: (e) {
        if (mounted) setState(() => _sensorAvailable = false);
      },
    );

    _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      (event) {
        _geomagnetic[0] = event.x;
        _geomagnetic[1] = event.y;
        _geomagnetic[2] = event.z;
        _hasMag = true;
        _updateOrientation();
      },
      onError: (e) {
        if (mounted) setState(() => _sensorAvailable = false);
      },
    );
  }

  void _updateOrientation() {
    if (!_hasAccel || !_hasMag) return;

    // Hitung rotation matrix dari gravity + geomagnetic
    final r = _getRotationMatrix(_gravity, _geomagnetic);
    if (r == null) return;

    // Ekstrak azimuth dari rotation matrix
    final orientation = _getOrientation(r);
    var az = orientation[0] * 180 / math.pi;
    az = (az + 360) % 360;

    // ponytail: low-pass filter agar jarum kompas bergerak halus,
    // bukan lompat-lompat mengikuti setiap event sensor.
    if (mounted) {
      setState(() => _azimuth = _lerpAngle(_azimuth, az, 0.12));
    }
  }

  /// Interpolate compass angle across the 0/360 wrap-around.
  double _lerpAngle(double current, double target, double t) {
    final diff = (target - current + 180) % 360 - 180;
    return (current + diff * t + 360) % 360;
  }

  /// Port SensorManager.getRotationMatrix dari Android
  List<double>? _getRotationMatrix(List<double> g, List<double> m) {
    final ax = g[0], ay = g[1], az = g[2];
    final ex = m[0], ey = m[1], ez = m[2];

    // Normalize accelerometer
    final aNorm = math.sqrt(ax * ax + ay * ay + az * az);
    if (aNorm == 0) return null;
    final nx = ax / aNorm, ny = ay / aNorm, nz = az / aNorm;

    // H = E x A
    final hx = ey * nz - ez * ny;
    final hy = ez * nx - ex * nz;
    final hz = ex * ny - ey * nx;
    final hNorm = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (hNorm == 0) return null;
    final hnx = hx / hNorm, hny = hy / hNorm, hnz = hz / hNorm;

    // M = A x H
    final mx = ny * hnz - nz * hny;
    final my = nz * hnx - nx * hnz;
    final mz = nx * hny - ny * hnx;

    return [hnx, hny, hnz, mx, my, mz, nx, ny, nz];
  }

  /// Port SensorManager.getOrientation
  List<double> _getOrientation(List<double> r) {
    // r adalah 3x3 matrix (row-major)
    // r[0]=hnx, r[1]=hny, r[2]=hnz
    // r[3]=mx,  r[4]=my,  r[5]=mz
    // r[6]=nx,  r[7]=ny,  r[8]=nz
    final azimuth = math.atan2(r[1], r[4]); // arctan2(R[1], R[4])
    return [azimuth, 0, 0];
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relativeAngle = _qiblaBearing - _azimuth;
    final isAligned = (relativeAngle % 360).abs() < 5 || (relativeAngle % 360).abs() > 355;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🧭 Kompas Kiblat', style: AppText.titleLg()),
                        Text(
                          '📍 ${widget.cityName}',
                          style: AppText.bodyMd().copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_sensorAvailable)
              _sensorUnavailableCard()
            else
              Expanded(
                child: Center(
                  child: _compass(isAligned, relativeAngle),
                ),
              ),
            // Info cards
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _alignmentCard(isAligned, relativeAngle),
                  const SizedBox(height: AppSpacing.sm),
                  _bearingCard(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '💡 Kalibrasi kompas: putar perangkat dalam pola angka 8 beberapa kali untuk akurasi terbaik.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMd().copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compass(bool isAligned, double relativeAngle) {
    final compassColor = isAligned ? AppColors.primary : AppColors.secondaryFixed;
    final arrowColor = isAligned ? AppColors.primary : AppColors.tertiary;

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: compassColor.withValues(alpha: isAligned ? 0.35 : 0.15),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CompassPainter(
          azimuth: _azimuth,
          qiblaBearing: _qiblaBearing,
          isAligned: isAligned,
          compassColor: compassColor,
          arrowColor: arrowColor,
        ),
      ),
    );
  }

  Widget _sensorUnavailableCard() {
    return Expanded(
      child: Center(
        child: GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sensor Kompas Tidak Tersedia',
                  style: AppText.titleLg().copyWith(color: AppColors.tertiary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Perangkat ini tidak memiliki sensor magnetometer. Gunakan kalkulator arah kiblat di bawah ini sebagai alternatif.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Arah Kiblat dari ${widget.cityName}:', style: AppText.bodyMd()),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_qiblaBearing.toInt()}° dari Utara',
                  style: AppText.displayHero(36).copyWith(
                    color: AppColors.secondaryFixed,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '🌐 Jarak ke Ka\'bah: ${_distance.toStringAsFixed(0)} km',
                  style: AppText.bodyMd().copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Putar perangkat ${_qiblaBearing.toInt()}° searah jarum jam dari utara untuk menghadap kiblat.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alignmentCard(bool isAligned, double relativeAngle) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isAligned
          ? AppColors.primary.withValues(alpha: 0.5)
          : AppColors.outlineVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Text(isAligned ? '✅' : '🧭', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAligned ? 'Sudah Menghadap Kiblat!' : 'Arahkan Perangkat ke Kiblat',
                  style: AppText.titleLg().copyWith(
                    color: isAligned ? AppColors.primary : AppColors.onSurface,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Sudut: ${(relativeAngle % 360).toStringAsFixed(1)}° dari kiblat',
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bearingCard() {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arah Kiblat', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
              Text(
                '${_qiblaBearing.toInt()}°',
                style: AppText.displayHero(22).copyWith(
                  color: AppColors.secondaryFixed,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Jarak ke Ka\'bah', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
              Text(
                '${_distance.toStringAsFixed(0)} km',
                style: AppText.displayHero(22).copyWith(
                  color: AppColors.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter untuk kompas — port dari V3 QiblaComposable
class _CompassPainter extends CustomPainter {
  final double azimuth;
  final double qiblaBearing;
  final bool isAligned;
  final Color compassColor;
  final Color arrowColor;

  _CompassPainter({
    required this.azimuth,
    required this.qiblaBearing,
    required this.isAligned,
    required this.compassColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) - 20;

    // ─── Background circle ───
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.surfaceContainerHigh, AppColors.background],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius + 20));
    canvas.drawCircle(Offset(centerX, centerY), radius + 18, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = compassColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, centerY), radius + 18, borderPaint);

    // ─── Outer ring tick marks (0-360, every 30°) ───
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-azimuth * math.pi / 180);

    for (var i = 0; i < 360; i += 30) {
      final angle = (i - 90) * math.pi / 180;
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius;
      final endX = math.cos(angle) * (radius - 15);
      final endY = math.sin(angle) * (radius - 15);
      final isMain = i % 90 == 0;

      final tickPaint = Paint()
        ..color = isMain ? compassColor.withValues(alpha: 0.8) : AppColors.onSurfaceVariant.withValues(alpha: 0.5)
        ..strokeWidth = isMain ? 3 : 1.5;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // ─── Cardinal directions (N, E, S, W) ───
    final cardinals = [
      ('N', 0, compassColor),
      ('E', 90, AppColors.onSurfaceVariant),
      ('S', 180, AppColors.onSurfaceVariant),
      ('W', 270, AppColors.onSurfaceVariant),
    ];

    for (final (label, angle, color) in cardinals) {
      final radAngle = (angle - 90) * math.pi / 180;
      final textX = math.cos(radAngle) * (radius - 35);
      final textY = math.sin(radAngle) * (radius - 35);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(textX - tp.width / 2, textY - tp.height / 2));
    }
    canvas.restore();

    // ─── Inner circle ───
    final innerPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(centerX, centerY), radius - 50, innerPaint);

    // ─── Center Ka'bah icon ───
    final centerBgPaint = Paint()..color = compassColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(centerX, centerY), 30, centerBgPaint);

    final centerBorderPaint = Paint()
      ..color = compassColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, centerY), 20, centerBorderPaint);

    // ─── Qibla arrow ───
    final relativeAngle = qiblaBearing - azimuth;
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(relativeAngle * math.pi / 180);

    final arrowLength = radius - 55;

    // Arrow line
    final arrowPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, 10), Offset(0, -arrowLength), arrowPaint);

    // Arrow head (triangle)
    final headPath = Path()
      ..moveTo(0, -arrowLength - 5)
      ..lineTo(-12, -arrowLength + 18)
      ..lineTo(12, -arrowLength + 18)
      ..close();
    final headPaint = Paint()..color = arrowColor;
    canvas.drawPath(headPath, headPaint);

    // Small tail circle
    final tailPaint = Paint()..color = arrowColor.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(0, 10), 6, tailPaint);

    canvas.restore();

    // ─── Ka'bah emoji at arrow tip ───
    final tipRadAngle = (relativeAngle - 90) * math.pi / 180;
    final tipX = centerX + math.cos(tipRadAngle) * (radius - 80);
    final tipY = centerY + math.sin(tipRadAngle) * (radius - 80);

    final kaabaTp = TextPainter(
      text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    )..layout();
    kaabaTp.paint(canvas, Offset(tipX - kaabaTp.width / 2, tipY - kaabaTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.azimuth != azimuth || oldDelegate.isAligned != isAligned;
  }
}
