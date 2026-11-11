import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/dashboard_summary.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/branded_shell.dart';
import '../widgets/page_header.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

const _durations = <({String key, String label})>[
  (key: 'Today', label: 'Today'),
  (key: 'Week', label: 'Week'),
  (key: 'Month', label: 'Month'),
  (key: 'Last3Months', label: 'Last 3 Months'),
  (key: 'Last6Months', label: 'Last 6 Months'),
];

const _donutColors = <Color>[
  Color(0xFF0E6B38),
  Color(0xFF157A40),
  Color(0xFF2E7D32),
  Color(0xFF43A047),
  Color(0xFF66BB6A),
  Color(0xFF81C784),
  Color(0xFFA5D6A7),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onMenu, this.initialSummary});

  final DashboardSummary? initialSummary;
  final VoidCallback onMenu;

  // initialSummary is kept so MainShell can pass the previous payload
  // without a constructor break; the web dashboard loads live APIs instead.

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();

  final _funds = _Slot<DashboardKpi>();
  final _receivable = _Slot<DashboardKpi>();
  final _pendingOrders = _Slot<DashboardKpi>();
  final _delivery = _Slot<DashboardKpi>();
  final _flowIn = _Slot<DashboardKpi>();
  final _flowOut = _Slot<DashboardKpi>();
  final _totalSales = _Slot<DashboardChartSeries>();
  final _salesByCategory = _Slot<DashboardChartSeries>();
  final _dailyReceived = _Slot<DashboardChartSeries>();
  final _parties = _Slot<DashboardGrid>();
  final _saleOrders = _Slot<DashboardGrid>();
  final _stock = _Slot<DashboardGrid>();

  String _duration = 'Month';
  late DateTime _fromDate;
  late DateTime _toDate;
  DateTime? _lastUpdated;
  bool _leaving = false;

  bool get _backgroundLoading => [
    _funds,
    _receivable,
    _pendingOrders,
    _delivery,
    _flowIn,
    _flowOut,
    _totalSales,
    _salesByCategory,
    _dailyReceived,
    _parties,
    _saleOrders,
    _stock,
  ].any((slot) => slot.loading);

  @override
  void initState() {
    super.initState();
    final range = _rangeFor(_duration);
    _fromDate = range.from;
    _toDate = range.to;
    if (!AppSession.instance.isLoggedIn) {
      for (final slot in [
        _funds,
        _receivable,
        _pendingOrders,
        _delivery,
        _flowIn,
        _flowOut,
        _totalSales,
        _salesByCategory,
        _dailyReceived,
        _parties,
        _saleOrders,
        _stock,
      ]) {
        slot.loading = false;
      }
      return;
    }
    unawaited(_saveContext());
    _loadAll();
  }

  ({DateTime from, DateTime to}) _rangeFor(String duration) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    switch (duration) {
      case 'Today':
        start = today;
      case 'Week':
        start = today.subtract(const Duration(days: 6));
      case 'Last3Months':
        start = DateTime(
          today.year,
          today.month - 3,
          today.day,
        ).add(const Duration(days: 1));
      case 'Last6Months':
        start = DateTime(
          today.year,
          today.month - 6,
          today.day,
        ).add(const Duration(days: 1));
      case 'Month':
      default:
        start = DateTime(
          today.year,
          today.month - 1,
          today.day,
        ).add(const Duration(days: 1));
    }
    return (from: start, to: today);
  }

  Future<void> _saveContext() async {
    final session = AppSession.instance;
    try {
      await AuthService().saveContext(
        company: '${session.ccode}',
        branch: '${session.bcode}',
        period: '${session.pid}',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) _leave();
    }
  }

  void _loadAll() {
    _lastUpdated = DateTime.now();
    unawaited(
      _loadSlot(
        _funds,
        () => _dashboardService.getAvailableFunds(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _receivable,
        () => _dashboardService.getNetReceivablePayable(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _pendingOrders,
        () => _dashboardService.getPendingOrdersCount(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _delivery,
        () => _dashboardService.getTotalDelivery(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _flowIn,
        () => _dashboardService.getCashBankFlowIn(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _flowOut,
        () => _dashboardService.getCashBankFlowOut(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _totalSales,
        () => _dashboardService.getTotalSales(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _salesByCategory,
        () => _dashboardService.getSalesByCategory(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _dailyReceived,
        () => _dashboardService.getDailyReceived(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _parties,
        () => _dashboardService.getPartyReceivablesPayables(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _saleOrders,
        () => _dashboardService.getPendingSaleOrders(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
    unawaited(
      _loadSlot(
        _stock,
        () => _dashboardService.getStockMovement(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final range = _rangeFor(_duration);
    _fromDate = range.from;
    _toDate = range.to;
    _loadAll();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    while (mounted && _backgroundLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _loadSlot<T>(_Slot<T> slot, Future<T> Function() load) async {
    if (!mounted) return;
    setState(() {
      slot.loading = true;
      slot.error = null;
    });
    try {
      final data = await load();
      if (!mounted) return;
      setState(() {
        slot.data = data;
        slot.loading = false;
        _lastUpdated = DateTime.now();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      setState(() {
        slot.loading = false;
        slot.error = error.message;
      });
    }
  }

  void _changeDuration(String duration) {
    if (duration == _duration) return;
    final range = _rangeFor(duration);
    setState(() {
      _duration = duration;
      _fromDate = range.from;
      _toDate = range.to;
    });
    _loadAll();
  }

  Future<void> _signOut() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    AppSession.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  void _openKpi(_KpiSpec spec, _Slot<DashboardKpi> slot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DashboardKpiPage(spec: spec, slot: slot),
      ),
    );
  }

  void _openChart({
    required String title,
    required IconData icon,
    required _Slot<DashboardChartSeries> slot,
    required _ChartKind kind,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DashboardChartPage(
          title: title,
          icon: icon,
          slot: slot,
          kind: kind,
        ),
      ),
    );
  }

  void _openGrid({
    required String title,
    required IconData icon,
    required _Slot<DashboardGrid> slot,
    required _GridKind kind,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DashboardGridPage(
          title: title,
          icon: icon,
          slot: slot,
          kind: kind,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 600 ? 28.0 : 16.0;
    final username = session.username ?? '';

    return Column(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: username.isEmpty
              ? 'Business Overview'
              : 'Welcome, $username',
          onMenu: widget.onMenu,
          trailing: _ProfileMenu(onProfile: _openProfile, onLogout: _signOut),
        ),
        if (_backgroundLoading)
          const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.lime,
            backgroundColor: AppColors.forestMid,
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.forest,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
              children: [
                _SessionStrip(
                  company: session.company?.name ?? '-',
                  branch: session.branch?.name ?? '-',
                  period: session.period?.name ?? '-',
                ),
                const SizedBox(height: 12),
                _RangeBar(
                  from: _fromDate,
                  to: _toDate,
                  duration: _duration,
                  lastUpdated: _lastUpdated,
                  onDuration: _changeDuration,
                ),
                const SizedBox(height: 16),
                _kpiSection(width),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Total Sales',
                  icon: Icons.bar_chart_rounded,
                  slot: _totalSales,
                  kind: _ChartKind.bars,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _totalSales,
                      () => _dashboardService.getTotalSales(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onDetails: () => _openChart(
                    title: 'Total Sales',
                    icon: Icons.bar_chart_rounded,
                    slot: _totalSales,
                    kind: _ChartKind.bars,
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Sales by Item Category',
                  icon: Icons.donut_large_rounded,
                  slot: _salesByCategory,
                  kind: _ChartKind.donut,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _salesByCategory,
                      () => _dashboardService.getSalesByCategory(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onDetails: () => _openChart(
                    title: 'Sales by Item Category',
                    icon: Icons.donut_large_rounded,
                    slot: _salesByCategory,
                    kind: _ChartKind.donut,
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Daily Received Amounts',
                  icon: Icons.show_chart_rounded,
                  slot: _dailyReceived,
                  kind: _ChartKind.area,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _dailyReceived,
                      () => _dashboardService.getDailyReceived(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onDetails: () => _openChart(
                    title: 'Daily Received Amounts',
                    icon: Icons.show_chart_rounded,
                    slot: _dailyReceived,
                    kind: _ChartKind.area,
                  ),
                ),
                const SizedBox(height: 16),
                _GridCard(
                  title: 'Party Receivables & Payables',
                  icon: Icons.groups_outlined,
                  slot: _parties,
                  kind: _GridKind.party,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _parties,
                      () => _dashboardService.getPartyReceivablesPayables(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onViewAll: () => _openGrid(
                    title: 'Party Receivables & Payables',
                    icon: Icons.groups_outlined,
                    slot: _parties,
                    kind: _GridKind.party,
                  ),
                ),
                const SizedBox(height: 16),
                _GridCard(
                  title: 'Pending Orders',
                  icon: Icons.inventory_2_outlined,
                  slot: _saleOrders,
                  kind: _GridKind.orders,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _saleOrders,
                      () => _dashboardService.getPendingSaleOrders(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onViewAll: () => _openGrid(
                    title: 'Pending Orders',
                    icon: Icons.inventory_2_outlined,
                    slot: _saleOrders,
                    kind: _GridKind.orders,
                  ),
                ),
                const SizedBox(height: 16),
                _GridCard(
                  title: 'Total Stock Movement',
                  icon: Icons.swap_horiz_rounded,
                  slot: _stock,
                  kind: _GridKind.stock,
                  onRetry: () => unawaited(
                    _loadSlot(
                      _stock,
                      () => _dashboardService.getStockMovement(
                        duration: _duration,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  ),
                  onViewAll: () => _openGrid(
                    title: 'Total Stock Movement',
                    icon: Icons.swap_horiz_rounded,
                    slot: _stock,
                    kind: _GridKind.stock,
                  ),
                ),
                const SizedBox(height: 28),
                const PoweredByFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiSection(double width) {
    final specs = <(_KpiSpec, _Slot<DashboardKpi>)>[
      (
        const _KpiSpec(
          icon: Icons.account_balance_outlined,
          label: 'Over All Available Funds',
          caption: 'Cash & Banks',
          money: true,
        ),
        _funds,
      ),
      (
        const _KpiSpec(
          icon: Icons.balance_outlined,
          label: 'Net Receivable & Payable',
          caption: 'Outstanding',
          money: true,
        ),
        _receivable,
      ),
      (
        const _KpiSpec(
          icon: Icons.shopping_bag_outlined,
          label: 'Total Pending Orders',
          caption: 'Open Orders',
          money: false,
        ),
        _pendingOrders,
      ),
      (
        const _KpiSpec(
          icon: Icons.local_shipping_outlined,
          label: 'Total Delivery',
          caption: 'Open Deliveries',
          money: false,
        ),
        _delivery,
      ),
      (
        const _KpiSpec(
          icon: Icons.trending_up_rounded,
          label: 'Cash & Bank Flow In (Debit)',
          caption: 'Inflow',
          money: true,
        ),
        _flowIn,
      ),
      (
        const _KpiSpec(
          icon: Icons.trending_down_rounded,
          label: 'Cash & Bank Flow Out (Credit)',
          caption: 'Outflow',
          money: true,
        ),
        _flowOut,
      ),
    ];
    final columns = width >= 900 ? 3 : 2;
    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: i + j < specs.length
                      ? _KpiCard(
                          spec: specs[i + j].$1,
                          slot: specs[i + j].$2,
                          onRetry: () {
                            unawaited(_reloadKpi(specs[i + j].$2));
                          },
                          onDetails: () =>
                              _openKpi(specs[i + j].$1, specs[i + j].$2),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + columns < specs.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Future<void> _reloadKpi(_Slot<DashboardKpi> slot) {
    if (slot == _funds) {
      return _loadSlot(
        _funds,
        () => _dashboardService.getAvailableFunds(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
    }
    if (slot == _receivable) {
      return _loadSlot(
        _receivable,
        () => _dashboardService.getNetReceivablePayable(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
    }
    if (slot == _pendingOrders) {
      return _loadSlot(
        _pendingOrders,
        () => _dashboardService.getPendingOrdersCount(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
    }
    if (slot == _delivery) {
      return _loadSlot(
        _delivery,
        () => _dashboardService.getTotalDelivery(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
    }
    if (slot == _flowIn) {
      return _loadSlot(
        _flowIn,
        () => _dashboardService.getCashBankFlowIn(
          duration: _duration,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
    }
    return _loadSlot(
      _flowOut,
      () => _dashboardService.getCashBankFlowOut(
        duration: _duration,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }
}

class _Slot<T> {
  bool loading = true;
  String? error;
  T? data;
}

class _KpiSpec {
  const _KpiSpec({
    required this.icon,
    required this.label,
    required this.caption,
    required this.money,
  });

  final IconData icon;
  final String label;
  final String caption;
  final bool money;
}

enum _ChartKind { bars, donut, area }

enum _GridKind { party, orders, stock }

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.onProfile, required this.onLogout});

  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Profile',
      position: PopupMenuPosition.under,
      color: AppTheme.cardColor(context),
      icon: const Icon(Icons.person, color: AppColors.onForest),
      onSelected: (value) {
        if (value == 'profile') onProfile();
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: _ProfileMenuRow(icon: Icons.person_outline, label: 'Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: _ProfileMenuRow(icon: Icons.logout, label: 'Logout'),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forest;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryText(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _SessionStrip extends StatelessWidget {
  const _SessionStrip({
    required this.company,
    required this.branch,
    required this.period,
  });

  final String company;
  final String branch;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _SessionRow(label: 'Company', value: company),
          const Divider(height: 16),
          _SessionRow(label: 'Branch', value: branch),
          const Divider(height: 16),
          _SessionRow(label: 'Period', value: period),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.primaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.from,
    required this.to,
    required this.duration,
    required this.lastUpdated,
    required this.onDuration,
  });

  final DateTime from;
  final DateTime to;
  final String duration;
  final DateTime? lastUpdated;
  final ValueChanged<String> onDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppColors.forest,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${formatDashboardDate(from)} - ${formatDashboardDate(to)}',
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor(context)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: duration,
                    isDense: true,
                    borderRadius: BorderRadius.circular(10),
                    dropdownColor: AppTheme.cardColor(context),
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      for (final item in _durations)
                        DropdownMenuItem<String>(
                          value: item.key,
                          child: Text(item.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onDuration(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${formatDashboardDateTime(lastUpdated!)}',
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.spec,
    required this.slot,
    required this.onRetry,
    required this.onDetails,
    this.showDetails = true,
  });

  final _KpiSpec spec;
  final _Slot<DashboardKpi> slot;
  final VoidCallback onRetry;
  final VoidCallback onDetails;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final value = slot.data?.value;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: AppColors.forest),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(spec.icon, color: AppColors.forest, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  spec.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                if (slot.loading && value == null)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forest,
                    ),
                  )
                else if (slot.error != null && value == null)
                  Text(
                    'Unavailable',
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value == null
                          ? '-'
                          : spec.money
                          ? formatDashboardRs(value)
                          : formatDashboardNumber(value),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  spec.caption,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (slot.error != null && value == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Retry'),
                    ),
                  )
                else if (showDetails)
                  TextButton(
                    onPressed: onDetails,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View Details  →'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.slot,
    required this.kind,
    required this.onRetry,
    required this.onDetails,
    this.expanded = false,
    this.showAction = true,
  });

  final String title;
  final IconData icon;
  final _Slot<DashboardChartSeries> slot;
  final _ChartKind kind;
  final VoidCallback onRetry;
  final VoidCallback onDetails;
  final bool expanded;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final series = slot.data;
    return _DashboardPanel(
      icon: icon,
      title: title,
      actionLabel: showAction ? 'View Details  →' : '',
      onAction: onDetails,
      child: SizedBox(
        height: expanded
            ? 280
            : kind == _ChartKind.donut
            ? 230
            : 210,
        child: slot.loading && series == null
            ? const _SectionLoader(label: 'Loading chart...')
            : slot.error != null && (series == null || series.points.isEmpty)
            ? _SectionMessage(message: slot.error!, onRetry: onRetry)
            : series == null || series.points.isEmpty
            ? const _EmptyHint(label: 'No data for this period')
            : kind == _ChartKind.donut
            ? _DonutChartView(series: series)
            : _XyChartView(series: series, kind: kind),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.title,
    required this.icon,
    required this.slot,
    required this.kind,
    required this.onRetry,
    required this.onViewAll,
  });

  final String title;
  final IconData icon;
  final _Slot<DashboardGrid> slot;
  final _GridKind kind;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final grid = slot.data;
    final records = grid?.records ?? const [];
    final visible = records.take(4).toList();
    return _DashboardPanel(
      icon: icon,
      title: title,
      actionLabel: 'View All  →',
      onAction: onViewAll,
      child: slot.loading && grid == null
          ? const _SectionLoader(label: 'Loading records...')
          : slot.error != null && records.isEmpty
          ? _SectionMessage(message: slot.error!, onRetry: onRetry)
          : records.isEmpty
          ? const _EmptyHint(label: 'No records for this period')
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppTheme.dividerColor(context)),
                  _GridRecordTile(
                    grid: grid!,
                    record: visible[i],
                    kind: kind,
                    shaded: i.isOdd,
                  ),
                ],
              ],
            ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.forest, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (actionLabel.isNotEmpty)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(actionLabel),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.secondaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GridRecordTile extends StatelessWidget {
  const _GridRecordTile({
    required this.grid,
    required this.record,
    required this.kind,
    required this.shaded,
  });

  final DashboardGrid grid;
  final Map<String, String> record;
  final _GridKind kind;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: shaded
          ? AppTheme.zebraColor(context)
          : AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: _row(context),
      ),
    );
  }

  Widget _row(BuildContext context) {
    switch (kind) {
      case _GridKind.party:
        return _party(context);
      case _GridKind.orders:
        return _order(context);
      case _GridKind.stock:
        return _stock(context);
    }
  }

  Widget _party(BuildContext context) {
    final name = grid.cell(record, const [
      'party name',
      'party',
      'account name',
      'name',
    ]);
    final outstanding = grid.cell(record, const [
      'outstanding',
      'balance',
      'amount',
    ]);
    final lastDate = grid.cell(record, const [
      'last received date',
      'received date',
    ]);
    final lastAmount = grid.cell(record, const [
      'last received amount',
      'received amount',
    ]);
    final due = grid.cell(record, const ['due date', 'due']);
    final status = grid.cell(record, const ['due status', 'status']);
    if (name.isEmpty && outstanding.isEmpty) {
      return _generic(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? '-' : name,
                style: TextStyle(
                  color: AppTheme.primaryText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (status.isNotEmpty) _StatusBadge(label: status),
          ],
        ),
        const SizedBox(height: 6),
        _meta(context, 'Outstanding', outstanding),
        if (lastDate.isNotEmpty || lastAmount.isNotEmpty)
          _meta(
            context,
            'Last received',
            [
              lastDate,
              lastAmount,
            ].where((part) => part.isNotEmpty).join('  ·  '),
          ),
        if (due.isNotEmpty) _meta(context, 'Due date', due),
      ],
    );
  }

  Widget _order(BuildContext context) {
    final order = grid.cell(record, const [
      'order #',
      'order no',
      'orderno',
      'voucher',
      'order',
    ]);
    final buyer = grid.cell(record, const [
      'buyer',
      'party',
      'customer',
      'account',
    ]);
    final date = grid.cell(record, const ['date', 'order date']);
    final qty = grid.cell(record, const ['qty (kg)', 'qty', 'quantity']);
    final status = grid.cell(record, const ['status']);
    if (order.isEmpty && buyer.isEmpty) return _generic(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.isEmpty ? '-' : order,
                style: TextStyle(
                  color: AppTheme.primaryText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (status.isNotEmpty) _StatusBadge(label: status),
          ],
        ),
        if (buyer.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            buyer,
            style: TextStyle(
              color: AppTheme.primaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          [
            date,
            if (qty.isNotEmpty) '$qty kg',
          ].where((part) => part.isNotEmpty).join('  ·  '),
          style: TextStyle(
            color: AppTheme.secondaryText(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _stock(BuildContext context) {
    final order = grid.cell(record, const [
      'order #',
      'order no',
      'orderno',
      'voucher',
      'order',
    ]);
    final buyer = grid.cell(record, const ['buyer', 'party', 'customer']);
    final seller = grid.cell(record, const ['seller']);
    final date = grid.cell(record, const ['date']);
    final qty = grid.cell(record, const ['qty (kg)', 'qty', 'quantity']);
    final product = grid.cell(record, const [
      'product name',
      'product',
      'item',
      'item name',
    ]);
    if (order.isEmpty && buyer.isEmpty && product.isEmpty) {
      return _generic(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.isEmpty ? '-' : order,
          style: TextStyle(
            color: AppTheme.primaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (buyer.isNotEmpty || seller.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [buyer, if (seller.isNotEmpty) seller].join('  →  '),
            style: TextStyle(
              color: AppTheme.primaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          [
            date,
            if (qty.isNotEmpty) '$qty kg',
            product,
          ].where((part) => part.isNotEmpty).join('  ·  '),
          style: TextStyle(
            color: AppTheme.secondaryText(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _generic(BuildContext context) {
    final entries = [
      for (final column in grid.columns)
        if ((record[column] ?? '').trim().isNotEmpty)
          MapEntry(column, record[column]!.trim()),
    ];
    final shown = entries.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _meta(context, entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryText(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final key = label.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    Color color = const Color(0xFF6F6F6F);
    if (key.contains('overdue') ||
        key.contains('undelivered') ||
        key == 'pending') {
      color = const Color(0xFFD32F2F);
    } else if (key.contains('upcoming') ||
        key.contains('partial') ||
        key.contains('weightslip')) {
      color = const Color(0xFFEF6C00);
    } else if (key.contains('complete') || key == 'clear' || key == 'current') {
      color = const Color(0xFF2E7D32);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _XyChartView extends StatelessWidget {
  const _XyChartView({required this.series, required this.kind});

  final DashboardChartSeries series;
  final _ChartKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
      child: CustomPaint(
        painter: _XyChartPainter(
          points: series.points,
          kind: kind,
          axisColor: AppTheme.secondaryText(context),
          gridColor: AppTheme.dividerColor(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DonutChartView extends StatelessWidget {
  const _DonutChartView({required this.series});

  final DashboardChartSeries series;

  @override
  Widget build(BuildContext context) {
    final points = series.points;
    final total =
        series.total ??
        points.fold<num>(0, (sum, point) => sum + point.sliceValue.abs());
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _DonutPainter(points: points),
                  child: const SizedBox.expand(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDashboardRs(total),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Total Sales',
                        style: TextStyle(
                          color: AppTheme.secondaryText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < points.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: _pointColor(points[i], i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            points[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.primaryText(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${_percent(points[i], points).round()}%',
                          style: TextStyle(
                            color: AppTheme.secondaryText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardKpiPage extends StatelessWidget {
  const _DashboardKpiPage({required this.spec, required this.slot});

  final _KpiSpec spec;
  final _Slot<DashboardKpi> slot;

  @override
  Widget build(BuildContext context) {
    final value = slot.data?.value;
    final details = slot.data?.details ?? const [];
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.forestDeep,
        foregroundColor: AppColors.onForest,
        title: Text(spec.label),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _KpiCard(
            spec: spec,
            slot: slot,
            onRetry: () {},
            onDetails: () {},
            showDetails: false,
          ),
          if (details.length > 1) ...[
            const SizedBox(height: 16),
            _DashboardPanel(
              icon: spec.icon,
              title: 'Details',
              actionLabel: '',
              onAction: () {},
              child: Column(
                children: [
                  for (var i = 0; i < details.length; i++)
                    _GridRecordTile(
                      grid: DashboardGrid.from(details),
                      record: {
                        for (final entry in details[i].entries)
                          entry.key.toString(): formatDashboardCell(
                            entry.value,
                          ),
                      },
                      kind: _GridKind.party,
                      shaded: i.isOdd,
                    ),
                ],
              ),
            ),
          ] else if (value != null) ...[
            const SizedBox(height: 16),
            Text(
              spec.caption,
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardChartPage extends StatelessWidget {
  const _DashboardChartPage({
    required this.title,
    required this.icon,
    required this.slot,
    required this.kind,
  });

  final String title;
  final IconData icon;
  final _Slot<DashboardChartSeries> slot;
  final _ChartKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.forestDeep,
        foregroundColor: AppColors.onForest,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ChartCard(
            title: title,
            icon: icon,
            slot: slot,
            kind: kind,
            expanded: true,
            showAction: false,
            onRetry: () {},
            onDetails: () {},
          ),
        ],
      ),
    );
  }
}

class _DashboardGridPage extends StatefulWidget {
  const _DashboardGridPage({
    required this.title,
    required this.icon,
    required this.slot,
    required this.kind,
  });

  final String title;
  final IconData icon;
  final _Slot<DashboardGrid> slot;
  final _GridKind kind;

  @override
  State<_DashboardGridPage> createState() => _DashboardGridPageState();
}

class _DashboardGridPageState extends State<_DashboardGridPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final grid = widget.slot.data ?? const DashboardGrid();
    final records = [
      for (final record in grid.records)
        if (_query.trim().isEmpty ||
            record.values.any(
              (value) => value.toLowerCase().contains(_query.toLowerCase()),
            ))
          record,
    ];
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.forestDeep,
        foregroundColor: AppColors.onForest,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : index == records.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          color: AppTheme.dividerColor(context),
                        ),
                      _GridRecordTile(
                        grid: grid,
                        record: records[index],
                        kind: widget.kind,
                        shaded: index.isOdd,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _XyChartPainter extends CustomPainter {
  _XyChartPainter({
    required this.points,
    required this.kind,
    required this.axisColor,
    required this.gridColor,
  });

  final List<DashboardChartPoint> points;
  final _ChartKind kind;
  final Color axisColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 42.0;
    const bottom = 28.0;
    const top = 12.0;
    const right = 8.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    final maxValue = points.fold<num>(0, (value, point) {
      final peak = math.max(point.value.abs(), (point.trend ?? 0).abs());
      return math.max(value, peak);
    });
    final ceiling = maxValue == 0 ? 1.0 : maxValue.toDouble() * 1.1;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: axisColor, fontSize: 9);
    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * (i / 4);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = formatCompactAxis(ceiling * (i / 4));
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: left - 4);
      painter.paint(
        canvas,
        Offset(left - painter.width - 6, y - painter.height / 2),
      );
    }

    final n = points.length;
    final barWidth = chart.width / math.max(n * 1.6, 1);
    final barPaint = Paint()..color = AppColors.forest;
    final linePaint = Paint()
      ..color = kind == _ChartKind.area ? AppColors.forest : AppColors.limeSoft
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final path = Path();
    Offset? first;
    Offset? last;

    for (var i = 0; i < n; i++) {
      final x = n == 1
          ? chart.left + chart.width / 2
          : chart.left + chart.width * (i / (n - 1));
      final barX = n == 1
          ? chart.left + (chart.width - barWidth) / 2
          : chart.left +
                (chart.width / n) * i +
                (chart.width / n - barWidth) / 2;
      final y =
          chart.bottom - chart.height * (points[i].value.toDouble() / ceiling);
      if (kind == _ChartKind.bars) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, y, barWidth, chart.bottom - y),
            const Radius.circular(4),
          ),
          barPaint,
        );
      }
      final trendValue = (points[i].trend ?? points[i].value).toDouble();
      final ty = chart.bottom - chart.height * (trendValue / ceiling);
      final point = Offset(
        kind == _ChartKind.bars ? barX + barWidth / 2 : x,
        ty,
      );
      if (first == null) {
        path.moveTo(point.dx, point.dy);
        first = point;
      } else {
        path.lineTo(point.dx, point.dy);
      }
      last = point;

      final labelPainter = TextPainter(
        text: TextSpan(text: points[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(chart.width / n - 2, 28));
      labelPainter.paint(
        canvas,
        Offset(
          (kind == _ChartKind.bars ? barX + barWidth / 2 : x) -
              labelPainter.width / 2,
          chart.bottom + 6,
        ),
      );
    }

    if (kind == _ChartKind.area && first != null && last != null) {
      final fill = Path.from(path)
        ..lineTo(last.dx, chart.bottom)
        ..lineTo(first.dx, chart.bottom)
        ..close();
      canvas.drawPath(fill, fillPaint);
    }
    if (kind == _ChartKind.area || points.any((point) => point.trend != null)) {
      canvas.drawPath(path, linePaint);
      final dot = Paint()..color = linePaint.color;
      for (var i = 0; i < n; i++) {
        final x = n == 1
            ? chart.left + chart.width / 2
            : chart.left + chart.width * (i / (n - 1));
        final barX = n == 1
            ? chart.left + (chart.width - barWidth) / 2
            : chart.left +
                  (chart.width / n) * i +
                  (chart.width / n - barWidth) / 2;
        final trendValue = (points[i].trend ?? points[i].value).toDouble();
        final ty = chart.bottom - chart.height * (trendValue / ceiling);
        canvas.drawCircle(
          Offset(kind == _ChartKind.bars ? barX + barWidth / 2 : x, ty),
          3.2,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _XyChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.kind != kind ||
        oldDelegate.axisColor != axisColor;
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.points});

  final List<DashboardChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.fold<num>(
      0,
      (sum, point) => sum + point.sliceValue.abs(),
    );
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: side / 2 - 6,
    );
    var start = -math.pi / 2;
    if (total <= 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = const Color(0xFFE0E0E0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.18,
      );
      return;
    }
    for (var i = 0; i < points.length; i++) {
      final sweep = (points[i].sliceValue.abs() / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = _pointColor(points[i], i)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = side * 0.18,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

Color _pointColor(DashboardChartPoint point, int index) {
  final parsed = _parseColor(point.color);
  if (parsed != null) return parsed;
  return _donutColors[index % _donutColors.length];
}

Color? _parseColor(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var hex = raw.trim().replaceAll('#', '').replaceAll('0x', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

num _percent(DashboardChartPoint point, List<DashboardChartPoint> points) {
  if (point.percentage != null) return point.percentage!;
  if (point.trend != null) return point.value;
  final total = points.fold<num>(0, (sum, item) => sum + item.sliceValue.abs());
  if (total == 0) return 0;
  return point.sliceValue.abs() / total * 100;
}
