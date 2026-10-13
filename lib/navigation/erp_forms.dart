import 'package:flutter/material.dart';

import '../screens/soda_book_feeding_screen.dart';

/// ERP forms shown in the side menu and Search.
/// Add future forms to this list.
class ErpFormEntry {
  const ErpFormEntry({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

MaterialPageRoute<void>? erpFormRoute(ErpFormEntry form) {
  if (form.title == 'Soda Book Feeding') {
    return MaterialPageRoute<void>(
      builder: (_) => const SodaBookFeedingScreen(),
    );
  }
  return null;
}

const List<ErpFormEntry> erpForms = [
  ErpFormEntry(title: 'Soda Book Feeding', icon: Icons.menu_book_outlined),
];
