import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/dashboard_summary.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/branded_shell.dart';
import '../widgets/page_header.dart';
import 'city_outstanding_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onMenu, this.initialSummary});

  final DashboardSummary? initialSummary;
  final VoidCallback onMenu;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();

  bool _countsLoading = true;
  bool _balancesLoading = true;
  bool _balanceFromOutstanding = false;
  bool _leaving = false;
  String? _countsError;
  String? _balancesError;
  num? _soda;
  num? _delivery;
  num? _pending;
  num? _outstanding;
  List<OutstandingBalanceItem> _balances = const [];

  bool get _backgroundLoading => _countsLoading || _balancesLoading;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSummary;
    if (initial != null) {
      _soda = initial.sodaBookFeedingCount;
      _delivery = initial.deliveryFeedingCount;
      _pending = initial.pickedDeliveryCount;
      _outstanding = initial.outstandingBalance;
      _balances = initial.outstandingBalances;
      _countsLoading = false;
      _balancesLoading = false;
      return;
    }
    unawaited(_saveContext());
    unawaited(_loadCounts());
    unawaited(_loadOutstanding());
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

  Future<void> _loadCounts() async {
    if (!_countsLoading && mounted) {
      setState(() {
        _countsLoading = true;
        _countsError = null;
      });
    }
    try {
      final counts = await _dashboardService.getCounts();
      if (!mounted) return;
      setState(() {
        _soda = counts.sodaBookFeedingCount;
        _delivery = counts.deliveryFeedingCount;
        _pending = counts.pickedDeliveryCount;
        if (counts.outstandingBalance != null && !_balanceFromOutstanding) {
          _outstanding = counts.outstandingBalance;
        }
        _countsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      setState(() {
        _countsLoading = false;
        _countsError = error.message;
      });
    }
  }

  Future<void> _loadOutstanding() async {
    if (!_balancesLoading && mounted) {
      setState(() {
        _balancesLoading = true;
        _balancesError = null;
      });
    }
    try {
      final outstanding = await _dashboardService.getOutstanding();
      if (!mounted) return;
      setState(() {
        _balances = outstanding.items;
        if (outstanding.outstandingBalance != null) {
          _outstanding = outstanding.outstandingBalance;
          _balanceFromOutstanding = true;
        }
        _balancesLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      setState(() {
        _balancesLoading = false;
        _balancesError = error.message;
      });
    }
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

  void _openCity(String city) {
    final name = city.trim();
    if (name.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CityOutstandingScreen(city: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 600 ? 28.0 : 16.0;
    final username = session.username ?? '';
    final showBalances =
        _balancesLoading || _balancesError != null || _balances.isNotEmpty;

    return Column(
      children: [
        PageHeader(
          title: 'MQT Dashboard',
          subtitle: username.isEmpty ? 'Mast Qalander' : 'Welcome, $username',
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            children: [
              _SessionStrip(
                company: session.company?.name ?? '-',
                branch: session.branch?.name ?? '-',
                period: session.period?.name ?? '-',
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width >= 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: width >= 600 ? 1.35 : 1.18,
                children: [
                  _MetricCard(
                    icon: Icons.menu_book_outlined,
                    label: 'Soda Book Feeding',
                    value: _metricValue(_soda, _countsLoading),
                    loading: _soda == null && _countsLoading,
                  ),
                  _MetricCard(
                    icon: Icons.local_shipping_outlined,
                    label: 'Delivery Feeding',
                    value: _metricValue(_delivery, _countsLoading),
                    loading: _delivery == null && _countsLoading,
                  ),
                  _MetricCard(
                    icon: Icons.pending_actions_outlined,
                    label: 'Pending Delivery',
                    value: _metricValue(_pending, _countsLoading),
                    loading: _pending == null && _countsLoading,
                  ),
                  _MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Outstanding Balance',
                    value: _metricValue(
                      _outstanding,
                      _countsLoading || _balancesLoading,
                    ),
                    loading:
                        _outstanding == null &&
                        (_countsLoading || _balancesLoading),
                  ),
                ],
              ),
              if (_countsError != null) ...[
                const SizedBox(height: 8),
                _SectionMessage(
                  message: _countsError!,
                  onRetry: () {
                    _loadCounts();
                  },
                ),
              ],
              if (showBalances) ...[
                const SizedBox(height: 16),
                _BalanceTable(
                  items: _balances,
                  loading: _balancesLoading && _balances.isEmpty,
                  error: _balancesError,
                  onRetry: () {
                    _loadOutstanding();
                  },
                  onCity: _openCity,
                ),
              ],
              const SizedBox(height: 28),
              const PoweredByFooter(),
            ],
          ),
        ),
      ],
    );
  }

  String _metricValue(num? value, bool loading) {
    if (value == null) return loading ? '' : '-';
    return formatDashboardNumber(value);
  }
}

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
        PopupMenuItem<String>(
          value: 'profile',
          child: _ProfileMenuRow(icon: Icons.person_outline, label: 'Profile'),
        ),
        PopupMenuItem<String>(
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.forest, size: 18),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forest,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCity,
  });

  final List<OutstandingBalanceItem> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<String> onCity;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.forest.withValues(alpha: 0.08),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'City',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Balance',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 22),
              ],
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forest,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading balances...',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SectionMessage(message: error!, onRetry: onRetry),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: AppTheme.dividerColor(context)),
              _BalanceRow(
                city: items[i].accountName,
                balance: items[i].balance,
                shaded: i.isOdd,
                onTap: () => onCity(items[i].accountName),
              ),
            ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.city,
    required this.balance,
    required this.shaded,
    required this.onTap,
  });

  final String city;
  final num balance;
  final bool shaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: shaded
            ? AppTheme.zebraColor(context)
            : AppTheme.cardColor(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  city,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatDashboardNumber(balance),
                style: TextStyle(
                  color: isNegative
                      ? const Color(0xFFC62828)
                      : AppColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.secondaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
