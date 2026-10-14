import 'package:flutter/material.dart';
import 'services/platform_service.dart';
import 'services/store.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});
  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  final store = StudioStore(AndroidService());
  bool ready = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await store.init();
      if (mounted) {
        setState(() {
          ready = true;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Impossible d’ouvrir le stockage local.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => MaterialApp(
      title: 'Icon Studio',
      debugShowCheckedModeBanner: false,
      theme: studioTheme(Brightness.light),
      darkTheme: studioTheme(Brightness.dark),
      themeMode: store.theme == 'dark'
          ? ThemeMode.dark
          : store.theme == 'light'
          ? ThemeMode.light
          : ThemeMode.system,
      home: ready
          ? (store.onboarded ? HomeScreen(store) : Onboarding(store))
          : Scaffold(
              body: Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!),
                          TextButton(
                            onPressed: _init,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
              ),
            ),
    ),
  );
}

ThemeData studioTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff007aff),
        brightness: brightness,
      ).copyWith(
        primary: const Color(0xff007aff),
        surface: dark ? const Color(0xff1c1c1e) : Colors.white,
        onSurface: dark ? const Color(0xfff5f5f7) : const Color(0xff1c1c1e),
        onSurfaceVariant: dark
            ? const Color(0xffaeaeb2)
            : const Color(0xff636366),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff000000)
        : const Color(0xfff2f2f7),
    fontFamily: 'sans-serif',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? Colors.black : const Color(0xfff2f2f7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: .12),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    sliderTheme: const SliderThemeData(trackHeight: 3),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .08),
    ),
  );
}
