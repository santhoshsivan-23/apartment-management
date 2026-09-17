import 'package:flutter/material.dart';
import '../../core/repository/base_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';

class BillDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  const BillDetailsScreen({super.key, required this.bill});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final _billsRepo = BaseRepository('maintenance_bills');
  final _itemsRepo = BaseRepository('bill_items');
  final _paymentsRepo = BaseRepository('payments');
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _itemsRepo.getAll(where: 'bill_id = ?', whereArgs: [widget.bill['id']]);
    final payments =
        await _paymentsRepo.getAll(where: 'bill_id = ?', whereArgs: [widget.bill['id']]);
    setState(() {
      _items = items;
      _payments = payments;
      _loading = false;
    });
  }

  Future<void> _addItem() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add line item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && descCtrl.text.isNotEmpty) {
      await _itemsRepo.insert({
        'bill_id': widget.bill['id'],
        'description': descCtrl.text.trim(),
        'amount': num.tryParse(amountCtrl.text.trim()) ?? 0,
      });
      _load();
    }
  }

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController(text: '${widget.bill['amount']}');
    String mode = 'cash';
    final refCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              DropdownButtonFormField<String>(
                value: mode,
                items: ['cash', 'upi', 'cheque', 'bank transfer', 'card']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setDlg(() => mode = v!),
                decoration: const InputDecoration(labelText: 'Mode'),
              ),
              TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _paymentsRepo.insert({
        'bill_id': widget.bill['id'],
        'amount': num.tryParse(amountCtrl.text.trim()) ?? 0,
        'payment_date': AppDateUtils.today(),
        'mode': mode,
        'reference': refCtrl.text.trim(),
      });
      await _billsRepo.update(widget.bill['id'] as int, {'status': 'paid'});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final totalPaid = _payments.fold<double>(0, (s, p) => s + (p['amount'] as num).toDouble());
    return Scaffold(
      appBar: AppBar(title: Text('Bill • ${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bill Amount: ${CurrencyUtils.format(bill['amount'] as num?)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Due: ${AppDateUtils.display(bill['due_date'] as String?)}'),
                        Text('Status: ${bill['status']}'),
                        Text('Paid so far: ${CurrencyUtils.format(totalPaid)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Line items', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add')),
                  ],
                ),
                ..._items.map((i) => ListTile(
                      title: Text('${i['description']}'),
                      trailing: Text(CurrencyUtils.format(i['amount'] as num?)),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payments', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _recordPayment,
                      icon: const Icon(Icons.payment),
                      label: const Text('Record'),
                    ),
                  ],
                ),
                ..._payments.map((p) => ListTile(
                      title: Text(CurrencyUtils.format(p['amount'] as num?)),
                      subtitle: Text('${p['mode']} • ${AppDateUtils.display(p['payment_date'] as String?)}'),
                    )),
              ],
            ),
    );
  }
}
