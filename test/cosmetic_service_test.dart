import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';
import 'package:muslim_leveling/services/cosmetic_service.dart';

void main() {
  test('migrateRewards maps legacy names to owned ids (idempotent)', () {
    final s = GameState(rewards: const ['Efek Aura Sultan', 'Pedang Sholat Mitik']);
    final migrated = CosmeticService.migrateRewards(s);
    expect(migrated.ownedCosmetics, containsAll(['aura_sultan', 'title_mythic_sword']));
    // Running again adds nothing new.
    final again = CosmeticService.migrateRewards(migrated);
    expect(again.ownedCosmetics.length, migrated.ownedCosmetics.length);
  });

  test('equip free owned succeeds', () {
    final s = GameState(ownedCosmetics: const ['aura_sultan']);
    final r = CosmeticService.equip(s, slot: CosmeticSlot.aura, id: 'aura_sultan', isPro: false);
    expect(r, isNotNull);
    expect(r!.equipped['aura'], 'aura_sultan');
  });

  test('equip free NOT owned is rejected', () {
    final s = GameState();
    final r = CosmeticService.equip(s, slot: CosmeticSlot.aura, id: 'aura_sultan', isPro: false);
    expect(r, isNull);
  });

  test('equip pro without entitlement is rejected; with entitlement succeeds', () {
    final s = GameState();
    expect(CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'shield_classic', isPro: false), isNull);
    final r = CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'shield_classic', isPro: true);
    expect(r, isNotNull);
    expect(r!.equipped['frame'], 'shield_classic');
  });

  test('default cosmetics are always allowed (no ownership needed)', () {
    final s = GameState();
    final r = CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'frame_default', isPro: false);
    expect(r, isNotNull);
  });

  test('resolveSlot falls back to default when pro item not entitled', () {
    final s = GameState(equipped: const {'frame': 'shield_classic'});
    expect(CosmeticService.resolveSlot(s, CosmeticSlot.frame, isPro: false), 'frame_default');
    expect(CosmeticService.resolveSlot(s, CosmeticSlot.frame, isPro: true), 'shield_classic');
  });

  test('reconcileLapse clears pro-equipped slots but keeps free ones', () {
    final s = GameState(
      ownedCosmetics: const ['title_crescent'],
      equipped: const {'frame': 'shield_classic', 'title': 'title_crescent'},
    );
    final r = CosmeticService.reconcileLapse(s, isPro: false);
    expect(r.equipped.containsKey('frame'), isFalse); // pro removed
    expect(r.equipped['title'], 'title_crescent');    // free kept
  });
}
