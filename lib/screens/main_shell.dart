import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../navigation/erp_forms.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'dashboard_screen.dart';
import 'faq_screen.dart';
import 'more_screen.dart';
import 'search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.summary});

  final DashboardSummary? summary;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      child: Builder(
        builder: (context) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.pageBackground(context),
            drawer: const _AppDrawer(),
            body: IndexedStack(
              index: _index,
              children: [
                DashboardScreen(
                  initialSummary: widget.summary,
                  onMenu: _openMenu,
                ),
                SearchScreen(onMenu: _openMenu),
                FaqScreen(onMenu: _openMenu),
                MoreScreen(onMenu: _openMenu),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                setState(() => _index = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.help_outline),
                  selectedIcon: Icon(Icons.help),
                  label: "FAQ's",
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final username = session.username?.trim() ?? '';
    final company = session.company?.name ?? '';
    final branch = session.branch?.name ?? '';
    final period = session.period?.name ?? '';
    final detail = [
      if (company.isNotEmpty) company,
      if (branch.isNotEmpty) branch,
    ].join(' · ');
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = width >= 600
        ? 360.0
        : (width * 0.84).clamp(280.0, 340.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppTheme.pageBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(
            username: username.isEmpty ? 'Signed in user' : username,
            detail: detail,
            period: period,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'ERP FORMS',
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                for (final form in erpForms) _DrawerFormTile(form: form),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.dividerColor(context)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Text(
              'Empire ERP  ·  Mobile',
              style: TextStyle(
                color: AppTheme.secondaryText(context),
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.username,
    required this.detail,
    required this.period,
  });

  final String username;
  final String detail;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestDeep, AppColors.forestMid],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.onForest.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.lime.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.lime,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAST QALANDER',
                      style: TextStyle(
                        color: AppColors.onForest,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'MQT',
                      style: TextStyle(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const UserAvatar(
                radius: 22,
                backgroundColor: Color(0x33FFFFFF),
                foregroundColor: AppColors.lime,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onForest,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.limeSoft,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (period.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onForest.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerFormTile extends StatelessWidget {
  const _DrawerFormTile({required this.form});

  final ErpFormEntry form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.dividerColor(context)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final route = erpFormRoute(form);
            navigator.pop();
            if (route != null) {
              navigator.push(route);
              return;
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '${form.title} will be available in a future update.',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(form.icon, color: AppColors.forest, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    form.title,
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.secondaryText(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
