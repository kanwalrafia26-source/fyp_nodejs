import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/splashScreen.dart';
import 'core/auth_service.dart';

// Global notifier for dark mode
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('KeyDownEvent is dispatched') ||
        msg.contains('_pressedKeys.containsKey')) {
      return;
    }
    FlutterError.presentError(details);
  };

  await AuthService.loadSavedSession();
  await AuthService.loadSavedDisplayName();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child) => MaterialApp(
        title: 'Speakora',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF290451)),
          fontFamily: 'Poppins',
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF290451),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0020),
          fontFamily: 'Poppins',
          brightness: Brightness.dark,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home':  (_) => const MainScreen(),
        },
      ),
    );
  }
}
