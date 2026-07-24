import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/screens/pro_paywall_screen.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('dev activate button flips Pro on', (tester) async {
    await EntitlementService.load();
    await tester.pumpWidget(const MaterialApp(home: ProPaywallScreen()));
    expect(EntitlementService.isPro, isFalse);

    await tester.tap(find.text('Aktifkan Pro (dev)'));
    await tester.pumpAndSettle();

    expect(EntitlementService.isPro, isTrue);
  });
}
