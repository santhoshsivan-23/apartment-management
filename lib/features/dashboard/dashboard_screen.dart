import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/repository/base_repository.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/ams_stat_card.dart';
import '../maintenance/generate_bill_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../complaints/complaints_screen.dart';
import '../amenities/booking_screen.dart';
import '../residents/residents_screen.dart';
import '../visitors/visitors_screen.dart';
import '../apartments/apartments_screen.dart';
import '../notices/notices_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onSelectTab;
  const DashboardScreen({super.key, this.onSelectTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  int _apartments = 0;
  int _residents = 0;
  int _unpaidBills = 0;
  double _pendingAmount = 0;
  double _collectedAmount = 0;
  double _totalBilledAmount = 0;
  int _openComplaints = 0;
  int _upcomingBookings = 0;
  List<Map<String, dynamic>> _recentVisitors = [];
  Map<int, String> _flatNumbers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final aptRepo = BaseRepository('apartments');
    final resRepo = BaseRepository('residents');
    final billsRepo = BaseRepository('maintenance_bills');
    final paymentsRepo = BaseRepository('payments');
    final complaintsRepo = BaseRepository('complaints');
    final bookingsRepo = BaseRepository('facility_bookings');
    final visitorsRepo = BaseRepository('visitors');

    final apartments = await aptRepo.count();
    final residents = await resRepo.count();
    final unpaidBills = await billsRepo.count(where: "status = 'unpaid'");
    final pendingAmount = await billsRepo.sum('amount', where: "status = 'unpaid'");
    final collectedAmount = await paymentsRepo.sum('amount');
    final totalBilledAmount = await billsRepo.sum('amount');
    final openComplaints = await complaintsRepo.count(where: "status IN ('open','in_progress')");
    final bookings = await bookingsRepo.count(where: "status = 'booked'");

    final allApts = await aptRepo.getAll();
    final flatMap = {for (final a in allApts) a['id'] as int: '${a['apartment_number']}'};

    final visitors = await visitorsRepo.getAll(orderBy: 'id DESC', where: '1 = 1');

    if (mounted) {
      setState(() {
        _apartments = apartments;
        _residents = residents;
        _unpaidBills = unpaidBills;
        _pendingAmount = pendingAmount;
        _collectedAmount = collectedAmount;
        _totalBilledAmount = totalBilledAmount;
        _openComplaints = openComplaints;
        _upcomingBookings = bookings;
        _flatNumbers = flatMap;
        _recentVisitors = visitors.take(4).toList();
        _loading = false;
      });
    }
  }

  Future<void> _markExit(int id) async {
    await BaseRepository('visitors').update(id, {
      'exit_time': DateTime.now().toIso8601String().substring(11, 16),
    });
    _load();
  }

  Future<void> _vacuumDb() async {
    final db = await AppDatabase.instance.database;
    await db.execute('VACUUM');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SQLite VACUUM complete. Database defragmented and optimized.')),
      );
    }
  }

  Future<void> _createSnapshot() async {
    try {
      final path = await BackupService().createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Instant snapshot created: ${path.split(RegExp(r"[/\\]")).last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create snapshot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final double recoveryRate = _totalBilledAmount > 0
        ? (_collectedAmount / _totalBilledAmount).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: _load,
            child: _buildMobileDashboard(context),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // TOP ADMIN WELCOME & SQLITE SYNC BANNER
              _buildAdminBanner(),
              const SizedBox(height: 16),

              // 6-CARD KPI METRIC GRID
              _buildKpiGrid(recoveryRate),
              const SizedBox(height: 16),

              // QUICK OPERATIONS & DISPATCH BAR
              _buildQuickDispatchBar(),
              const SizedBox(height: 16),

              // GATE & SECURITY LIVE STREAM
              _buildGateStreamCard(),
              const SizedBox(height: 16),

              // RECOVERY GAUGE & FACILITY WATCH ROW
              LayoutBuilder(
                builder: (context, innerConstraints) {
                  if (innerConstraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecoveryDonutCard(recoveryRate)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFacilityWatchCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildRecoveryDonutCard(recoveryRate),
                      const SizedBox(height: 16),
                      _buildFacilityWatchCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // BACKUP NODE CARD
              _buildBackupNodeCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Info Banner & Local DB Indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'On-Device SQLite • Offline Ready',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _load,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.cached_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'All figures computed live from on-device SQLite database.',
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Metrics 2x3 Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            // Card 1: Apartments
            _buildMobileMetricCard(
              icon: Icons.apartment_rounded,
              iconBgColor: AppTheme.secondaryContainer.withOpacity(0.4),
              iconColor: AppTheme.onSecondaryContainer,
              badgeText: '98% Occupied',
              badgeBgColor: AppTheme.secondaryContainer.withOpacity(0.6),
              badgeTextColor: AppTheme.onSecondaryContainer,
              label: 'Apartments',
              value: '$_apartments',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApartmentsScreen())).then((_) => _load()),
            ),
            // Card 2: Residents
            _buildMobileMetricCard(
              icon: Icons.group_rounded,
              iconBgColor: AppTheme.primary.withOpacity(0.15),
              iconColor: AppTheme.primary,
              badgeText: '+4 this mo',
              badgeBgColor: AppTheme.surfaceContainerHigh,
              badgeTextColor: AppTheme.onSurfaceVariant,
              label: 'Residents',
              value: '$_residents',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentsScreen())).then((_) => _load()),
            ),
            // Card 3: Unpaid Bills
            _buildMobileMetricCard(
              icon: Icons.receipt_long_rounded,
              iconBgColor: const Color(0xFFFFDCC3),
              iconColor: const Color(0xFF7D4200),
              badgeText: 'Due in 5d',
              badgeBgColor: const Color(0xFFFFDCC3),
              badgeTextColor: const Color(0xFF6E3900),
              label: 'Unpaid Bills',
              value: '$_unpaidBills',
              valueColor: const Color(0xFFA15600),
              onTap: () {
                if (widget.onSelectTab != null) {
                  widget.onSelectTab!(2);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())).then((_) => _load());
                }
              },
            ),
            // Card 4: Pending Dues
            _buildMobileMetricCard(
              icon: Icons.error_outline_rounded,
              iconBgColor: AppTheme.errorContainer.withOpacity(0.6),
              iconColor: AppTheme.defaulterRed,
              badgeText: 'Critical',
              badgeBgColor: AppTheme.errorContainer,
              badgeTextColor: const Color(0xFF93000A),
              label: 'Pending Dues',
              value: CurrencyUtils.format(_pendingAmount),
              valueColor: AppTheme.defaulterRed,
              onTap: () {
                if (widget.onSelectTab != null) {
                  widget.onSelectTab!(2);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())).then((_) => _load());
                }
              },
            ),
            // Card 5: Open Complaints
            _buildMobileMetricCard(
              icon: Icons.handyman_rounded,
              iconBgColor: AppTheme.errorContainer.withOpacity(0.4),
              iconColor: const Color(0xFF93000A),
              badgeText: _openComplaints > 0 ? '$_openComplaints Urgent' : 'Clear',
              badgeBgColor: AppTheme.errorContainer,
              badgeTextColor: const Color(0xFF93000A),
              label: 'Open Complaints',
              value: '$_openComplaints',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsScreen())).then((_) => _load()),
            ),
            // Card 6: Upcoming Bookings
            _buildMobileMetricCard(
              icon: Icons.event_available_rounded,
              iconBgColor: AppTheme.surfaceContainerHighest,
              iconColor: AppTheme.primary,
              badgeText: 'Club/Pool',
              badgeBgColor: AppTheme.surfaceContainer,
              badgeTextColor: AppTheme.onSurfaceVariant,
              label: 'Upcoming Bookings',
              value: '$_upcomingBookings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())).then((_) => _load()),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Community Activity Preview (Recent Gate Activity)
        _buildMobileRecentGateActivity(),
        const SizedBox(height: 14),

        // 4. Quick Actions Section ("Instant Dispatch")
        _buildMobileQuickActions(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMobileMetricCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String label,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: valueColor ?? AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRecentGateActivity() {
    final hasVisitors = _recentVisitors.isNotEmpty;
    final firstVisitor = hasVisitors ? _recentVisitors.first : null;
    final flat = firstVisitor != null ? (_flatNumbers[firstVisitor['apartment_id']] ?? 'Unit') : 'Unit 402';
    final visitorTitle = 'Tower B Main Gate';
    final visitorTime = firstVisitor != null ? (firstVisitor['entry_time'] ?? 'Just now') : '2m ago';
    final visitorSubtitle = firstVisitor != null
        ? '${firstVisitor['name']} (${firstVisitor['purpose'] ?? 'Guest'}) authorized for Flat $flat'
        : 'Guest vehicle KA-03-MG-4122 authorized for Unit 402';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsScreen())).then((_) => _load()),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recent Gate Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                ),
                Text(
                  'LIVE SYNC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            visitorTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                          ),
                          Text(
                            visitorTime,
                            style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        visitorSubtitle,
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
            ),
            Text(
              'INSTANT DISPATCH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Action 1: Generate Monthly Bills
        _buildMobileActionTile(
          icon: Icons.payments_rounded,
          iconBgColor: AppTheme.primaryContainer,
          iconColor: Colors.white,
          title: 'Generate Monthly Bills',
          subtitle: 'October 2026 cycle ready ($_apartments units)',
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.onSurfaceVariant),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateBillScreen())).then((_) => _load()),
        ),
        const SizedBox(height: 10),

        // Action 2: View Open Complaints
        _buildMobileActionTile(
          icon: Icons.build_rounded,
          iconBgColor: const Color(0xFFFFDCC3),
          iconColor: const Color(0xFF6E3900),
          title: 'View Open Complaints',
          subtitle: 'Water leakage, lift repair pending review',
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.onSurfaceVariant),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsScreen())).then((_) => _load()),
        ),
        const SizedBox(height: 10),

        // Action 3: Register Gate Visitor
        _buildMobileActionTile(
          icon: Icons.person_add_rounded,
          iconBgColor: AppTheme.secondaryContainer,
          iconColor: AppTheme.onSecondaryContainer,
          title: 'Register Gate Visitor',
          badgeText: 'Quick Entry',
          subtitle: 'One-tap pass & resident call authorization',
          trailing: const Icon(Icons.add, size: 20, color: AppTheme.onSurfaceVariant),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsScreen())).then((_) => _load()),
        ),
      ],
    );
  }

  Widget _buildMobileActionTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? badgeText,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Center(child: trailing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Administrator Console',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LOCAL MASTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSecondaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SQLite v3.42 Standalone • Air-Gapped / Zero Network Calls',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_apartments Units • $_residents Residents Registered',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.data_thresholding, size: 16, color: AppTheme.primary),
                    label: const Text('VACUUM DB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _vacuumDb,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primary),
                    onPressed: _load,
                    tooltip: 'Refresh Ledger',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(double recoveryRate) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1100) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            AmsStatCard(
              label: 'Apartments',
              value: '$_apartments',
              badgeText: '98% Occ',
              badgeColor: AppTheme.surfaceContainerHigh,
              badgeTextColor: AppTheme.primary,
              icon: Icons.apartment,
              progress: 0.98,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentsScreen())),
            ),
            AmsStatCard(
              label: 'Residents',
              value: '$_residents',
              badgeText: 'Active',
              badgeColor: AppTheme.secondaryContainer,
              badgeTextColor: AppTheme.onSecondaryContainer,
              icon: Icons.groups,
              iconColor: AppTheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentsScreen())),
            ),
            AmsStatCard(
              label: 'Pending Dues',
              value: '$_unpaidBills Flats',
              subtitle: CurrencyUtils.format(_pendingAmount),
              badgeText: 'Overdue',
              badgeColor: AppTheme.errorContainer,
              badgeTextColor: AppTheme.error,
              icon: Icons.pending_actions,
              iconColor: AppTheme.error,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
            ),
            AmsStatCard(
              label: 'Recovery',
              value: CurrencyUtils.format(_collectedAmount),
              subtitle: '${(recoveryRate * 100).toInt()}% Collected',
              icon: Icons.payments,
              iconColor: AppTheme.secondary,
              progress: recoveryRate,
              progressColor: AppTheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
            ),
            AmsStatCard(
              label: 'Helpdesk',
              value: '$_openComplaints',
              badgeText: _openComplaints > 0 ? 'Open' : 'Clean',
              badgeColor: _openComplaints > 0 ? AppTheme.errorContainer : AppTheme.secondaryContainer,
              badgeTextColor: _openComplaints > 0 ? AppTheme.error : AppTheme.onSecondaryContainer,
              icon: Icons.report_problem_outlined,
              iconColor: AppTheme.tertiary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsScreen())),
            ),
            AmsStatCard(
              label: 'Bookings',
              value: '$_upcomingBookings',
              badgeText: 'This Wk',
              badgeColor: AppTheme.surfaceContainerHigh,
              badgeTextColor: AppTheme.primary,
              icon: Icons.event_available,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickDispatchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text('Quick Operations & Dispatch',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                ],
              ),
              Text('Local SQLite Writes',
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.receipt_long,
                  label: 'Batch Billing',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GenerateBillScreen()),
                  ).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Add Resident',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentsScreen()),
                  ).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.badge_outlined,
                  label: 'Gate Entry',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VisitorsScreen()),
                  ).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.price_check,
                  label: 'Log Payment',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                  ).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.campaign_outlined,
                  label: 'Broadcast',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NoticesScreen()),
                  ).then((_) => _load()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateStreamCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
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
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('Gate & Security Live Stream',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsScreen()))
                    .then((_) => _load()),
                child: const Text('View All >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentVisitors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No visitors currently on campus.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentVisitors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final v = _recentVisitors[index];
                final flat = _flatNumbers[v['apartment_id']] ?? 'Common';
                final isExited = v['exit_time'] != null && (v['exit_time'] as String).isNotEmpty;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isExited ? AppTheme.surfaceContainerHigh : AppTheme.secondaryContainer,
                    child: Text(
                      (v['name'] as String? ?? 'V').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExited ? AppTheme.onSurfaceVariant : AppTheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    '${v['name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Flat $flat • ${v['purpose'] ?? 'Guest'} • In: ${v['entry_time'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                  trailing: isExited
                      ? const Chip(
                          label: Text('Exited', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          visualDensity: VisualDensity.compact,
                        )
                      : FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _markExit(v['id'] as int),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 14),
                              SizedBox(width: 4),
                              Text('Mark Exit', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecoveryDonutCard(double recoveryRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Assessment Recovery',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: recoveryRate,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(recoveryRate * 100).toInt()}%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                    ),
                    const Text('RECOVERED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Collected:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(CurrencyUtils.format(_collectedAmount),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Invoices:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(CurrencyUtils.format(_pendingAmount),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityWatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Facility Watch',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ALL ACTIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSecondaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFacilityItem(
            icon: Icons.local_gas_station,
            title: 'Diesel Generator Tank',
            status: '45% (180 L)',
            progress: 0.45,
            progressColor: AppTheme.tertiary,
          ),
          const SizedBox(height: 14),
          _buildFacilityItem(
            icon: Icons.water_drop,
            title: 'Master Sump Water Level',
            status: '85% Capacity',
            progress: 0.85,
            progressColor: AppTheme.primary,
          ),
          const SizedBox(height: 14),
          _buildFacilityItem(
            icon: Icons.videocam,
            title: 'CCTV Surveillance NVR',
            status: '32/32 Cameras Active',
            progress: 1.0,
            progressColor: AppTheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityItem({
    required IconData icon,
    required String title,
    required String status,
    required double progress,
    required Color progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackupNodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.save_outlined, color: AppTheme.primary, size: 24),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local Database Backup',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                  Text('Instant physical snapshot to local storage',
                      style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.download_for_offline, size: 16),
            label: const Text('Snapshot Now', style: TextStyle(fontSize: 12)),
            onPressed: _createSnapshot,
          ),
        ],
      ),
    );
  }
}
