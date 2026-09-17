import 'package:flutter/material.dart';
import '../../core/repository/base_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/app_empty_state.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _paymentsRepo = BaseRepository('payments');
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _paymentsRepo.getAll(orderBy: 'payment_date DESC, id DESC');
    setState(() {
      _payments = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _payments.fold<double>(0, (s, p) => s + (p['amount'] as num).toDouble());
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total collected'),
                          Text(CurrencyUtils.format(total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _payments.isEmpty
                      ? const AppEmptyState(message: 'No payments recorded yet.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            itemCount: _payments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              return ListTile(
                                leading: const Icon(Icons.receipt),
                                title: Text(CurrencyUtils.format(p['amount'] as num?)),
                                subtitle: Text(
                                    'Bill #${p['bill_id']} • ${p['mode']} • ${p['reference'] ?? ''}'),
                                trailing: Text(AppDateUtils.display(p['payment_date'] as String?)),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
