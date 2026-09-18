import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/option_loaders.dart';

class FloorsScreen extends StatefulWidget {
  final int? buildingId;
  final String? buildingName;

  const FloorsScreen({super.key, this.buildingId, this.buildingName});

  @override
  State<FloorsScreen> createState() => _FloorsScreenState();
}

class _FloorsScreenState extends State<FloorsScreen> {
  List<Map<String, dynamic>> _floors = [];
  Map<int, String> _buildings = {};
  int? _selectedBuildingFilter;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBuildingFilter = widget.buildingId;
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bMap = await OptionLoaders.buildings();
    final db = await AppDatabase.instance.database;

    final String query;
    final List<dynamic> args;
    if (_selectedBuildingFilter != null) {
      query = '''
        SELECT f.*, b.name as building_name
        FROM floors f
        LEFT JOIN buildings b ON f.building_id = b.id
        WHERE f.building_id = ?
        ORDER BY f.floor_number ASC
      ''';
      args = [_selectedBuildingFilter];
    } else {
      query = '''
        SELECT f.*, b.name as building_name
        FROM floors f
        LEFT JOIN buildings b ON f.building_id = b.id
        ORDER BY b.name ASC, f.floor_number ASC
      ''';
      args = [];
    }

    final rows = await db.rawQuery(query, args);
    setState(() {
      _buildings = bMap;
      _floors = rows;
      _loading = false;
    });
  }

  Future<void> _autoGenerateFloors() async {
    final count = await OptionLoaders.syncFloorsForBuildings();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? 'Successfully auto-generated $count floors from building totals!'
              : 'All building floors are already generated and up to date.',
        ),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _openFloorForm({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();
    int? buildingId = existing?['building_id'] ?? _selectedBuildingFilter ?? (_buildings.isNotEmpty ? _buildings.keys.first : null);
    final floorNumCtrl = TextEditingController(text: existing?['floor_number']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add New Floor' : 'Edit Floor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: buildingId,
                      decoration: const InputDecoration(
                        labelText: 'Building',
                        border: OutlineInputBorder(),
                      ),
                      items: _buildings.entries.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => buildingId = val),
                      validator: (val) => val == null ? 'Building is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: floorNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Floor Number',
                        hintText: 'e.g. 1, 2, 0 (Ground), -1 (Basement)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Floor number is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Floor Name / Label (Optional)',
                        hintText: 'e.g. Ground Floor, First Floor, Terrace',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final db = await AppDatabase.instance.database;
                        final floorNum = int.tryParse(floorNumCtrl.text.trim()) ?? 0;
                        final label = nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : 'Floor $floorNum';

                        if (existing == null) {
                          await db.insert('floors', {
                            'building_id': buildingId,
                            'floor_number': floorNum,
                            'name': label,
                          });
                        } else {
                          await db.update(
                            'floors',
                            {
                              'building_id': buildingId,
                              'floor_number': floorNum,
                              'name': label,
                            },
                            where: 'id = ?',
                            whereArgs: [existing['id']],
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                      child: Text(existing == null ? 'Create Floor' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      _load();
    }
  }

  Future<void> _deleteFloor(Map<String, dynamic> floor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Floor?'),
        content: Text(
          'Are you sure you want to delete "${floor['name'] ?? 'Floor ${floor['floor_number']}'}" from ${floor['building_name']}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await AppDatabase.instance.database;
      await db.delete('floors', where: 'id = ?', whereArgs: [floor['id']]);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.buildingName != null
        ? '${widget.buildingName} - Floors'
        : 'Floors Management';

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _floors.where((f) {
      if (query.isEmpty) return true;
      final name = (f['name'] ?? '').toString().toLowerCase();
      final numStr = (f['floor_number'] ?? '').toString();
      final bName = (f['building_name'] ?? '').toString().toLowerCase();
      return name.contains(query) || numStr.contains(query) || bName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Auto-Generate Floors from Buildings',
            onPressed: _autoGenerateFloors,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search floors by name, number, or building...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.buildingId == null && _buildings.length > 1) ...[
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: _selectedBuildingFilter,
                    hint: const Text('All Buildings'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Buildings')),
                      ..._buildings.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBuildingFilter = val);
                      _load();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Floors List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.layers_clear_outlined, size: 28, color: AppTheme.outline),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No floors found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Floors can be automatically created based on your Building settings or added manually.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _autoGenerateFloors,
                                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                                label: const Text('Auto-Generate from Buildings'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final f = filtered[index];
                          final floorNum = f['floor_number'] as int? ?? 0;
                          final label = (f['name'] != null && f['name'].toString().trim().isNotEmpty)
                              ? f['name']
                              : 'Floor $floorNum';
                          final bName = f['building_name'] ?? 'Unassigned Building';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryContainer.withOpacity(0.12),
                              foregroundColor: AppTheme.primaryContainer,
                              child: Text(
                                floorNum == 0 ? 'G' : '$floorNum',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(
                              '$label',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('$bName • Floor #$floorNum'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Edit Floor',
                                  onPressed: () => _openFloorForm(existing: f),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                  tooltip: 'Delete Floor',
                                  onPressed: () => _deleteFloor(f),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFloorForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Floor'),
      ),
    );
  }
}
