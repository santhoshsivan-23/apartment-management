import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apartment_management/app/theme/app_theme.dart';
import 'package:apartment_management/features/home/home_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HomeScreen renders adaptive navigation and tabs on mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify NavigationBar destinations exist (Mobile 4-tab bar)
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Modules'), findsOneWidget);
    expect(find.text('Billing'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);
  });

  testWidgets('HomeScreen renders wide sidebar on desktop/tablet layout', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify sidebar elements exist
    expect(find.text('AMS LOCAL'), findsOneWidget);
    expect(find.text('STANDALONE NODE'), findsOneWidget);
    expect(find.text('26 Modules'), findsOneWidget);
    expect(find.text('Maintenance Hub'), findsOneWidget);
  });
}
