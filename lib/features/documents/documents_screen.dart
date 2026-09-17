import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/repository/base_repository.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/app_empty_state.dart';

/// Stores references to documents the user picks from local device storage.
/// Files stay on-device; only their local path/title/category are recorded
/// in SQLite — nothing is uploaded anywhere.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _repo = BaseRepository('documents');
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.getAll(orderBy: 'upload_date DESC');
    setState(() {
      _docs = rows;
      _loading = false;
    });
  }

  Future<void> _addDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final categoryCtrl = TextEditingController();
    final titleCtrl = TextEditingController(text: file.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.insert({
        'title': titleCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'file_path': file.path,
      });
      _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> doc) async {
    await _repo.delete(doc['id'] as int);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? const AppEmptyState(message: 'No documents added yet.\nTap + to attach a local file.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = _docs[index];
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text('${d['title']}'),
                        subtitle: Text('${d['category'] ?? ''} • ${AppDateUtils.display(d['upload_date'] as String?)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(d),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.attach_file),
        label: const Text('Add'),
      ),
    );
  }
}
