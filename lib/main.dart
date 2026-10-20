import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'screens/admin_gate.dart';
import 'screens/brand_portal_screen.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences fallback initialized for web: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }
  ApiService.restoreSessions();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZubixApp(),
    ),
  );
}

// Exact paths only. Anything else falls back to the consumer app at '/'.
const Set<String> webRoutes = {'/', '/admin', '/brands', '/brands/register'};

String normalizeWebRoute(String path) {
  var route = path.toLowerCase();
  if (route.length > 1 && route.endsWith('/')) {
    route = route.substring(0, route.length - 1);
  }
  return route;
}

String resolveWebRoute(String path) {
  final route = normalizeWebRoute(path);
  return webRoutes.contains(route) ? route : '/';
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

  String get _initialWebRoute => kIsWeb ? resolveWebRoute(Uri.base.path) : '/';

  Widget _screenForRoute(String route) {
    switch (route) {
      case '/admin':
        return AdminGate(state: _appState);
      case '/brands':
        return BrandPortalScreen(state: _appState, initialAuthView: 'gateway');
      case '/brands/register':
        return BrandPortalScreen(state: _appState, initialAuthView: 'register');
      default:
        return AuthGate(state: _appState);
    }
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
            final route = normalizeWebRoute(settings.name ?? '/');
            return MaterialPageRoute(
              builder: (_) => _screenForRoute(route),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
