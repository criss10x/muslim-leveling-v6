import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_leveling/screens/profil_tab.dart';
import 'package:muslim_leveling/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profil tab golden', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'nickname': 'Pejuang',
      'onboarding_done': true,
      'city_id': 'a1',
      'city_name': 'Jakarta',
      'avatar_path': '',
    });

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const ProfilTab(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(ProfilTab),
      matchesGoldenFile('goldens/profil_tab_phone.png'),
    );
  });
}
