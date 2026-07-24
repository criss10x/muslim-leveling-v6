import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/widgets/tier_avatar.dart';

void main() {
  testWidgets('avatar renders with a premium aura without throwing', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TierProfileAvatar(
        tierName: 'Warrior',
        equippedAuraId: 'aura_nur_emas',
        sizeDp: 80,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TierProfileAvatar), findsOneWidget);
  });

  testWidgets('aura_none adds no aura layer (no throw, Warrior has no tier particles)',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TierProfileAvatar(tierName: 'Warrior', sizeDp: 80),
    ));
    expect(find.byType(TierProfileAvatar), findsOneWidget);
  });
}
