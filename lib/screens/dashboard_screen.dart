import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/branded_shell.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.username});

  final String username;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _companies = ['Mast Qalander Traders'];
  static const _branches = ['Mast Qalander Traders'];
  static const _periods = ['From 01-01-2020 To 31-12-2026'];

  String _company = _companies.first;
  String _branch = _branches.first;
  String _period = _periods.first;

  void _onPrevious() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _onNext() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Session ready for $_company · $_branch',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandedShell(
        showProductBowls: false,
        trailingHeader: IconButton(
          tooltip: 'Sign out',
          onPressed: _onPrevious,
          icon: const Icon(Icons.logout, color: AppColors.onForest),
        ),
        child: WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PanelLogo(),
              const SizedBox(height: 10),
              const MqtBanner(),
              const SizedBox(height: 14),
              Text(
                'Welcome, ${widget.username}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              const RequiredLabel('Company'),
              _SessionDropdown(
                value: _company,
                items: _companies,
                icon: Icons.business_outlined,
                onChanged: (value) => setState(() => _company = value),
              ),
              const SizedBox(height: 14),
              const RequiredLabel('Branch'),
              _SessionDropdown(
                value: _branch,
                items: _branches,
                icon: Icons.storefront_outlined,
                onChanged: (value) => setState(() => _branch = value),
              ),
              const SizedBox(height: 14),
              const RequiredLabel('Period'),
              _SessionDropdown(
                value: _period,
                items: _periods,
                icon: Icons.date_range_outlined,
                onChanged: (value) => setState(() => _period = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      icon: Icons.arrow_back,
                      outlined: true,
                      onPressed: _onPrevious,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Next',
                      icon: Icons.arrow_forward,
                      onPressed: _onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDropdown extends StatelessWidget {
  const _SessionDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}