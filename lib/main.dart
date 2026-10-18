import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ZubixApp(),
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
          home: MainShell(state: _appState),
        );
      },
    );
  }
}
