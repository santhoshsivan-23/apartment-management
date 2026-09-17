import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apartment_management/app/app.dart';

void main() {
  setUpAll(() {
    // Allow sqflite to run inside the (non-mobile) test environment.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots to PIN setup on first run', (tester) async {
    await tester.pumpWidget(const ApartmentManagementApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Set up your PIN'), findsOneWidget);
  });
}
