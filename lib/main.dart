import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://8c85da22b45bf35c51d3df07dcca0096@o4511691396677632.ingest.de.sentry.io/4511691401330768';
      options.environment = const String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'production');
      options.release = const String.fromEnvironment('SENTRY_RELEASE', defaultValue: 'muslim-leveling@1.0.0+1');
      // Set to a lower value if you want more aggressive sampling
      options.tracesSampleRate = 0.1;
      options.profilesSampleRate = 0.1;
      options.attachScreenshot = true;
      options.debug = false;
    },
    appRunner: () async {
      // Init notification service early so scheduled reminders survive app restart
      await NotificationService.init();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
      runApp(const MuslimLevelingApp());
    },
  );
}

class MuslimLevelingApp extends StatelessWidget {
  const MuslimLevelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muslim Leveling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
