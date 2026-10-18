import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'screens/web_dashboard_screen.dart';
import 'screens/brand_partner_dashboard.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences fallback initialized for web: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ZubixApp(),
    ),
  );
}

class ZubixApp extends StatefulWidget {
  const ZubixApp({super.key});

  @override
  State<ZubixApp> createState() => _ZubixAppState();
}

class _ZubixAppState extends State<ZubixApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  String get _initialWebRoute {
    if (!kIsWeb) return '/';
    final uri = Uri.base;
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();

    if (path.contains('admin') || fragment.contains('admin') || uri.queryParameters.containsKey('admin')) {
      return '/admin';
    }
    if (path.contains('brand') || fragment.contains('brand') || uri.queryParameters.containsKey('brand') || uri.queryParameters.containsKey('brands')) {
      return '/brands';
    }
    return '/';
  }

  Widget _screenForRoute(String route) {
    if (route == '/admin') {
      return WebDashboardScreen(state: _appState);
    }
    if (route == '/brands') {
      return BrandPartnerDashboard(state: _appState);
    }
    return AuthGate(state: _appState);
  }

  @override
  Widget build(BuildContext context) {
    final initialRoute = _initialWebRoute;

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Zubix • Luxury Commerce & Partner Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _screenForRoute(initialRoute),
          onGenerateRoute: (settings) {
            final name = (settings.name ?? '').toLowerCase();
            if (name.contains('admin') || name.contains('dashboard')) {
              return MaterialPageRoute(
                builder: (_) => WebDashboardScreen(state: _appState),
                settings: settings,
              );
            }
            if (name.contains('brand')) {
              return MaterialPageRoute(
                builder: (_) => BrandPartnerDashboard(state: _appState),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (_) => AuthGate(state: _appState),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
