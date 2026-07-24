import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/screens/profil_tab.dart';
import 'package:muslim_leveling/widgets/cosmetic_locker.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Profil shows the cosmetic locker', (tester) async {
    await GameService.load();
    await EntitlementService.load();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilTab())));
    await tester.pumpAndSettle();
    expect(find.byType(CosmeticLocker), findsOneWidget);
  });
}
