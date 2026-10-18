import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Zubix',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: AuthGate(state: _appState),
        );
      },
    );
  }
}
