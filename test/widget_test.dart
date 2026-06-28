// Basic smoke test — splash screen renders without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/main.dart';

void main() {
  testWidgets('App boots and shows splash', (tester) async {
    await tester.pumpWidget(const MuslimLevelingApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
