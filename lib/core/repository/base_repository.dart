import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// A generic offline repository. Every feature module (residents, bills,
/// complaints, visitors, vendors, staff, assets, etc.) reuses this instead
/// of hand-writing near-identical SQLite CRUD code per table.
class BaseRepository {
  BaseRepository(this.tableName);

  final String tableName;

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _db;
    final id = await db.insert(tableName, row);
    await AppDatabase.instance.logAction('create', entity: tableName, entityId: id);
    return id;
  }

  Future<int> update(int id, Map<String, dynamic> row) async {
    final db = await _db;
    final count = await db.update(tableName, row, where: 'id = ?', whereArgs: [id]);
    await AppDatabase.instance.logAction('update', entity: tableName, entityId: id);
    return count;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    final count = await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    await AppDatabase.instance.logAction('delete', entity: tableName, entityId: id);
    return count;
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAll({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await _db;
    return db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'id DESC',
    );
  }

  Future<int> count({String? where, List<Object?>? whereArgs}) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['COUNT(*) as c'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> sum(String column, {String? where, List<Object?>? whereArgs}) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['SUM($column) as s'],
      where: where,
      whereArgs: whereArgs,
    );
    final value = result.first['s'];
    return (value as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await _db;
    return db.rawQuery(sql, args);
  }
}
