import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/prayer_service.dart';

/// ponytail: shared city search dialog used by onboarding, jadwal, and profil.
/// Returns {id, name} or null if cancelled.
class CityPicker {
  static Future<({String id, String name})?> show(BuildContext context) async {
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> results = const [];
    bool loading = false;

    return showDialog<({String id, String name})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> search(String q) async {
            if (q.trim().length < 3) {
              setState(() => results = const []);
              return;
            }
            setState(() => loading = true);
            final r = await PrayerService.searchCities(q);
            setState(() {
              results = r;
              loading = false;
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerHigh,
            title: Text('Pilih Lokasi', style: AppText.titleLg()),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: AppText.bodyLg(),
                    decoration: InputDecoration(
                      hintText: 'Ketik nama kota/kab...',
                      hintStyle: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: search,
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else if (results.isEmpty && ctrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kota tidak ditemukan',
                        style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final c = results[i];
                          final name = c['lokasi'] as String? ?? '';
                          final id = c['id']?.toString() ?? '';
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on, color: AppColors.primary, size: 18),
                            title: Text(name, style: AppText.bodyMd()),
                            onTap: () => Navigator.pop(ctx, (id: id, name: name)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ],
          );
        },
      ),
    );
  }
}
