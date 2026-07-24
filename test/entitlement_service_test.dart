import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to not Pro', () async {
    await EntitlementService.load();
    expect(EntitlementService.isPro, isFalse);
  });

  test('setProDev(true) persists and notifies', () async {
    await EntitlementService.load();
    var fired = false;
    void listener() => fired = true;
    EntitlementService.proStatus.addListener(listener);

    await EntitlementService.setProDev(true);
    expect(EntitlementService.isPro, isTrue);
    expect(fired, isTrue);

    EntitlementService.proStatus.removeListener(listener);

    // Re-load from a fresh read simulates app restart with same prefs.
    await EntitlementService.load();
    expect(EntitlementService.isPro, isTrue);
  });
}
