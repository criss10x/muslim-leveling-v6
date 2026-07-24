import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/cosmetic_catalog.dart';
import '../services/cosmetic_service.dart';
import '../services/game_service.dart';
import '../services/entitlement_service.dart';
import '../screens/pro_paywall_screen.dart';

const _slotLabels = {
  CosmeticSlot.frame: 'Bingkai',
  CosmeticSlot.aura: 'Aura',
  CosmeticSlot.title: 'Gelar',
};

class CosmeticLocker extends StatefulWidget {
  const CosmeticLocker({super.key});
  @override
  State<CosmeticLocker> createState() => _CosmeticLockerState();
}

class _CosmeticLockerState extends State<CosmeticLocker> {
  CosmeticSlot _slot = CosmeticSlot.frame;

  @override
  void initState() {
    super.initState();
    GameService.stateVersion.addListener(_rebuild);
    EntitlementService.proStatus.addListener(_rebuild);
  }

  @override
  void dispose() {
    GameService.stateVersion.removeListener(_rebuild);
    EntitlementService.proStatus.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _onTap(Cosmetic c) async {
    final isPro = EntitlementService.isPro;
    if (c.access == CosmeticAccess.pro && !isPro) {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProPaywallScreen()));
      return;
    }
    await GameService.equipCosmetic(c.slot, c.id, isPro: isPro);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = EntitlementService.isPro;
    final state = GameService.current;
    final equippedId = CosmeticService.resolveSlot(state, _slot, isPro: isPro);
    final items = CosmeticCatalog.bySlot(_slot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slot tabs
        Row(
          children: CosmeticSlot.values.map((s) {
            final sel = s == _slot;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_slotLabels[s]!),
                selected: sel,
                onSelected: (_) => setState(() => _slot = s),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: items.map((c) {
            final allowed = CosmeticService.isAllowed(state, c.id, isPro: isPro);
            final locked = c.access == CosmeticAccess.pro && !isPro;
            final owned = allowed || CosmeticCatalog.isDefault(c.id);
            final selected = c.id == equippedId;
            return InkWell(
              onTap: () => _onTap(c),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: selected ? AppColors.tertiary : Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(locked ? '🔒' : c.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(c.name,
                        style: AppText.bodyMd().copyWith(
                          fontSize: 10,
                          color: owned ? AppColors.onSurface : AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
