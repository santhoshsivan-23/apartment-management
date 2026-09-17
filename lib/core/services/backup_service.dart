import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

/// Local-only backup: copies the actual .db file to another folder on the
/// device (chosen by the user), or restores by copying a chosen .db file
/// back over the live database. No network is involved at any point.
class BackupService {
  Future<String> createBackup() async {
    final dbPath = await AppDatabase.instance.dbFilePath;
    final sourceFile = File(dbPath);
    if (!await sourceFile.exists()) {
      throw Exception('Database file not found yet — add some data first.');
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupDir.path, 'apartment_backup_$timestamp.db');
    await sourceFile.copy(backupPath);
    return backupPath;
  }

  Future<void> restoreFrom(String backupFilePath) async {
    await AppDatabase.instance.close();
    final dbPath = await AppDatabase.instance.dbFilePath;
    final backupFile = File(backupFilePath);
    await backupFile.copy(dbPath);
    // Reopen so the app immediately reflects the restored data.
    await AppDatabase.instance.database;
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!await backupDir.exists()) return [];
    final files = backupDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }
}
