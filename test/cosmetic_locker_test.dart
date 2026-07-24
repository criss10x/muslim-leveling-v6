import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/widgets/cosmetic_locker.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping an owned free cosmetic equips it', (tester) async {
    await GameService.load();
    await EntitlementService.load();
    await GameService.debugSeedOwned(['title_crescent']);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CosmeticLocker())));
    await tester.pumpAndSettle();

    // Switch to the Title tab, then tap the owned title.
    await tester.tap(find.text('Gelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulan Sabit Menyala'));
    await tester.pumpAndSettle();

    expect(GameService.current.equipped['title'], 'title_crescent');
  });
}
