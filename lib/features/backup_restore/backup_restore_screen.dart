import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../../core/services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _service = BackupService();
  List<FileSystemEntity> _backups = [];
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backups = await _service.listBackups();
    setState(() {
      _backups = backups;
      _loading = false;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _working = true);
    try {
      final path = await _service.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved locally: ${p.basename(path)}')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _shareBackup(FileSystemEntity file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _restoreFrom(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore data?'),
        content: const Text(
          'This will replace all current data on this device with the selected backup. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _working = true);
    try {
      await _service.restoreFrom(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restoreFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result != null && result.files.single.path != null) {
      await _restoreFrom(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Your data lives only on this device. Create a local backup file periodically, '
                  'and share or copy it somewhere safe (e.g. your own cloud drive) manually if you want extra protection.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _working ? null : _createBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Create Backup Now'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _working ? null : _restoreFromFilePicker,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore from a .db file'),
                ),
                const SizedBox(height: 24),
                Text('Local backups on this device', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_backups.isEmpty) const Text('No backups yet.', style: TextStyle(color: Colors.grey)),
                ..._backups.map((f) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.sd_storage_outlined),
                        title: Text(p.basename(f.path)),
                        subtitle: Text(f.statSync().modified.toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.share), onPressed: () => _shareBackup(f)),
                            IconButton(icon: const Icon(Icons.restore), onPressed: () => _restoreFrom(f.path)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
