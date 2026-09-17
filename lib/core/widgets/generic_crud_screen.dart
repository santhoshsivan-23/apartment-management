import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repository/base_repository.dart';
import 'field_config.dart';
import 'app_empty_state.dart';

/// A single reusable screen that renders a searchable list of records from
/// any SQLite table, plus an add/edit form and delete — all fully offline.
/// Every feature module in the project (residents, complaints, visitors,
/// vendors, staff, assets, notices, events, amenities, parking, etc.)
/// is powered by an instance of this widget configured with its own
/// table name and fields, so real CRUD works everywhere without
/// duplicating boilerplate per module.
class GenericCrudScreen extends StatefulWidget {
  final String title;
  final String tableName;
  final List<FieldConfig> fields;
  final String titleField; // which field to show as the list tile title
  final String? subtitleField;
  final Widget Function(Map<String, dynamic> row)? trailingBuilder;

  const GenericCrudScreen({
    super.key,
    required this.title,
    required this.tableName,
    required this.fields,
    required this.titleField,
    this.subtitleField,
    this.trailingBuilder,
  });

  @override
  State<GenericCrudScreen> createState() => _GenericCrudScreenState();
}

class _GenericCrudScreenState extends State<GenericCrudScreen> {
  late final BaseRepository repo = BaseRepository(widget.tableName);
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applySearch);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await repo.getAll();
    setState(() {
      _rows = rows;
      _loading = false;
    });
    _applySearch();
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _rows
          : _rows.where((r) {
              return r.values.any((v) => v.toString().toLowerCase().contains(q));
            }).toList();
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecordForm(
        fields: widget.fields,
        existing: existing,
        onSave: (data) async {
          if (existing == null) {
            await repo.insert(data);
          } else {
            await repo.update(existing['id'] as int, data);
          }
        },
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('This will permanently delete "${row[widget.titleField]}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await repo.delete(row['id'] as int);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? AppEmptyState(message: 'No ${widget.title.toLowerCase()} yet.\nTap + to add one.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = _filtered[index];
                            return ListTile(
                              title: Text('${row[widget.titleField] ?? ''}'),
                              subtitle: widget.subtitleField != null
                                  ? Text('${row[widget.subtitleField!] ?? ''}')
                                  : null,
                              trailing: widget.trailingBuilder?.call(row) ??
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') _openForm(existing: row);
                                      if (v == 'delete') _delete(row);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                              onTap: () => _openForm(existing: row),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _RecordForm extends StatefulWidget {
  final List<FieldConfig> fields;
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _RecordForm({required this.fields, required this.onSave, this.existing});

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Map<int, String>> _loadedOptions = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final initial = widget.existing?[f.key];
      _values[f.key] = initial;
      _controllers[f.key] = TextEditingController(text: initial?.toString() ?? '');
      if (f.optionsLoader != null) {
        f.optionsLoader!().then((opts) {
          if (mounted) setState(() => _loadedOptions[f.key] = opts);
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldConfig f) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_controllers[f.key]!.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      _controllers[f.key]!.text = formatted;
      _values[f.key] = formatted;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    for (final f in widget.fields) {
      if (f.type == FieldType.number) {
        _values[f.key] = num.tryParse(_controllers[f.key]!.text.trim());
      } else if (f.type != FieldType.dropdown) {
        _values[f.key] = _controllers[f.key]!.text.trim();
      }
    }
    await widget.onSave(_values);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add record' : 'Edit record',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final f in widget.fields) ...[
                _buildField(f),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(FieldConfig f) {
    switch (f.type) {
      case FieldType.date:
        return TextFormField(
          controller: _controllers[f.key],
          readOnly: true,
          decoration: InputDecoration(
            labelText: f.label,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: const OutlineInputBorder(),
          ),
          onTap: () => _pickDate(f),
          validator: (v) => f.required && (v == null || v.isEmpty) ? '${f.label} is required' : null,
        );
      case FieldType.dropdown:
        final staticOptions = f.options;
        final dynamicOptions = _loadedOptions[f.key];
        if (dynamicOptions != null) {
          return DropdownButtonFormField<int>(
            value: _values[f.key] is int ? _values[f.key] as int : null,
            decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
            items: dynamicOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _values[f.key] = v),
            validator: (v) => f.required && v == null ? '${f.label} is required' : null,
          );
        }
        return DropdownButtonFormField<String>(
          value: _values[f.key]?.toString().isEmpty ?? true ? null : _values[f.key].toString(),
          decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
          items: (staticOptions ?? [])
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => f.required && (v == null) ? '${f.label} is required' : null,
        );
      case FieldType.number:
        return TextFormField(
          controller: _controllers[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
          validator: (v) => f.required && (v == null || v.isEmpty) ? '${f.label} is required' : null,
        );
      case FieldType.multiline:
        return TextFormField(
          controller: _controllers[f.key],
          maxLines: 4,
          decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
          validator: (v) => f.required && (v == null || v.isEmpty) ? '${f.label} is required' : null,
        );
      case FieldType.text:
        return TextFormField(
          controller: _controllers[f.key],
          decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
          validator: (v) => f.required && (v == null || v.isEmpty) ? '${f.label} is required' : null,
        );
    }
  }
}
