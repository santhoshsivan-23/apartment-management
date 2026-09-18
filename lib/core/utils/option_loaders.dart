import '../database/app_database.dart';
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

  /// Ensures every building with total_floors > 0 has its floor rows generated,
  /// then returns a formatted mapping: id -> 'Building Name - Floor Name/Number'.
  static Future<Map<int, String>> floors({int? buildingId}) async {
    await syncFloorsForBuildings();
    final db = await AppDatabase.instance.database;
    final String query;
    final List<dynamic> args;
    if (buildingId != null) {
      query = '''
        SELECT f.id, f.floor_number, f.name, b.name as building_name
        FROM floors f
        LEFT JOIN buildings b ON f.building_id = b.id
        WHERE f.building_id = ?
        ORDER BY f.floor_number ASC
      ''';
      args = [buildingId];
    } else {
      query = '''
        SELECT f.id, f.floor_number, f.name, b.name as building_name
        FROM floors f
        LEFT JOIN buildings b ON f.building_id = b.id
        ORDER BY b.name ASC, f.floor_number ASC
      ''';
      args = [];
    }
    final rows = await db.rawQuery(query, args);
    return {
      for (final r in rows)
        r['id'] as int: _formatFloorLabel(
          r['building_name'] as String?,
          r['floor_number'] as int?,
          r['name'] as String?,
        ),
    };
  }

  static String _formatFloorLabel(String? buildingName, int? floorNumber, String? name) {
    final floorStr = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Floor ${floorNumber ?? 0}';
    return (buildingName != null && buildingName.trim().isNotEmpty)
        ? '$buildingName - $floorStr'
        : floorStr;
  }

  /// Automatically generates missing floor rows for buildings based on their total_floors.
  static Future<int> syncFloorsForBuildings() async {
    final db = await AppDatabase.instance.database;
    final buildings = await db.query('buildings');
    int generatedCount = 0;
    for (final b in buildings) {
      final bId = b['id'] as int;
      final totalFloors = (b['total_floors'] as int?) ?? 0;
      if (totalFloors > 0) {
        final existingFloors = await db.query(
          'floors',
          where: 'building_id = ?',
          whereArgs: [bId],
          orderBy: 'floor_number ASC',
        );
        final existingNumbers = existingFloors
            .map((e) => e['floor_number'] as int)
            .toSet();

        for (int f = 1; f <= totalFloors; f++) {
          if (!existingNumbers.contains(f)) {
            await db.insert('floors', {
              'building_id': bId,
              'floor_number': f,
              'name': 'Floor $f',
            });
            generatedCount++;
          }
        }
      }
    }
    return generatedCount;
  }
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
