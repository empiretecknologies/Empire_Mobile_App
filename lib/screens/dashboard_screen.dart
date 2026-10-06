import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../services/auth_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.summary});

  final DashboardSummary summary;

  Future<void> _signOut(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 600 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Column(
        children: [
          _DashboardHeader(
            username: session.username ?? '',
            onSignOut: () => _signOut(context),
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
                      value: _formatNumber(summary.sodaBookFeedingCount),
                    ),
                    _MetricCard(
                      icon: Icons.local_shipping_outlined,
                      label: 'Delivery Feeding',
                      value: _formatNumber(summary.deliveryFeedingCount),
                    ),
                    _MetricCard(
                      icon: Icons.pending_actions_outlined,
                      label: 'Pending Delivery',
                      value: _formatNumber(summary.pickedDeliveryCount),
                    ),
                    _MetricCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Outstanding Balance',
                      value: _formatNumber(summary.outstandingBalance),
                    ),
                  ],
                ),
                if (summary.outstandingBalances.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _BalanceTable(items: summary.outstandingBalances),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final withCommas = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return negative ? '-$withCommas' : withCommas;
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.username,
    required this.onSignOut,
  });

  final String username;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 12,
        8,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestDeep, AppColors.forestMid],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.onForest.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.lime),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MQT Dashboard',
                  style: TextStyle(
                    color: AppColors.onForest,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  username.isEmpty ? 'Mast Qalander' : 'Welcome, $username',
                  style: const TextStyle(
                    color: AppColors.limeSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: AppColors.onForest),
          ),
        ],
      ),
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
        color: AppColors.card,
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
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
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
                  style: const TextStyle(
                    color: AppColors.textMuted,
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
  const _BalanceTable({required this.items});

  final List<OutstandingBalanceItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
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
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0xFFE8EEE8)),
            _BalanceRow(
              city: items[i].accountName.isEmpty ? '-' : items[i].accountName,
              balance: items[i].balance,
              shaded: i.isOdd,
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
  });

  final String city;
  final num balance;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    return ColoredBox(
      color: shaded ? const Color(0xFFF7FAF7) : AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                city,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatNumber(balance),
              style: TextStyle(
                color: isNegative ? const Color(0xFFC62828) : AppColors.forest,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
