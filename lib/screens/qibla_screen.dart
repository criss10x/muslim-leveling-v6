import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Interpolasi sudut lewat busur TERPENDEK (350°→10° lewat utara, bukan
/// muter balik 340°). Kunci kompas yang smooth tanpa "lompat" di 0/360.
double _lerpAngle(double a, double b, double t) {
  final diff = (b - a + 540) % 360 - 180;
  return (a + diff * t + 360) % 360;
}

/// Qibla Screen — kompas neon full screen dengan arrow ke Ka'bah.
class QiblaScreen extends StatefulWidget {
  final String cityName;

  const QiblaScreen({super.key, required this.cityName});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  /// Azimuth mentah hasil sensor (target), dan yang dirender (smoothed).
  double _targetAzimuth = 0;
  double _displayAzimuth = 0;
  bool _hasFix = false;
  bool _sensorAvailable = true;
  bool _wasAligned = false;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  final List<double> _gravity = [0, 0, 0];
  final List<double> _geomagnetic = [0, 0, 0];
  bool _hasAccel = false;
  bool _hasMag = false;

  late final double _qiblaBearing;
  late final double _distance;
  late final AnimationController _pulse;

  /// Low-pass sensor (0..1, kecil = makin halus tapi makin "berat").
  static const _sensorAlpha = 0.15;

  /// Kecepatan jarum mengejar target per event sensor.
  static const _needleLerp = 0.22;

  @override
  void initState() {
    super.initState();
    final coords = _findCityCoords(widget.cityName) ?? [-6.2088, 106.8456];
    _qiblaBearing = _calculateQiblaBearing(coords[0], coords[1]);
    _distance = _haversineDistance(coords[0], coords[1], _kaabaLat, _kaabaLon);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _initSensors();
  }

  void _initSensors() {
    _accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      (event) {
        // Low-pass filter — buang jitter frekuensi tinggi dari tangan.
        _gravity[0] += _sensorAlpha * (event.x - _gravity[0]);
        _gravity[1] += _sensorAlpha * (event.y - _gravity[1]);
        _gravity[2] += _sensorAlpha * (event.z - _gravity[2]);
        _hasAccel = true;
        _updateOrientation();
      },
      onError: (e) {
        if (mounted) setState(() => _sensorAvailable = false);
      },
    );

    _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      (event) {
        _geomagnetic[0] += _sensorAlpha * (event.x - _geomagnetic[0]);
        _geomagnetic[1] += _sensorAlpha * (event.y - _geomagnetic[1]);
        _geomagnetic[2] += _sensorAlpha * (event.z - _geomagnetic[2]);
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

    final r = _getRotationMatrix(_gravity, _geomagnetic);
    if (r == null) return;

    final orientation = _getOrientation(r);
    var az = orientation[0] * 180 / math.pi;
    az = (az + 360) % 360;
    _targetAzimuth = az;

    // Fix pertama: langsung snap biar gak muter dari 0. Setelahnya jarum
    // mengejar target lewat busur terpendek — gerakan jadi smooth.
    final next = _hasFix
        ? _lerpAngle(_displayAzimuth, _targetAzimuth, _needleLerp)
        : _targetAzimuth;
    _hasFix = true;

    // Skip repaint kalau pergeseran tak kasat mata (hemat frame).
    final delta = ((next - _displayAzimuth + 540) % 360 - 180).abs();
    if (delta < 0.05) return;

    if (!mounted) return;
    setState(() => _displayAzimuth = next);

    // Haptic + pulse saat masuk/keluar posisi sejajar kiblat.
    final aligned = _isAligned;
    if (aligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
      _pulse.repeat(reverse: true);
    } else if (!aligned && _wasAligned) {
      _pulse.stop();
      _pulse.value = 0;
    }
    _wasAligned = aligned;
  }

  /// Selisih sudut ke kiblat, dinormalisasi -180..180.
  double get _relativeAngle =>
      (_qiblaBearing - _displayAzimuth + 540) % 360 - 180;

  bool get _isAligned => _relativeAngle.abs() < 5;

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
    final azimuth = math.atan2(r[1], r[4]);
    return [azimuth, 0, 0];
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aligned = _isAligned;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Entrance(child: _header()),
              if (!_sensorAvailable)
                _sensorUnavailableCard()
              else ...[
                Expanded(
                  child: Center(
                    child: Entrance(
                      delay: const Duration(milliseconds: 120),
                      child: _compass(aligned),
                    ),
                  ),
                ),
                Entrance(
                  delay: const Duration(milliseconds: 200),
                  child: _turnHint(aligned),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Column(
                  children: [
                    Entrance(
                      delay: const Duration(milliseconds: 280),
                      child: _alignmentCard(aligned),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Entrance(
                      delay: const Duration(milliseconds: 360),
                      child: _statChips(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '💡 Kalibrasi kompas: putar perangkat membentuk angka 8 beberapa kali untuk akurasi terbaik.',
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
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PressableScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KOMPAS KIBLAT',
                    style: AppText.labelCaps()
                        .copyWith(color: AppColors.primary, fontSize: 10)),
                const SizedBox(height: 2),
                Text('Arah Kiblat', style: AppText.displayHero(24)),
                Text(
                  '📍 ${widget.cityName} • ${_distance.toStringAsFixed(0)} km ke Ka\'bah',
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compass(bool aligned) {
    // Dial selalu mint (identitas app + logo). Jarum cyan saat mencari,
    // mengunci ke mint saat sejajar — pasangan mint/cyan = gradient logo.
    const compassColor = AppColors.primary;
    final arrowColor = aligned ? AppColors.primaryFixed : AppColors.tertiary;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => SizedBox(
        width: 300,
        height: 300,
        child: CustomPaint(
          painter: _CompassPainter(
            azimuth: _displayAzimuth,
            qiblaBearing: _qiblaBearing,
            isAligned: aligned,
            // 0..1 — menguatkan glow ring saat sejajar (pulse bernapas).
            glow: aligned ? 0.45 + 0.55 * _pulse.value : 0.0,
            compassColor: compassColor,
            arrowColor: arrowColor,
          ),
        ),
      ),
    );
  }

  /// Chip petunjuk arah putar — memberi tahu aksi konkret, bukan cuma angka.
  Widget _turnHint(bool aligned) {
    final rel = _relativeAngle;
    final degrees = rel.abs().round();
    final (label, color) = aligned
        ? ('🎯 Pas! Tahan posisi ini', AppColors.primary)
        : rel > 0
            ? ('Putar $degrees° ke kanan →', AppColors.tertiary)
            : ('← Putar $degrees° ke kiri', AppColors.tertiary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: aligned ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: aligned
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16)]
            : null,
      ),
      child: Text(
        label,
        style: AppText.titleLg().copyWith(color: color, fontSize: 14),
      ),
    );
  }

  Widget _sensorUnavailableCard() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GlassPanel(
            borderColor: AppColors.tertiary.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                    'Perangkat ini tidak memiliki sensor magnetometer. Gunakan panduan arah di bawah ini sebagai alternatif.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Arah Kiblat dari ${widget.cityName}:',
                      style: AppText.bodyMd()),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_qiblaBearing.toInt()}° dari Utara',
                    style: AppText.displayHero(36).copyWith(
                      color: AppColors.tertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Putar perangkat ${_qiblaBearing.toInt()}° searah jarum jam dari utara untuk menghadap kiblat.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alignmentCard(bool aligned) {
    final color = aligned ? AppColors.primary : AppColors.onSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: aligned
              ? [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.tertiary.withValues(alpha: 0.15)
                ]
              : [
                  AppColors.surfaceContainer,
                  AppColors.surfaceContainer.withValues(alpha: 0.6)
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: aligned
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: aligned
            ? [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20)
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              aligned ? '✅' : '🧭',
              key: ValueKey(aligned),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aligned
                      ? 'Sudah Menghadap Kiblat!'
                      : 'Arahkan Perangkat ke Kiblat',
                  style: AppText.titleLg().copyWith(color: color, fontSize: 15),
                ),
                Text(
                  'Selisih ${_relativeAngle.abs().toStringAsFixed(1)}° dari kiblat',
                  style: AppText.bodyMd().copyWith(
                      color: AppColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChips() {
    Widget chip(String label, String value, Color color) {
      return Expanded(
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          borderColor: color.withValues(alpha: 0.35),
          child: Column(
            children: [
              Text(label,
                  style: AppText.labelCaps().copyWith(
                      color: AppColors.onSurfaceVariant, fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.displayHero(20)
                    .copyWith(color: color, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('ARAH KIBLAT', '${_qiblaBearing.toInt()}°', AppColors.tertiary),
        const SizedBox(width: AppSpacing.sm),
        chip('JARAK KA\'BAH', '${_distance.toStringAsFixed(0)} km', AppColors.primary),
      ],
    );
  }
}

/// Custom painter kompas — dial neon bergaya tema app.
class _CompassPainter extends CustomPainter {
  final double azimuth;
  final double qiblaBearing;
  final bool isAligned;
  final double glow; // 0..1, ekstra glow saat sejajar (pulse)
  final Color compassColor;
  final Color arrowColor;

  _CompassPainter({
    required this.azimuth,
    required this.qiblaBearing,
    required this.isAligned,
    required this.glow,
    required this.compassColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    // Dial sengaja disusutkan: badge Ka'bah menempel di bezel, jadi cincin
    // luar butuh ruang bernapas yang sebelumnya tidak ada.
    final radius = math.min(centerX, centerY) - 30;
    final bezel = radius + 14;

    // ─── Background dial ───
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.surfaceContainerHigh,
          AppColors.background,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: bezel));
    canvas.drawCircle(center, bezel, bgPaint);

    // ─── Neon ring + glow (menguat saat sejajar) ───
    final glowPaint = Paint()
      ..color = compassColor.withValues(alpha: 0.20 + 0.5 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + 4 * glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, bezel, glowPaint);

    final borderPaint = Paint()
      ..color = compassColor.withValues(alpha: isAligned ? 0.85 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, bezel, borderPaint);

    // ─── Dial berputar: ticks + huruf mata angin ───
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-azimuth * math.pi / 180);

    for (var i = 0; i < 360; i += 15) {
      final isMain = i % 90 == 0;
      final isMid = i % 45 == 0;
      final angle = (i - 90) * math.pi / 180;
      final len = isMain ? 16.0 : (isMid ? 12.0 : 7.0);
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius;
      final endX = math.cos(angle) * (radius - len);
      final endY = math.sin(angle) * (radius - len);

      final tickPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..color = isMain
            ? compassColor.withValues(alpha: 0.9)
            : AppColors.onSurfaceVariant.withValues(alpha: isMid ? 0.55 : 0.3)
        ..strokeWidth = isMain ? 3 : 1.5;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // Huruf mata angin — N menonjol dengan glow.
    final cardinals = [
      ('N', 0, compassColor, true),
      ('E', 90, AppColors.onSurfaceVariant, false),
      ('S', 180, AppColors.onSurfaceVariant, false),
      ('W', 270, AppColors.onSurfaceVariant, false),
    ];

    for (final (label, angle, color, emphasize) in cardinals) {
      final radAngle = (angle - 90) * math.pi / 180;
      final textX = math.cos(radAngle) * (radius - 30);
      final textY = math.sin(radAngle) * (radius - 30);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: emphasize ? 18 : 15,
            fontWeight: FontWeight.bold,
            shadows: emphasize
                ? [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10)]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(textX - tp.width / 2, textY - tp.height / 2));
    }
    canvas.restore();

    // ─── Inner ring halus ───
    final innerPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 46, innerPaint);

    // ─── Jarum kiblat ───
    // Ujung berhenti sebelum cincin huruf mata angin; kepala dan batang
    // dijahit di satu titik (headBase) supaya tidak ada celah/tumpukan.
    final relativeAngle = qiblaBearing - azimuth;
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(relativeAngle * math.pi / 180);

    final tipY = -(radius - 52);
    const headLen = 22.0;
    final headBase = tipY + headLen;

    // Glow di belakang jarum
    final needleGlow = Paint()
      ..color = arrowColor.withValues(alpha: 0.35 + 0.35 * glow)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(const Offset(0, 16), Offset(0, tipY + 8), needleGlow);

    // Batang: gradient dari ekor transparan ke pangkal kepala
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [arrowColor.withValues(alpha: 0.22), arrowColor],
      ).createShader(Rect.fromLTRB(-3, tipY, 3, 16))
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Berhenti 4px DI DALAM kepala (−y = atas) supaya sambungannya tak berjahit.
    canvas.drawLine(Offset(0, 16), Offset(0, headBase - 4), needlePaint);

    // Kepala panah — duduk tepat di ujung batang
    final headPath = Path()
      ..moveTo(0, tipY)
      ..lineTo(-10, headBase)
      ..lineTo(10, headBase)
      ..close();
    canvas.drawPath(headPath, Paint()..color = arrowColor);

    // Ekor kecil
    canvas.drawCircle(
        const Offset(0, 16), 5, Paint()..color = arrowColor.withValues(alpha: 0.5));
    canvas.restore();

    // ─── Pusat: dot glassy ───
    canvas.drawCircle(
        center, 26, Paint()..color = compassColor.withValues(alpha: 0.12));
    canvas.drawCircle(
      center,
      16,
      Paint()
        ..color = compassColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 4, Paint()..color = compassColor);

    // ─── Badge Ka'bah di bezel ───
    // Ka'bah adalah arah geografis tetap, jadi tempatnya sebagai penanda
    // target di cincin luar — bukan menempel di batang jarum (dulu ia
    // digambar di radius-80, persis menimpa kepala panah).
    final markRad = (relativeAngle - 90) * math.pi / 180;
    final mx = centerX + math.cos(markRad) * bezel;
    final my = centerY + math.sin(markRad) * bezel;
    final mark = Offset(mx, my);

    canvas.drawCircle(
      mark,
      18,
      Paint()
        ..color = arrowColor.withValues(alpha: 0.18 + 0.3 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
        mark, 13, Paint()..color = AppColors.surfaceContainerHigh);
    canvas.drawCircle(
      mark,
      13,
      Paint()
        ..color = arrowColor.withValues(alpha: isAligned ? 0.95 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final kaabaTp = TextPainter(
      text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 15)),
      textDirection: TextDirection.ltr,
    )..layout();
    kaabaTp.paint(
        canvas, Offset(mx - kaabaTp.width / 2, my - kaabaTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.azimuth != azimuth ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.glow != glow ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.compassColor != compassColor;
  }
}
