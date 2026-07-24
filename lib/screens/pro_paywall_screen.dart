import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/entitlement_service.dart';

/// Pro subscription pitch. v1 uses a dev toggle to unlock; the real billing
/// (RevenueCat) purchase flow lands in a later billing-only project — wire it
/// where marked below.
class ProPaywallScreen extends StatelessWidget {
  const ProPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Muslim Leveling Pro', style: AppText.displayHero(20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Text('Buka semua skin premium',
                style: AppText.displayHero(22), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Perisai, aura, dan gelar eksklusif. Gaya baru untuk avatarmu — '
                'tanpa memengaruhi XP, streak, atau peringkatmu.',
                style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            // TODO(billing): replace with RevenueCat purchase in the billing project.
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.tertiary),
              onPressed: () async {
                await EntitlementService.setProDev(true);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Aktifkan Pro (dev)'),
            ),
          ],
        ),
      ),
    );
  }
}
