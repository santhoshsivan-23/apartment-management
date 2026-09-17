import '../repository/base_repository.dart';

/// Builds id -> label maps for foreign-key dropdowns (e.g. picking an
/// apartment when adding a resident) by querying the related table.
class OptionLoaders {
  static Future<Map<int, String>> load(String table, String labelColumn) async {
    final rows = await BaseRepository(table).getAll();
    return {for (final r in rows) r['id'] as int: '${r[labelColumn] ?? ''}'};
  }

  static Future<Map<int, String>> communities() => load('communities', 'name');
  static Future<Map<int, String>> buildings() => load('buildings', 'name');
  static Future<Map<int, String>> floors() => load('floors', 'name');
  static Future<Map<int, String>> apartments() => load('apartments', 'apartment_number');
  static Future<Map<int, String>> residents() => load('residents', 'name');
  static Future<Map<int, String>> vendors() => load('vendors', 'name');
  static Future<Map<int, String>> amenities() => load('amenities', 'name');
  static Future<Map<int, String>> staff() => load('staff', 'name');
  static Future<Map<int, String>> assets() => load('assets', 'name');
  static Future<Map<int, String>> maintenanceBills() => load('maintenance_bills', 'id');
  static Future<Map<int, String>> expenseCategories() => load('expense_categories', 'name');
  static Future<Map<int, String>> maintenanceCategories() => load('maintenance_categories', 'name');
  static Future<Map<int, String>> complaints() => load('complaints', 'title');
  static Future<Map<int, String>> visitors() => load('visitors', 'name');
}
