import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_theme.dart';
import '../../core/repository/base_repository.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/ams_stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _backupService = BackupService();
  bool _loading = true;
  bool _creatingBackup = false;

  // Financial Totals
  double _totalCollected = 0;
  double _totalPending = 0;
  double _totalExpenses = 0;

  // Charts data
  List<_MonthlyData> _monthlyData = [];
  List<_CategoryExpense> _categoryExpenses = [];

  // Local Backups
  List<FileSystemEntity> _backups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final paymentsRepo = BaseRepository('payments');
    final billsRepo = BaseRepository('maintenance_bills');
    final expensesRepo = BaseRepository('expenses');

    final collected = await paymentsRepo.sum('amount');
    final pending = await billsRepo.sum('amount', where: "status = 'unpaid'");
    final expenses = await expensesRepo.sum('amount');

    // Monthly Collections (last 6 months)
    final monthlyCollections = await paymentsRepo.rawQuery('''
      SELECT strftime('%Y-%m', payment_date) as ym, SUM(amount) as total
      FROM payments
      GROUP BY ym
      ORDER BY ym DESC
      LIMIT 6
    ''');

    // Monthly Expenses (last 6 months)
    final monthlyExp = await expensesRepo.rawQuery('''
      SELECT strftime('%Y-%m', date) as ym, SUM(amount) as total
      FROM expenses
      GROUP BY ym
      ORDER BY ym DESC
      LIMIT 6
    ''');

    // OPEX by Category
    final categoryExpRaw = await expensesRepo.rawQuery('''
      SELECT COALESCE(c.name, 'General / Misc') as category, SUM(e.amount) as total
      FROM expenses e
      LEFT JOIN expense_categories c ON e.category_id = c.id
      GROUP BY category
      ORDER BY total DESC
    ''');

    // Merge Monthly Collections & Expenses
    final Map<String, double> inflowMap = {};
    for (final row in monthlyCollections) {
      final ym = row['ym'] as String? ?? '';
      inflowMap[ym] = (row['total'] as num?)?.toDouble() ?? 0;
    }

    final Map<String, double> outflowMap = {};
    for (final row in monthlyExp) {
      final ym = row['ym'] as String? ?? '';
      outflowMap[ym] = (row['total'] as num?)?.toDouble() ?? 0;
    }

    // Set of all unique months sorted ascending
    final allMonths = {...inflowMap.keys, ...outflowMap.keys}.toList()..sort();
    final recentMonths = allMonths.length > 6 ? allMonths.sublist(allMonths.length - 6) : allMonths;

    final List<_MonthlyData> merged = recentMonths.map((ym) {
      return _MonthlyData(
        monthLabel: ym.length >= 7 ? ym.substring(2) : ym,
        inflow: inflowMap[ym] ?? 0,
        outflow: outflowMap[ym] ?? 0,
      );
    }).toList();

    // Category Expenses
    final List<_CategoryExpense> catList = categoryExpRaw.map((row) {
      return _CategoryExpense(
        name: row['category'] as String? ?? 'General',
        amount: (row['total'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    // Backups
    final backups = await _backupService.listBackups();

    if (mounted) {
      setState(() {
        _totalCollected = collected;
        _totalPending = pending;
        _totalExpenses = expenses;
        _monthlyData = merged;
        _categoryExpenses = catList;
        _backups = backups;
        _loading = false;
      });
    }
  }

  Future<void> _triggerBackup() async {
    setState(() => _creatingBackup = true);
    try {
      final path = await _backupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Safeguard Snapshot Created: ${p.basename(path)}'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup snapshot failed: $e'), backgroundColor: AppTheme.defaulterRed),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final netReserve = _totalCollected - _totalExpenses;
    final isSurplus = netReserve >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header
                      _buildHeader(isWide),
                      const SizedBox(height: 20),

                      // 4 KPI Cards
                      _buildKpiGrid(netReserve, isSurplus, isWide, constraints.maxWidth),
                      const SizedBox(height: 24),

                      // Dual-Bar Cashflow Chart
                      _buildCashflowChartCard(),
                      const SizedBox(height: 24),

                      // OPEX Allocation Donut Chart
                      _buildOpexDonutCard(),
                      const SizedBox(height: 24),

                      // SQLite Safeguard & Snapshots
                      _buildSafeguardLogsCard(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health & OPEX Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time ledger aggregation from offline SQLite transactions. 100% cloud-independent.',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            icon: _creatingBackup
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.shield_outlined, size: 16),
            label: const Text('Snapshot DB', style: TextStyle(fontSize: 12)),
            onPressed: _creatingBackup ? null : _triggerBackup,
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh Reports',
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(double netReserve, bool isSurplus, bool isWide, double maxWidth) {
    final cardWidth = isWide
        ? (maxWidth - 40 - 36) / 4
        : (maxWidth - 40 - 12) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: cardWidth,
          child: AMSStatCard(
            title: 'Total Inflow (Collections)',
            value: CurrencyUtils.format(_totalCollected),
            subtitle: 'Lifetime Maintenance Collected',
            icon: Icons.savings_rounded,
            color: Colors.green,
            badge: 'Inflow',
            badgeColor: Colors.green,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: AMSStatCard(
            title: 'Outstanding Receivables',
            value: CurrencyUtils.format(_totalPending),
            subtitle: 'Pending Resident Dues',
            icon: Icons.pending_actions_rounded,
            color: AppTheme.defaulterRed,
            badge: 'Unpaid Dues',
            badgeColor: AppTheme.defaulterRed,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: AMSStatCard(
            title: 'Total OPEX (Expenses)',
            value: CurrencyUtils.format(_totalExpenses),
            subtitle: 'Operational & Vendor Outflow',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFD97706),
            badge: 'Outflow',
            badgeColor: const Color(0xFFD97706),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: AMSStatCard(
            title: 'Net Society Reserve',
            value: CurrencyUtils.format(netReserve),
            subtitle: isSurplus ? 'Surplus Treasury' : 'Deficit Warning',
            icon: Icons.account_balance_rounded,
            color: isSurplus ? AppTheme.primary : AppTheme.defaulterRed,
            badge: isSurplus ? '+ Surplus' : '- Deficit',
            badgeColor: isSurplus ? AppTheme.primary : AppTheme.defaulterRed,
          ),
        ),
      ],
    );
  }

  Widget _buildCashflowChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-Month Cashflow (Inflow vs OPEX)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Comparative monthly collections vs operations expenditure.',
                    style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
              // Legend
              Row(
                children: [
                  _buildLegendItem('Inflow', AppTheme.primary),
                  const SizedBox(width: 12),
                  _buildLegendItem('OPEX', const Color(0xFFE11D48)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: _monthlyData.isEmpty
                ? const Center(child: Text('No recorded cashflow transactions for the last 6 months.'))
                : BarChart(
                    BarChartData(
                      barGroups: [
                        for (int i = 0; i < _monthlyData.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 6,
                            barRods: [
                              BarChartRodData(
                                toY: _monthlyData[i].inflow,
                                color: AppTheme.primary,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: _monthlyData[i].outflow,
                                color: const Color(0xFFE11D48),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _monthlyData.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _monthlyData[idx].monthLabel,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 55,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              if (value >= 100000) {
                                return Text('₹${(value / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontSize: 10));
                              } else if (value >= 1000) {
                                return Text('₹${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
                              }
                              return Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpexDonutCard() {
    final colors = [
      AppTheme.primary,
      const Color(0xFF0284C7),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFE11D48),
      const Color(0xFF059669),
      const Color(0xFF64748B),
    ];

    final totalOpex = _categoryExpenses.fold<double>(0, (s, c) => s + c.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPEX Allocation by Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Categorical distribution of operational expenses.',
                    style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
              Text(
                'Total: ${CurrencyUtils.format(totalOpex)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_categoryExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No expenses recorded yet in the database.')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;

                final chart = SizedBox(
                  height: 200,
                  width: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        for (int i = 0; i < _categoryExpenses.length; i++)
                          PieChartSectionData(
                            color: colors[i % colors.length],
                            value: _categoryExpenses[i].amount,
                            title: totalOpex > 0
                                ? '${(_categoryExpenses[i].amount / totalOpex * 100).toStringAsFixed(0)}%'
                                : '',
                            radius: 35,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                final legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _categoryExpenses.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _categoryExpenses[i].name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              CurrencyUtils.format(_categoryExpenses[i].amount),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              totalOpex > 0
                                  ? '(${(_categoryExpenses[i].amount / totalOpex * 100).toStringAsFixed(1)}%)'
                                  : '',
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      chart,
                      const SizedBox(width: 32),
                      Expanded(child: legend),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Center(child: chart),
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSafeguardLogsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Safeguard & Offline Snapshots',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                      ),
                      Text(
                        'Zero-latency local SQLite snapshots on device disk storage.',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${_backups.length} Snapshots',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_backups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No local database snapshots created yet. Tap "Snapshot DB" to safeguard your data.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Now'),
                    onPressed: _triggerBackup,
                  ),
                ],
              ),
            )
          else
            ..._backups.take(5).map((f) {
              final stat = f.statSync();
              final kb = (stat.size / 1024).toStringAsFixed(1);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.save_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(f.path),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified WAL Snapshot • ${stat.modified.toString().substring(0, 16)} • $kb KB',
                                style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: 'Share Snapshot',
                      onPressed: () => Share.shareXFiles([XFile(f.path)]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MonthlyData {
  final String monthLabel;
  final double inflow;
  final double outflow;
  _MonthlyData({required this.monthLabel, required this.inflow, required this.outflow});
}

class _CategoryExpense {
  final String name;
  final double amount;
  _CategoryExpense({required this.name, required this.amount});
}
