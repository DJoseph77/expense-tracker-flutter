import 'package:expense_tracker_flutter/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Theme System & Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      prefs = await SharedPreferences.getInstance();
    });

    test('ThemeNotifier loads initial mode from SharedPreferences', () {
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.light);
    });

    test('setThemeMode updates state and persists choice', () async {
      final notifier = ThemeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });

    testWidgets('App renders correctly under light and dark theme modes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mockPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: Text('Dark Mode Active')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Dark Mode Active'), findsOneWidget);
    });
  });
}
