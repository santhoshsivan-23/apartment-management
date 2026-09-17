import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/repository/base_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/ams_stat_card.dart';
import '../../core/widgets/app_empty_state.dart';
import 'generate_bill_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _billsRepo = BaseRepository('maintenance_bills');
  final _apartmentsRepo = BaseRepository('apartments');
  final _itemsRepo = BaseRepository('bill_items');
  final _paymentsRepo = BaseRepository('payments');

  List<Map<String, dynamic>> _allBills = [];
  Map<int, String> _apartmentNumbers = {};
  bool _loading = true;

  // Filter & Search
  String _filter = 'all'; // 'all', 'unpaid', 'paid'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Master-Detail selected bill
  Map<String, dynamic>? _selectedBill;
  List<Map<String, dynamic>> _selectedBillItems = [];
  List<Map<String, dynamic>> _selectedBillPayments = [];
  bool _loadingDetails = false;

  Map<int, String> _residentNames = {};
  Map<int, String> _residentOccupancy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bills = await _billsRepo.getAll(orderBy: 'year DESC, month DESC, id DESC');
    final apartments = await _apartmentsRepo.getAll();
    final aptMap = {for (final a in apartments) a['id'] as int: '${a['apartment_number']}'};

    final residents = await BaseRepository('residents').getAll();
    final resMap = <int, String>{};
    final occMap = <int, String>{};
    for (final r in residents) {
      final aptId = r['apartment_id'] as int?;
      if (aptId != null && !resMap.containsKey(aptId)) {
        resMap[aptId] = r['name'] as String? ?? 'Resident';
        final isOwner = r['is_owner'] == 1 || r['resident_type'] == 'owner';
        occMap[aptId] = isOwner ? 'Owner' : 'Tenant';
      }
    }

    setState(() {
      _allBills = bills;
      _apartmentNumbers = aptMap;
      _residentNames = resMap;
      _residentOccupancy = occMap;
      _loading = false;
    });

    if (_selectedBill != null) {
      final stillExists = bills.firstWhere(
        (b) => b['id'] == _selectedBill!['id'],
        orElse: () => {},
      );
      if (stillExists.isNotEmpty) {
        _selectBill(stillExists);
      } else if (bills.isNotEmpty) {
        _selectBill(bills.first);
      } else {
        setState(() {
          _selectedBill = null;
          _selectedBillItems = [];
          _selectedBillPayments = [];
        });
      }
    } else if (bills.isNotEmpty) {
      _selectBill(bills.first);
    }
  }

  Future<void> _selectBill(Map<String, dynamic> bill) async {
    setState(() {
      _selectedBill = bill;
      _loadingDetails = true;
    });

    final items = await _itemsRepo.getAll(where: 'bill_id = ?', whereArgs: [bill['id']]);
    final payments = await _paymentsRepo.getAll(where: 'bill_id = ?', whereArgs: [bill['id']]);

    if (mounted) {
      setState(() {
        _selectedBillItems = items;
        _selectedBillPayments = payments;
        _loadingDetails = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBills {
    return _allBills.where((bill) {
      final status = bill['status'] ?? 'unpaid';
      if (_filter == 'unpaid' && status == 'paid') return false;
      if (_filter == 'paid' && status != 'paid') return false;

      if (_searchQuery.isNotEmpty) {
        final apt = (_apartmentNumbers[bill['apartment_id']] ?? '').toLowerCase();
        final billId = 'inv-${bill['id']}'.toLowerCase();
        final month = AppDateUtils.monthName(bill['month'] as int? ?? 1).toLowerCase();
        final q = _searchQuery.toLowerCase();
        if (!apt.contains(q) && !billId.contains(q) && !month.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _recordOfflinePayment(Map<String, dynamic> bill) async {
    final amountCtrl = TextEditingController(text: '${bill['amount']}');
    String mode = 'cash';
    final refCtrl = TextEditingController(text: 'OFFLINE-REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.point_of_sale, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('Record Offline Payment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apt #${_apartmentNumbers[bill['apartment_id']] ?? bill['apartment_id']} • '
                  '${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Received Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mode,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash (Society Office)')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI / QR Scan')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque / DD')),
                    DropdownMenuItem(value: 'bank transfer', child: Text('NEFT / RTGS / IMPS')),
                    DropdownMenuItem(value: 'card', child: Text('POS Terminal Card')),
                  ],
                  onChanged: (v) => setDlg(() => mode = v!),
                  decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Offline Receipt / Txn Ref',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm & Mark Paid'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final amt = num.tryParse(amountCtrl.text.trim()) ?? (bill['amount'] as num);
      await _paymentsRepo.insert({
        'bill_id': bill['id'],
        'amount': amt,
        'payment_date': AppDateUtils.today(),
        'mode': mode,
        'reference': refCtrl.text.trim(),
      });
      await _billsRepo.update(bill['id'] as int, {'status': 'paid'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${CurrencyUtils.format(amt)} recorded for Flat ${_apartmentNumbers[bill['apartment_id']]}'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
      _load();
    }
  }

  Future<void> _addLineItem(Map<String, dynamic> bill) async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Invoice Line Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Item Description (e.g. DG Backup, Water Surcharge)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add Line Item')),
        ],
      ),
    );

    if (ok == true && descCtrl.text.trim().isNotEmpty) {
      final itemAmt = num.tryParse(amountCtrl.text.trim()) ?? 0;
      await _itemsRepo.insert({
        'bill_id': bill['id'],
        'description': descCtrl.text.trim(),
        'amount': itemAmt,
      });

      // Update total bill amount
      final newTotal = (bill['amount'] as num? ?? 0) + itemAmt;
      await _billsRepo.update(bill['id'] as int, {'amount': newTotal});

      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Summary KPI computations
    final totalInvoiced = _allBills.fold<double>(0, (s, b) => s + (b['amount'] as num? ?? 0).toDouble());
    final totalUnpaid = _allBills.where((b) => b['status'] != 'paid').fold<double>(0, (s, b) => s + (b['amount'] as num? ?? 0).toDouble());
    final totalPaid = totalInvoiced - totalUnpaid;
    final unpaidCount = _allBills.where((b) => b['status'] != 'paid').length;
    final recoveryPercent = totalInvoiced > 0 ? (totalPaid / totalInvoiced * 100).toStringAsFixed(1) : '100';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SafeArea(
                      child: _buildMobileBillingView(
                        totalInvoiced: totalInvoiced,
                        totalPaid: totalPaid,
                        totalUnpaid: totalUnpaid,
                        unpaidCount: unpaidCount,
                        recoveryPercent: recoveryPercent,
                      ),
                    ),
                  ),
          );
        }

        return Scaffold(
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      // Header & Summary
                      _buildHeaderAndSummary(
                        totalInvoiced: totalInvoiced,
                        totalPaid: totalPaid,
                        totalUnpaid: totalUnpaid,
                        unpaidCount: unpaidCount,
                        recoveryPercent: recoveryPercent,
                        isWide: isWide,
                      ),

                      // Controls Bar (Search + Filter Chips)
                      _buildControlsBar(),

                      // Body: Split or Single View
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Pane: Bills Master List
                            Expanded(
                              flex: 3,
                              child: _buildBillsList(isSplitMode: true),
                            ),
                            const VerticalDivider(width: 1, thickness: 1, color: AppTheme.outlineVariant),
                            // Right Pane: Inspector
                            Expanded(
                              flex: 2,
                              child: _buildInspectorPane(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Generate Bills'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenerateBillScreen()),
              );
              _load();
            },
          ),
        );
      },
    );
  }

  Widget _buildMobileBillingView({
    required double totalInvoiced,
    required double totalPaid,
    required double totalUnpaid,
    required int unpaidCount,
    required String recoveryPercent,
  }) {
    final bills = _filteredBills;
    final paidCount = _allBills.where((b) => b['status'] == 'paid').length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Top Navigation & Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance Bills',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_allBills.length} Invoices Cached',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Generate New', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GenerateBillScreen()),
                );
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Real-time Local Summary Strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, size: 17, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'October 2026 Collection',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$recoveryPercent% Paid',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Billed',
                            style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.format(totalInvoiced),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pending Dues',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.defaulterRed),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.format(totalUnpaid),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.defaulterRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Segmented Filter Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildSegmentedTab('All (${_allBills.length})', 'all'),
              _buildSegmentedTab('Unpaid ($unpaidCount)', 'unpaid'),
              _buildSegmentedTab('Paid ($paidCount)', 'paid'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Bills Feed
        if (bills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No invoices in this category.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...bills.map((bill) => _buildMobileBillCard(bill)),

        const SizedBox(height: 16),
        // 5. Offline Status Pill at Bottom
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SQLite Synced 3 mins ago • Instant Offline Search',
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSegmentedTab(String label, String key) {
    final active = _filter == key;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBillCard(Map<String, dynamic> bill) {
    final isPaid = bill['status'] == 'paid';
    final aptName = _apartmentNumbers[bill['apartment_id']] ?? 'Apt #${bill['apartment_id']}';
    final residentName = _residentNames[bill['apartment_id']] ?? 'John Doe';
    final occ = _residentOccupancy[bill['apartment_id']] ?? (isPaid ? 'Tenant' : 'Owner');
    final period = '${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']}';
    final dueDate = AppDateUtils.display(bill['due_date'] as String?);

    if (!isPaid) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.defaulterRed.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, size: 22, color: AppTheme.defaulterRed),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Flat $aptName',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '• Tower A',
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            const Text(
                              'Resident: ',
                              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                            ),
                            Text(
                              '$residentName ($occ)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'UNPAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.defaulterRed,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Metrics Grid (2 columns in surfaceContainerLow)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Period',
                          style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          period,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              dueDate,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDCC3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'In 5 days',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6E3900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Total Amount Highlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payable Amount',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant),
                ),
                Text(
                  CurrencyUtils.format(bill['amount'] as num?),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.defaulterRed,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Line Items Preview Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'LINE ITEMS PREVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Itemized breakdown',
                        style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly Base Maintenance', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      Text(CurrencyUtils.format(bill['amount'] as num?), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons (2 columns)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Pay / Record', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _recordOfflinePayment(bill),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () => _showMobileDetailsSheet(bill),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Paid Card
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 22, color: AppTheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Flat $aptName',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '• Tower A',
                            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: AppTheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          const Text(
                            'Resident: ',
                            style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                          Text(
                            '$residentName ($occ)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSecondaryContainer,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Metrics Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Period',
                        style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        period,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Mode',
                        style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.verified, size: 14, color: AppTheme.secondary),
                          SizedBox(width: 4),
                          Text(
                            'Settled (UPI / Cash)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Settled Amount Highlight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Settled Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant),
              ),
              Text(
                CurrencyUtils.format(bill['amount'] as num?),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 17),
                  label: const Text('View Receipt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () => _showMobileDetailsSheet(bill),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    foregroundColor: AppTheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_download_rounded, size: 17),
                  label: const Text('Share PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () => _showMobileDetailsSheet(bill),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSummary({
    required double totalInvoiced,
    required double totalPaid,
    required double totalUnpaid,
    required int unpaidCount,
    required String recoveryPercent,
    required bool isWide,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance & Collections Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Offline billing ledger, automated dues tracking & instant offline cash/UPI receipts.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Ledger',
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3 KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isWide
                  ? (constraints.maxWidth - 24) / 3
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: AMSStatCard(
                      title: 'Total Invoiced',
                      value: CurrencyUtils.format(totalInvoiced),
                      subtitle: '${_allBills.length} Billing records',
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.primary,
                      badge: 'All Time',
                      badgeColor: AppTheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AMSStatCard(
                      title: 'Total Collected',
                      value: CurrencyUtils.format(totalPaid),
                      subtitle: '$recoveryPercent% recovery rate',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      badge: 'Recovered',
                      badgeColor: Colors.green,
                      progress: totalInvoiced > 0 ? (totalPaid / totalInvoiced) : 1.0,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? cardWidth : constraints.maxWidth,
                    child: AMSStatCard(
                      title: 'Outstanding Dues',
                      value: CurrencyUtils.format(totalUnpaid),
                      subtitle: '$unpaidCount Defaulters / Pending',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.defaulterRed,
                      badge: unpaidCount > 0 ? '$unpaidCount Defaulters' : 'Clear',
                      badgeColor: unpaidCount > 0 ? AppTheme.defaulterRed : Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    final unpaidCount = _allBills.where((b) => b['status'] != 'paid').length;
    final paidCount = _allBills.where((b) => b['status'] == 'paid').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filter Chips
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: _filter == 'all',
                label: Text('All (${_allBills.length})'),
                onSelected: (_) => setState(() => _filter = 'all'),
              ),
              FilterChip(
                selected: _filter == 'unpaid',
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: AppTheme.defaulterRed),
                    const SizedBox(width: 4),
                    Text('Unpaid / Dues ($unpaidCount)'),
                  ],
                ),
                onSelected: (_) => setState(() => _filter = 'unpaid'),
              ),
              FilterChip(
                selected: _filter == 'paid',
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Settled ($paidCount)'),
                  ],
                ),
                onSelected: (_) => setState(() => _filter = 'paid'),
              ),
            ],
          ),

          // Search Field
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search flat, month, invoice...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList({required bool isSplitMode}) {
    final bills = _filteredBills;

    if (bills.isEmpty) {
      return const AppEmptyState(
        message: 'No bills match your search criteria.\nGenerate new batch bills using the button below.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bill = bills[index];
        final isPaid = bill['status'] == 'paid';
        final isSelected = isSplitMode && _selectedBill?['id'] == bill['id'];
        final aptName = _apartmentNumbers[bill['apartment_id']] ?? 'Apt #${bill['apartment_id']}';

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isSplitMode) {
              _selectBill(bill);
            } else {
              _showMobileDetailsSheet(bill);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryContainer.withOpacity(0.15) : AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : isPaid
                        ? AppTheme.outlineVariant
                        : AppTheme.defaulterRed.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Apartment Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withOpacity(0.1) : AppTheme.defaulterRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      aptName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isPaid ? Colors.green.shade800 : AppTheme.defaulterRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Month & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'INV-${bill['id']}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${AppDateUtils.display(bill['due_date'] as String?)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPaid ? AppTheme.onSurfaceVariant : AppTheme.defaulterRed,
                          fontWeight: isPaid ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(bill['amount'] as num?),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withOpacity(0.12) : AppTheme.defaulterRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPaid ? 'PAID' : 'UNPAID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green.shade800 : AppTheme.defaulterRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspectorPane() {
    if (_selectedBill == null) {
      return const Center(
        child: Text(
          'Select a bill on the left to inspect details,\nitems, and record offline payments.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    if (_loadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    final bill = _selectedBill!;
    final isPaid = bill['status'] == 'paid';
    final aptName = _apartmentNumbers[bill['apartment_id']] ?? 'Apt #${bill['apartment_id']}';
    final totalPaid = _selectedBillPayments.fold<double>(0, (s, p) => s + (p['amount'] as num).toDouble());

    return Container(
      color: AppTheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Inspector Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPaid
                    ? [const Color(0xFF0F766E), const Color(0xFF005C55)]
                    : [const Color(0xFFBE123C), const Color(0xFF9F1239)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'INVOICE #INV-${bill['id']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.white : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPaid ? 'PAID & SETTLED' : 'PAYMENT DUE',
                        style: TextStyle(
                          color: isPaid ? Colors.green.shade800 : AppTheme.defaulterRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Flat $aptName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Billing Cycle: ${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        Text(
                          CurrencyUtils.format(bill['amount'] as num?),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Due Date', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        Text(
                          AppDateUtils.display(bill['due_date'] as String?),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Actions
          if (!isPaid)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primary,
              ),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Record Offline Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _recordOfflinePayment(bill),
            ),
          if (isPaid)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.verified_outlined, color: Colors.green),
              label: Text('Settled on ${AppDateUtils.display(bill['updated_at'] as String? ?? AppDateUtils.today())}'),
              onPressed: null,
            ),
          const SizedBox(height: 20),

          // Line Items Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Itemized Bill Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                      onPressed: () => _addLineItem(bill),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Standard Society Maintenance', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    CurrencyUtils.format(bill['amount'] as num?),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._selectedBillItems.map((item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item['description']}'),
                      trailing: Text(
                        CurrencyUtils.format(item['amount'] as num?),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payments Ledger for this bill
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Paid: ${CurrencyUtils.format(totalPaid)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                if (_selectedBillPayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No offline payments logged yet for this invoice.', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  ),
                ..._selectedBillPayments.map((p) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      title: Text(CurrencyUtils.format(p['amount'] as num?), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${(p['mode'] ?? 'cash').toString().toUpperCase()} • ${AppDateUtils.display(p['payment_date'] as String?)}\nRef: ${p['reference'] ?? 'Direct Offline'}'),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileDetailsSheet(Map<String, dynamic> bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: Future.wait([
                      _itemsRepo.getAll(where: 'bill_id = ?', whereArgs: [bill['id']]),
                      _paymentsRepo.getAll(where: 'bill_id = ?', whereArgs: [bill['id']]),
                    ]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data![0];
                      final payments = snapshot.data![1];
                      final isPaid = bill['status'] == 'paid';
                      final aptName = _apartmentNumbers[bill['apartment_id']] ?? 'Apt #${bill['apartment_id']}';

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Flat $aptName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green.withOpacity(0.12) : AppTheme.defaulterRed.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'UNPAID',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPaid ? Colors.green.shade800 : AppTheme.defaulterRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text('${AppDateUtils.monthName(bill['month'] as int)} ${bill['year']} • INV-${bill['id']}'),
                          const SizedBox(height: 12),
                          Text(
                            'Amount: ${CurrencyUtils.format(bill['amount'] as num?)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text('Due Date: ${AppDateUtils.display(bill['due_date'] as String?)}'),
                          const SizedBox(height: 16),
                          if (!isPaid)
                            FilledButton.icon(
                              icon: const Icon(Icons.point_of_sale),
                              label: const Text('Record Offline Payment'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _recordOfflinePayment(bill);
                              },
                            ),
                          const SizedBox(height: 16),
                          const Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Standard Base Maintenance'),
                            trailing: Text(CurrencyUtils.format(bill['amount'] as num?)),
                          ),
                          ...items.map((i) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${i['description']}'),
                                trailing: Text(CurrencyUtils.format(i['amount'] as num?)),
                              )),
                          const Divider(),
                          const Text('Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (payments.isEmpty)
                            const Text('No payments recorded yet.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                          ...payments.map((p) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(CurrencyUtils.format(p['amount'] as num?)),
                                subtitle: Text('${p['mode']} • ${AppDateUtils.display(p['payment_date'] as String?)}'),
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
