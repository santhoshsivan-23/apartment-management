import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up the local SQLite database before the UI is shown.
  await AppDatabase.instance.database;
  runApp(const ApartmentManagementApp());
}
