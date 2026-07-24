import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('equipCosmetic persists to GameService.current', () async {
    await GameService.load();
    // Seed ownership through the reward-migration path.
    await GameService.debugSeedOwned(['aura_sultan']);
    final ok = await GameService.equipCosmetic(
        CosmeticSlot.aura, 'aura_sultan', isPro: false);
    expect(ok, isTrue);
    expect(GameService.current.equipped['aura'], 'aura_sultan');
  });

  test('equipCosmetic rejects a pro item when not entitled', () async {
    await GameService.load();
    final ok = await GameService.equipCosmetic(
        CosmeticSlot.frame, 'shield_classic', isPro: false);
    expect(ok, isFalse);
    expect(GameService.current.equipped.containsKey('frame'), isFalse);
  });
}
