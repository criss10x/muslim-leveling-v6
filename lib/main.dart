import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_sync.dart';
import 'services/auth_service.dart';

// ponytail: runApp dulu, init setelah — apapun error di init, UI tetap muncul
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MuslimLevelingApp());
  _initAsync();
}

Future<void> _initAsync() async {
  try {
    await Supabase.initialize(
      url: 'https://hiywlsqaurqvbwwuutbo.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpeXdsc3FhdXJxdmJ3d3V1dGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NTI3ODUsImV4cCI6MjA5OTIyODc4NX0.LDwpQooQKG5ehIENQ7qXPp1XJIkOq3BLXIUL2lOEfTw',
      // Deep link for browser OAuth fallback (see AuthService.redirectUrl).
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (_) {}

  try {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      final newId = '${_rand36()}-${_rand36()}-${_rand36()}';
      await prefs.setString('device_id', newId);
      SupabaseSync.init(newId);
    } else {
      SupabaseSync.init(deviceId);
    }
  } catch (_) {}

  try {
    final authed = await AuthService.init();
    if (authed) {
      final uid = AuthService.userId;
      if (uid != null) SupabaseSync.initWithUser(uid);
    }
  } catch (_) {}

  try {
    await NotificationService.init();
  } catch (_) {}

  try {
    // Default dark until ThemeNotifier.load(); toggle rebinds via theme_service.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColorsDark.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (_) {}

  SentryFlutter.init(
    (options) {
      options.dsn = 'https://8c85da...0096@o4511691396677632.ingest.de.sentry.io/4511691401330768';
      options.environment = const String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'production');
      options.release = const String.fromEnvironment('SENTRY_RELEASE', defaultValue: 'muslim-leveling@1.0.0+1');
      options.tracesSampleRate = 0.1;
      options.attachScreenshot = true;
      options.debug = false;
    },
    appRunner: () {},
  );
}

String _rand36() => BigInt.from(Random().nextInt(1 << 48)).toRadixString(36).padLeft(8, '0');

class MuslimLevelingApp extends StatefulWidget {
  const MuslimLevelingApp({super.key});
  @override
  State<MuslimLevelingApp> createState() => MuslimLevelingAppState();
}

class MuslimLevelingAppState extends State<MuslimLevelingApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Muslim Leveling',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeNotifier.mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
