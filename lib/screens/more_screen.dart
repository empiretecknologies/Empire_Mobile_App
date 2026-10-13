import 'package:flutter/material.dart';

import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';
import 'session_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;
    final session = AppSession.instance;
    final username = session.username?.trim() ?? '';

    return Column(
      children: [
        PageHeader(title: 'More', onMenu: onMenu),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            children: [
              _SettingsCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: const UserAvatar(radius: 20),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    username.isEmpty ? 'Signed in user' : username,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondaryText(context),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel('APP SETTINGS'),
              const SizedBox(height: 8),
              _SettingsCard(
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppTheme.mode,
                  builder: (context, mode, _) {
                    final dark = mode == ThemeMode.dark;
                    return Column(
                      children: [
                        _ModeTile(
                          icon: Icons.light_mode_outlined,
                          label: 'White / Light Mode',
                          selected: !dark,
                          onTap: () => AppTheme.mode.value = ThemeMode.light,
                        ),
                        Divider(height: 1, color: AppTheme.dividerColor(context)),
                        _ModeTile(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          selected: dark,
                          onTap: () => AppTheme.mode.value = ThemeMode.dark,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.business_outlined,
                      label: 'Change session',
                      detail: [
                        session.company?.name,
                        session.branch?.name,
                        session.period?.name,
                      ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const SessionScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerColor(context)),
                    _ActionTile(
                      icon: Icons.info_outline,
                      label: 'About',
                      detail: 'Empire ERP  ·  Version 1.0.0',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.secondaryText(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.dividerColor(context)),
      ),
      child: child,
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, color: AppColors.forest),
      title: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryText(context),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? AppColors.forest : AppTheme.secondaryText(context),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.forest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.forest, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryText(context),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: detail == null || detail!.isEmpty
          ? null
          : Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 12,
              ),
            ),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right,
              color: AppTheme.secondaryText(context),
            ),
      onTap: onTap,
    );
  }
}
