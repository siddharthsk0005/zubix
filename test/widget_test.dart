import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zubix/main.dart';
import 'package:zubix/providers/auth_provider.dart';

void main() {
  testWidgets('Zubix app boots to the splash/auth gate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ZubixApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('ZUBIX'), findsWidgets);
  });
}
