import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  static const _items = <(String, String)>[
    (
      'How do I sign in?',
      'Enter your User Name and Password on the sign-in screen, then tap Sign in. Leave Remember password checked if this device should keep that choice.',
    ),
    (
      'I forgot my password. What should I do?',
      'On the sign-in screen, tap Forgot password. Enter your user name, verify the OTP, and set a new password.',
    ),
    (
      'Why do I select Company, Branch and Period?',
      'These values set your working session in Empire ERP. The dashboard loads figures for the company, branch and period you choose.',
    ),
    (
      'What does the Home dashboard show?',
      'Home shows Soda Book Feeding, Delivery Feeding, Pending Delivery and Outstanding Balance for the current session. City balances appear when the server returns them.',
    ),
    (
      'How do I open an ERP form?',
      'Tap the menu icon with three lines at the top of the screen. Forms are listed in the side menu. Soda Book Feeding opens the voucher form.',
    ),
    (
      'How do I change my profile picture?',
      'Open More, then Profile. Tap the photo and choose one from your gallery, or take a new photo.',
    ),
    (
      'How do I switch between light and dark mode?',
      'Open More. Under App Settings, choose White / Light Mode or Dark Mode.',
    ),
    (
      'How do I sign out?',
      'Open More, then Profile, and tap Logout. On Home, tap the profile icon and choose Logout.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;

    return Column(
      children: [
        PageHeader(title: "FAQ's", onMenu: onMenu),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Material(
                color: AppTheme.cardColor(context),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.dividerColor(context)),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    iconColor: AppColors.forest,
                    collapsedIconColor: AppTheme.secondaryText(context),
                    title: Text(
                      item.$1,
                      style: TextStyle(
                        color: AppTheme.primaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            color: AppTheme.secondaryText(context),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
