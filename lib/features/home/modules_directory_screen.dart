import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../community/community_screen.dart';
import '../buildings/buildings_screen.dart';
import '../apartments/apartments_screen.dart';
import '../residents/residents_screen.dart';
import '../residents/family_members_screen.dart';
import '../residents/vehicles_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../payments/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import '../complaints/complaints_screen.dart';
import '../visitors/visitors_screen.dart';
import '../parking/parking_screen.dart';
import '../amenities/amenities_screen.dart';
import '../amenities/booking_screen.dart';
import '../notices/notices_screen.dart';
import '../events/events_screen.dart';
import '../vendors/vendors_screen.dart';
import '../staff/staff_screen.dart';
import '../staff/staff_attendance_screen.dart';
import '../assets/assets_screen.dart';
import '../assets/asset_maintenance_screen.dart';
import '../reports/reports_screen.dart';
import '../documents/documents_screen.dart';
import '../settings/settings_screen.dart';

class ModuleItem {
  final String title;
  final String description;
  final String subtitlePill;
  final String keywords;
  final IconData icon;
  final Color color;
  final Color? iconBgColor;
  final String category; // 'governance', 'finance', 'gate', 'admin'
  final WidgetBuilder builder;

  const ModuleItem({
    required this.title,
    required this.description,
    required this.subtitlePill,
    required this.keywords,
    required this.icon,
    required this.color,
    this.iconBgColor,
    required this.category,
    required this.builder,
  });
}

class ModulesDirectoryScreen extends StatefulWidget {
  const ModulesDirectoryScreen({super.key});

  @override
  State<ModulesDirectoryScreen> createState() => _ModulesDirectoryScreenState();
}

class _ModulesDirectoryScreenState extends State<ModulesDirectoryScreen> {
  String _selectedCategory = 'all';
  final _searchCtrl = TextEditingController();

