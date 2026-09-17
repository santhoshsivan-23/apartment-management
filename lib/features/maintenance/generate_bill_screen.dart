import 'package:flutter/material.dart';
import '../../core/repository/base_repository.dart';
import '../../core/utils/date_utils.dart';

class GenerateBillScreen extends StatefulWidget {
  const GenerateBillScreen({super.key});

  @override
  State<GenerateBillScreen> createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends State<GenerateBillScreen> {
  final _apartmentsRepo = BaseRepository('apartments');
  final _billsRepo = BaseRepository('maintenance_bills');
  final _amountCtrl = TextEditingController(text: '2500');
  List<Map<String, dynamic>> _apartments = [];
  final Set<int> _selected = {};
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 10));
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apartments = await _apartmentsRepo.getAll(orderBy: 'apartment_number ASC');
    setState(() {
      _apartments = apartments;
      _selected.addAll(apartments.map((a) => a['id'] as int));
      _loading = false;
    });
  }

  Future<void> _generate() async {
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (amount == null || _selected.isEmpty) return;
    setState(() => _saving = true);
    final dueIso = _dueDate.toIso8601String().split('T').first;
    for (final apartmentId in _selected) {
      await _billsRepo.insert({
        'apartment_id': apartmentId,
        'month': _month,
        'year': _year,
        'amount': amount,
        'due_date': dueIso,
        'status': 'unpaid',
      });
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Maintenance Bills')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _month,
                        decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text(AppDateUtils.monthName(m))))
                            .toList(),
                        onChanged: (v) => setState(() => _month = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _year.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                        onChanged: (v) => _year = int.tryParse(v) ?? _year,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount per apartment', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  title: const Text('Due date'),
                  subtitle: Text(_dueDate.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime(_year - 1),
                      lastDate: DateTime(_year + 2),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Apartments (${_selected.length}/${_apartments.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => setState(() {
                        if (_selected.length == _apartments.length) {
                          _selected.clear();
                        } else {
                          _selected
                            ..clear()
                            ..addAll(_apartments.map((a) => a['id'] as int));
                        }
                      }),
                      child: Text(_selected.length == _apartments.length ? 'Deselect all' : 'Select all'),
                    ),
                  ],
                ),
                ..._apartments.map((a) {
                  final id = a['id'] as int;
                  return CheckboxListTile(
                    value: _selected.contains(id),
                    title: Text('${a['apartment_number']}'),
                    subtitle: Text('${a['type'] ?? ''}'),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(id);
                      } else {
                        _selected.remove(id);
                      }
                    }),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _generate,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Generate ${_selected.length} bill(s)'),
                ),
              ],
            ),
    );
  }
}
