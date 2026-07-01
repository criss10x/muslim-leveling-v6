import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/prayer_service.dart';
import 'dashboard_shell.dart';

/// Character creation form — nickname + city, with hero CTA.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _nickname = TextEditingController();
  String? _city;
  // ponytail: hardcoded presets mapped to myquran v3 city IDs.
  // Profile uses the same PrayerService keys, so this keeps form & profile in sync.
  final _cities = const {
    'Jakarta': "58a2fc6ed39fd083f55d4182bf88826d",
    'Bandung': "fc221309746013ac554571fbd180e1c8",
    'Surabaya': "4734ba6f3de83d861c3176a6273cac6d",
    'Malang': "06138bc5af6023646ede0e1f7c1eac75",
    'Semarang': "74db120f0a8e5646ef5a30154e9f6deb",
  };

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AmbientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _header(),
                    const SizedBox(height: AppSpacing.xl),
                    _field(
                      label: 'Nickname Gamer',
                      icon: Icons.person_outline,
                      child: TextField(
                        controller: _nickname,
                        style: AppText.bodyLg(),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan Nickname',
                          hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _field(
                      label: 'Kota Asal',
                      icon: Icons.location_on_outlined,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _city,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceContainer,
                          icon: const Icon(
                            Icons.expand_more,
                            color: AppColors.outline,
                          ),
                          style: AppText.bodyLg().copyWith(
                            color: _city == null
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Pilih Kota...'),
                            ),
                            ..._cities.entries.map(
                              (e) => DropdownMenuItem<String>(
                                value: e.value,
                                child: Text(e.key),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _city = v),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        '*Untuk menyesuaikan jadwal sholat harian',
                        style: AppText.bodyMd().copyWith(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    HeroButton(
                      label: 'SIMPAN & LANJUT',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _city == null || _nickname.text.trim().isEmpty
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final cityName = _cities.entries
                                  .firstWhere((e) => e.value == _city)
                                  .key;
                              await prefs.setBool('onboarding_done', true);
                              await prefs.setString(
                                  'nickname', _nickname.text.trim());
                              await PrayerService.saveLocation(
                                  _city!, cityName);
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardShell(),
                                ),
                                (route) => false,
                              );
                            },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GhostButton(
                      label: 'Kembali',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [AppColors.primary, AppColors.tertiary],
          ).createShader(rect),
          child: Text(
            'BUAT KARAKTERMU',
            textAlign: TextAlign.center,
            style: AppText.displayHero(32).copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tentukan identitas perjalanan spiritualmu di alam Ascension.',
          textAlign: TextAlign.center,
          style: AppText.bodyMd().copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.labelCaps().copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.outline, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}