  static final List<ModuleItem> _allModules = [
    ModuleItem(
      title: 'Community',
      description: 'Central association profile, constitution & master ledger.',
      subtitlePill: '4 Towers',
      keywords: 'community 4 towers residency complex society',
      icon: Icons.apartment_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const CommunityScreen(),
    ),
    ModuleItem(
      title: 'Buildings',
      description: 'Tower mapping, blocks, floors and core architecture.',
      subtitlePill: 'Blocks A-D',
      keywords: 'buildings tower blocks a b c d structures floors levels stories',
      icon: Icons.domain_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const BuildingsScreen(),
    ),
    ModuleItem(
      title: 'Apartments',
      description: 'Individual flat units, sqft areas and occupancy status.',
      subtitlePill: '48 Units',
      keywords: 'apartments units flats homes doors floors levels',
      icon: Icons.meeting_room_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const ApartmentsScreen(),
    ),
    ModuleItem(
      title: 'Residents',
      description: 'Primary owner and tenant registry with verified contacts.',
      subtitlePill: '112 Members',
      keywords: 'residents members people owners tenants directory',
      icon: Icons.group_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'governance',
      builder: (_) => const ResidentsScreen(),
    ),
    ModuleItem(
      title: 'Family',
      description: 'Resident family trees, dependents and emergency relations.',
      subtitlePill: 'Dependents',
      keywords: 'family dependents relatives kids spouse elders',
      icon: Icons.family_restroom_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'governance',
      builder: (_) => const FamilyMembersScreen(),
    ),
    ModuleItem(
      title: 'Vehicles',
      description: 'Registered four-wheelers and two-wheelers with parking tags.',
      subtitlePill: '64 Listed',
      keywords: 'vehicles cars bikes registered rfid stickers',
      icon: Icons.directions_car_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'gate',
      builder: (_) => const VehiclesScreen(),
    ),
    ModuleItem(
      title: 'Parking',
      description: 'Basement and stilt slot allocations per apartment.',
      subtitlePill: 'Allotments',
      keywords: 'parking slot allotments basement space car bay',
      icon: Icons.local_parking_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'gate',
      builder: (_) => const ParkingScreen(),
    ),
    ModuleItem(
      title: 'Maint Bills',
      description: 'Automated billing ledger, breakdown invoices and monthly dues.',
      subtitlePill: 'Ledger',
      keywords: 'maint bills maintenance monthly ledger invoice dues',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF7D4200),
      iconBgColor: const Color(0x1A7D4200),
      category: 'finance',
      builder: (_) => const MaintenanceScreen(),
    ),
    ModuleItem(
      title: 'Payments',
      description: 'Offline payment logging for cash, cheques and direct transfers.',
      subtitlePill: 'UPI / Cash',
      keywords: 'payments cash upi bank receipts collections transactions',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF7D4200),
      iconBgColor: const Color(0x1A7D4200),
      category: 'finance',
      builder: (_) => const PaymentsScreen(),
    ),
    ModuleItem(
      title: 'Expenses',
      description: 'Society operating expenditures, utility bills & cash outflow.',
      subtitlePill: 'Staff & Ops',
      keywords: 'expenses utility staff wages diesel electricity vendor payments',
      icon: Icons.payments_rounded,
      color: const Color(0xFF7D4200),
      iconBgColor: const Color(0x1A7D4200),
      category: 'finance',
      builder: (_) => const ExpensesScreen(),
    ),
    ModuleItem(
      title: 'Complaints',
      description: 'Ticketing desk for plumbing, electrical and general repairs.',
      subtitlePill: '3 Active',
      keywords: 'complaints helpdesk issues tickets water leak noise electric',
      icon: Icons.notification_important_rounded,
      color: AppTheme.defaulterRed,
      iconBgColor: const Color(0x1ABA1A1A),
      category: 'gate',
      builder: (_) => const ComplaintsScreen(),
    ),
    ModuleItem(
      title: 'Visitors',
      description: 'Front gate entry logs, temporary passes and verification.',
      subtitlePill: 'Gate Pass',
      keywords: 'visitors gate pass entry guests delivery cab courier security',
      icon: Icons.security_rounded,
      color: AppTheme.primaryContainer,
      iconBgColor: const Color(0x200F766E),
      category: 'gate',
      builder: (_) => const VisitorsScreen(),
    ),
    ModuleItem(
      title: 'Amenities',
      description: 'Master list of clubhouse facilities, swimming pool, gym & parks.',
      subtitlePill: 'Club & Gym',
      keywords: 'amenities clubhouse gym pool tennis court recreation',
      icon: Icons.pool_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const AmenitiesScreen(),
    ),
    ModuleItem(
      title: 'Bookings',
      description: 'Facility scheduling calendar to prevent overlapping slots.',
      subtitlePill: 'Calendar',
      keywords: 'bookings slot calendar party hall schedule reserve',
      icon: Icons.calendar_month_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const BookingScreen(),
    ),
    ModuleItem(
      title: 'Notices',
      description: 'Broadcast bulletins, announcements and society circulars.',
      subtitlePill: 'Digital Board',
      keywords: 'notices digital board announcement circular broadcast',
      icon: Icons.campaign_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const NoticesScreen(),
    ),
    ModuleItem(
      title: 'Events',
      description: 'Community gatherings, festival celebrations & sports days.',
      subtitlePill: 'Community',
      keywords: 'events community hub festival holi diwali celebration sports',
      icon: Icons.celebration_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'governance',
      builder: (_) => const EventsScreen(),
    ),
    ModuleItem(
      title: 'Staff',
      description: 'Security guards, maintenance crew, sweepers and cleaners.',
      subtitlePill: '18 Active',
      keywords: 'staff guards cleaners security housekeeping maids gardener',
      icon: Icons.badge_outlined,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'gate',
      builder: (_) => const StaffScreen(),
    ),
    ModuleItem(
      title: 'Vendors',
      description: 'External contractors, AMC service providers and technicians.',
      subtitlePill: 'Services',
      keywords: 'vendors plumbing electric lift elevator amc contractor repairs plumber',
      icon: Icons.local_shipping_rounded,
      color: AppTheme.secondary,
      iconBgColor: const Color(0x1A006A61),
      category: 'admin',
      builder: (_) => const VendorsScreen(),
    ),
    ModuleItem(
      title: 'Assets',
      description: 'Equipment inventory like generators, pumps, lifts and CCTV.',
      subtitlePill: 'Pumps & DG',
      keywords: 'assets pumps generators transformers solar stp equipment',
      icon: Icons.precision_manufacturing_rounded,
      color: AppTheme.onSurfaceVariant,
      iconBgColor: const Color(0x1A3E4947),
      category: 'admin',
      builder: (_) => const AssetsScreen(),
    ),
    ModuleItem(
      title: 'Inventory',
      description: 'Consumables, lighting spares, plumbing pipes and hardware.',
      subtitlePill: 'Spares & Stock',
      keywords: 'inventory spares supplies bulbs chemicals pipes stock ledger',
      icon: Icons.inventory_2_rounded,
      color: AppTheme.onSurfaceVariant,
      iconBgColor: const Color(0x1A3E4947),
      category: 'admin',
      builder: (_) => const AssetMaintenanceScreen(),
    ),
    ModuleItem(
      title: 'Tasks',
      description: 'Routine maintenance checklists, pump checks and lift AMC logs.',
      subtitlePill: 'Logs',
      keywords: 'tasks maintenance logs daily checks routine inspection checklists',
      icon: Icons.task_alt_rounded,
      color: AppTheme.onSurfaceVariant,
      iconBgColor: const Color(0x1A3E4947),
      category: 'admin',
      builder: (_) => const StaffAttendanceScreen(),
    ),
    ModuleItem(
      title: 'Meetings',
      description: 'AGM and managing committee minutes of meeting archive.',
      subtitlePill: 'AGM & Board',
      keywords: 'meetings agm committee minutes resolutions mom recording',
      icon: Icons.mic_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const DocumentsScreen(),
    ),
    ModuleItem(
      title: 'Polls',
      description: 'Digital resident voting ballots and opinion surveys.',
      subtitlePill: '1 Open',
      keywords: 'polls resident voting ballot survey opinions decisions',
      icon: Icons.how_to_vote_rounded,
      color: AppTheme.primary,
      iconBgColor: const Color(0x1A005C55),
      category: 'governance',
      builder: (_) => const NoticesScreen(),
    ),
    ModuleItem(
      title: 'Reports',
      description: 'Income vs Expense charts, defaulter audits & balance sheets.',
      subtitlePill: 'P&L & Ops',
      keywords: 'reports financial ops audit statements export balance sheet',
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFF7D4200),
      iconBgColor: const Color(0x1A7D4200),
      category: 'finance',
      builder: (_) => const ReportsScreen(),
    ),
    ModuleItem(
      title: 'Documents',
      description: 'Society bylaws, occupancy certificates & legal blueprints.',
      subtitlePill: 'Bylaws & NOC',
      keywords: 'documents bylaws nocs agreements deeds legal files certificates',
      icon: Icons.folder_shared_rounded,
      color: AppTheme.onSurfaceVariant,
      iconBgColor: const Color(0x1A3E4947),
      category: 'admin',
      builder: (_) => const DocumentsScreen(),
    ),
    ModuleItem(
      title: 'Settings',
      description: 'Device configuration, Master PIN encryption and offline storage.',
      subtitlePill: 'SQLite & PIN',
      keywords: 'backups settings sqlite pin security database configuration sync',
      icon: Icons.settings_suggest_rounded,
      color: AppTheme.primaryContainer,
      iconBgColor: const Color(0x200F766E),
      category: 'admin',
      builder: (_) => const SettingsScreen(),
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ModuleItem> get _filteredModules {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allModules.where((m) {
      final matchesCategory = _selectedCategory == 'all' || m.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.keywords.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final modules = _filteredModules;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Society Modules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '26 Total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Local SQLite Cached',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search 26 modules (e.g., Billing, Gate)...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.onSurfaceVariant),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill('All (26)', 'all'),
                      const SizedBox(width: 6),
                      _buildFilterPill('Governance', 'governance'),
                      const SizedBox(width: 6),
                      _buildFilterPill('Finance', 'finance'),
                      const SizedBox(width: 6),
                      _buildFilterPill('Daily Gate', 'gate'),
                      const SizedBox(width: 6),
                      _buildFilterPill('Admin', 'admin'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Modules Grid or Empty State
                if (modules.isEmpty)
                  _buildNoResultsState()
                else if (isWide)
                  _buildDesktopGrid(modules)
                else
                  _buildMobile3ColGrid(modules),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, String category) {
    final active = _selectedCategory == category;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? Colors.white : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMobile3ColGrid(List<ModuleItem> modules) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: m.builder)),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: m.iconBgColor ?? m.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m.icon, color: m.color, size: 20),
                ),
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.subtitlePill,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopGrid(List<ModuleItem> modules) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: m.builder)),
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
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: m.iconBgColor ?? m.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.subtitlePill,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.description,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 28, color: AppTheme.outline),
          ),
          const SizedBox(height: 12),
          const Text(
            'No modules found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching for terms like "UPI", "Gate", "Gym" or "Plumber"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondaryContainer,
              foregroundColor: AppTheme.onSecondaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _selectedCategory = 'all');
            },
            child: const Text('Clear Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
