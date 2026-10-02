import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/lookup_item.dart';
import '../services/auth_service.dart';
import '../services/lookup_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/branded_shell.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _lookupService = LookupService();
  final _authService = AuthService();

  List<LookupItem> _companies = [];
  List<LookupItem> _branches = [];
  List<LookupItem> _periods = [];

  LookupItem? _company;
  LookupItem? _branch;
  LookupItem? _period;

  bool _loadingCompanies = true;
  bool _loadingBranches = false;
  bool _loadingPeriods = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _loadingCompanies = true;
      _error = null;
      _companies = [];
      _branches = [];
      _periods = [];
      _company = null;
      _branch = null;
      _period = null;
    });
    try {
      final items = await _lookupService.getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = items;
        _company = items.isEmpty ? null : items.first;
      });
      if (_company != null) await _loadBranches(_company!.id);
    } on ApiException catch (error) {
      await _handleError(error);
    } finally {
      if (mounted) setState(() => _loadingCompanies = false);
    }
  }

  Future<void> _loadBranches(int companyId) async {
    setState(() {
      _loadingBranches = true;
      _error = null;
      _branches = [];
      _periods = [];
      _branch = null;
      _period = null;
    });
    try {
      final items = await _lookupService.getBranches(companyId: companyId);
      if (!mounted) return;
      setState(() {
        _branches = items;
        _branch = items.isEmpty ? null : items.first;
      });
      if (_branch != null) await _loadPeriods(_branch!.id);
    } on ApiException catch (error) {
      await _handleError(error);
    } finally {
      if (mounted) setState(() => _loadingBranches = false);
    }
  }

  Future<void> _loadPeriods(int branchId) async {
    setState(() {
      _loadingPeriods = true;
      _error = null;
      _periods = [];
      _period = null;
    });
    try {
      final items = await _lookupService.getPeriods(branchId: branchId);
      if (!mounted) return;
      setState(() {
        _periods = items;
        _period = items.isEmpty ? null : items.first;
      });
    } on ApiException catch (error) {
      await _handleError(error);
    } finally {
      if (mounted) setState(() => _loadingPeriods = false);
    }
  }

  Future<void> _handleError(ApiException error) async {
    if (!mounted) return;
    if (error.isUnauthorized) {
      AppSession.instance.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() => _error = error.message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }

  Future<void> _onPrevious() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _onNext() async {
    if (_company == null || _branch == null || _period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Company, Branch and Period.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _authService.saveContext(
        company: '${_company!.id}',
        branch: '${_branch!.id}',
        period: '${_period!.id}',
      );
      if (!mounted) return;
      AppSession.instance
        ..company = _company
        ..branch = _branch
        ..period = _period;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
    } on ApiException catch (error) {
      await _handleError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _busy =>
      _loadingCompanies || _loadingBranches || _loadingPeriods || _saving;

  @override
  Widget build(BuildContext context) {
    final username = AppSession.instance.username ?? '';
    return Scaffold(
      body: BrandedShell(
        showProductBowls: false,
        trailingHeader: IconButton(
          tooltip: 'Sign out',
          onPressed: _busy ? null : _onPrevious,
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
                username.isEmpty ? 'Select session' : 'Welcome, $username',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _loadCompanies,
                  child: const Text('Retry'),
                ),
              ],
              const SizedBox(height: 16),
              const RequiredLabel('Company'),
              _LookupDropdown(
                value: _company,
                items: _companies,
                icon: Icons.business_outlined,
                loading: _loadingCompanies,
                enabled: !_busy,
                onChanged: (value) {
                  setState(() => _company = value);
                  if (value != null) _loadBranches(value.id);
                },
              ),
              const SizedBox(height: 14),
              const RequiredLabel('Branch'),
              _LookupDropdown(
                value: _branch,
                items: _branches,
                icon: Icons.storefront_outlined,
                loading: _loadingBranches,
                enabled: !_busy && _company != null,
                onChanged: (value) {
                  setState(() => _branch = value);
                  if (value != null) _loadPeriods(value.id);
                },
              ),
              const SizedBox(height: 14),
              const RequiredLabel('Period'),
              _LookupDropdown(
                value: _period,
                items: _periods,
                icon: Icons.date_range_outlined,
                loading: _loadingPeriods,
                enabled: !_busy && _branch != null,
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
                      onPressed: _busy ? null : _onPrevious,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Next',
                      icon: Icons.arrow_forward,
                      loading: _saving,
                      onPressed: _busy ? null : _onNext,
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

class _LookupDropdown extends StatelessWidget {
  const _LookupDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    required this.loading,
    required this.enabled,
  });

  final LookupItem? value;
  final List<LookupItem> items;
  final IconData icon;
  final ValueChanged<LookupItem?> onChanged;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    final selected =
        value != null && items.any((item) => item.id == value!.id)
            ? value
            : null;

    return DropdownButtonFormField<LookupItem>(
      key: ValueKey('${items.map((e) => e.id).join('-')}-$selected'),
      initialValue: selected,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
      ),
      hint: const Text('Select'),
      items: [
        for (final item in items)
          DropdownMenuItem<LookupItem>(
            value: item,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
