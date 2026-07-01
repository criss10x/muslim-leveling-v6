import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/city_picker.dart';
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
  String? _cityId;
  String? _cityName;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final picked = await CityPicker.show(context);
    if (picked == null) return;
    setState(() {
      _cityId = picked.id;
      _cityName = picked.name;
    });
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
                      child: InkWell(
                        onTap: _pickCity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _cityName ?? 'Pilih kota/kabupaten...',
                                  style: AppText.bodyLg().copyWith(
                                    color: _cityName == null
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ),
                              const Icon(Icons.search, color: AppColors.primary, size: 20),
                            ],
                          ),
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
                      onPressed: _cityId == null || _nickname.text.trim().isEmpty
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_done', true);
                              await prefs.setString(
                                  'nickname', _nickname.text.trim());
                              await PrayerService.saveLocation(
                                  _cityId!, _cityName ?? '');
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
