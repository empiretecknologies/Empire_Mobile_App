import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _categories = [
    (Icons.grain, 'Grains'),
    (Icons.water_drop_outlined, 'Oilseeds'),
    (Icons.spa_outlined, 'Pulses'),
    (Icons.local_fire_department_outlined, 'Spices'),
    (Icons.eco_outlined, 'Chickpeas'),
    (Icons.pets_outlined, 'Feed'),
    (Icons.apple_outlined, 'Dryfruits'),
  ];

  static const _services = [
    'Origination',
    'Processing',
    'Branding',
    'Merchandising',
    'Distribution',
  ];

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
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;

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
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Established Since',
                        value: '1975',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _YearsCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Product Categories'),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 600
                      ? 4
                      : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    for (final item in _categories)
                      _CategoryCard(icon: item.$1, label: item.$2),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Services'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final service in _services) _ServiceChip(service),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Head Office · Suite # 1602, 16th Floor, Muhammadi Trade Tower, New Chali, Karachi, Pakistan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.onForest, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onForest,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearsCard extends StatelessWidget {
  const _YearsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lime, width: 1.4),
      ),
      child: const Column(
        children: [
          Text(
            '50',
            style: TextStyle(
              color: AppColors.forest,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'YEARS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.forest, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.forest,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
