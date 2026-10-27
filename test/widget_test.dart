import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:empire_app/api/api_client.dart';
import 'package:empire_app/main.dart';
import 'package:empire_app/models/dashboard_summary.dart';
import 'package:empire_app/models/lookup_item.dart';
import 'package:empire_app/models/soda_book.dart';
import 'package:empire_app/screens/main_shell.dart';
import 'package:empire_app/session/app_session.dart';
import 'package:empire_app/theme/app_theme.dart';

void main() {
  tearDown(() {
    AppTheme.mode.value = ThemeMode.light;
    AppSession.instance.clear();
  });

  testWidgets('Login screen is shown on app start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('User Name'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember password'), findsOneWidget);
  });

  testWidgets('Login validation requires username and password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('User Name is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Main shell keeps the dashboard and shows navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    AppSession.instance
      ..username = 'empire'
      ..company = const LookupItem(id: 1, name: 'MQT Company')
      ..branch = const LookupItem(id: 2, name: 'Karachi')
      ..period = const LookupItem(id: 3, name: '2026');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MainShell(
          summary: DashboardSummary(
            sodaBookFeedingCount: 12,
            deliveryFeedingCount: 3,
            pickedDeliveryCount: 4,
            outstandingBalance: 1000,
          ),
        ),
      ),
    );

    expect(find.text('MQT Dashboard'), findsOneWidget);
    expect(find.text('Welcome, empire'), findsOneWidget);
    expect(find.text('Soda Book Feeding'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text("FAQ's"), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(tester.getTopLeft(find.byTooltip('Menu')).dx, lessThan(80));
    expect(
      tester.getTopLeft(find.byTooltip('Menu')).dy,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('MQT Company'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('MQT'), findsWidgets);
    expect(find.text('ERP FORMS'), findsOneWidget);
    expect(find.text('empire'), findsOneWidget);
    expect(find.text('Soda Book Feeding'), findsWidgets);

    await tester.tap(find.text('Soda Book Feeding').last);
    await tester.pumpAndSettle();
    expect(find.text('Transaction Date'), findsOneWidget);
    expect(find.text('MASTER'), findsOneWidget);
    expect(find.text('Seller'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Search form names'), findsOneWidget);
    expect(find.text('Search ERP form names'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'soda');
    await tester.pump();
    expect(find.text('Soda Book Feeding'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing-form');
    await tester.pump();
    expect(find.text('No forms match "missing-form"'), findsOneWidget);

    await tester.tap(find.text("FAQ's"));
    await tester.pumpAndSettle();
    expect(find.text('How do I sign in?'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('APP SETTINGS'), findsOneWidget);
    expect(find.text('White / Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Change session'), findsOneWidget);

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    expect(AppTheme.mode.value, ThemeMode.dark);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('MQT Company'), findsOneWidget);
    expect(find.text('Karachi'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byTooltip('Change profile picture'), findsOneWidget);
  });

  test('Lookup item reads company/branch codes from common API fields', () {
    final company = LookupItem.fromJson(
      {'CNAME': 'Mast Qalander Traders', 'companyId': 7},
      idKeys: const ['ccode', 'companyId', 'id', 'code'],
    );
    expect(company.id, 7);
    expect(company.name, 'Mast Qalander Traders');

    final branch = LookupItem.fromJson(
      {'BCODE': 12, 'BRANCH_NAME': 'Karachi'},
      idKeys: const ['bcode', 'branchId', 'id', 'code'],
    );
    expect(branch.id, 12);
    expect(branch.name, 'Karachi');
  });

  test('Split dashboard payloads keep counts, cities and report rows', () {
    final counts = DashboardSummary.mapFrom({
      'sodaBookFeedingCount': 12,
      'deliveryFeedingCount': 3,
      'pickedDeliveryCount': 4,
      'outstandingBalance': 1000,
    });
    expect(
      DashboardSummary.optionalNum(counts, const ['sodaBookFeedingCount']),
      12,
    );
    expect(
      DashboardSummary.optionalNum(counts, const ['outstandingBalance']),
      1000,
    );

    final cities = OutstandingBalanceItem.listFrom({
      'outstandingBalance': 2500,
      'outstandingBalances': [
        {'city': 'Karachi', 'balance': 2500},
      ],
    });
    expect(cities.single.accountName, 'Karachi');
    expect(cities.single.balance, 2500);
    expect(formatDashboardNumber(cities.single.balance), '2,500');

    final rows = DashboardSummary.rowsFrom({
      'data': [
        {'accountName': 'Shop', 'balance': 10, 'city': 'Lahore'},
      ],
    });
    expect(rows.single['city'], 'Lahore');
    expect(rows.single['accountName'], 'Shop');
  });

  test('Soda book document reads master and detail rows', () {
    final document = SodaDocument.fromJson({
      'master': {'traN_ID': 5, 'voucheR_NO': 'SB-1', 'selleR_CODE': 'S1'},
      'detail': [
        {'iteM_CODE': 9, 'qty': 2, 'rate': 10},
      ],
    });
    expect(sodaField(document.master, 'voucheR_NO'), 'SB-1');
    expect(document.detail.single['qty'], 2);
    expect(sodaCode(sodaField(document.detail.single, 'iteM_CODE')), '9');

    final saved = SodaDocument.fromJson(
      {
        'master': [
          {'tranId': 8, 'voucherNo': 'SB-8', 'sellerCode': 'S1'},
        ],
        'detail': [
          {'itemCode': 3, 'dtDesc': 'Yarn', 'qty': 4},
        ],
      },
      extra: [
        {'itemCode': 1, 'qty': 9},
      ],
    );
    expect(sodaFieldLoose(saved.master, 'voucheR_NO'), 'SB-8');
    expect(sodaFieldLoose(saved.master, 'traN_ID'), 8);
    expect(sodaFieldLoose(saved.detail.single, 'iteM_CODE'), 3);
    expect(saved.detail.single['qty'], 4);

    final split = SodaDocument.fromJson(
      {'tranId': 2, 'voucherNo': 'SB-2'},
      extra: [
        {'itemCode': 1, 'qty': 5},
      ],
    );
    expect(sodaFieldLoose(split.master, 'voucheR_NO'), 'SB-2');
    expect(split.detail.single['qty'], 5);

    final mixed = SodaDocument.fromJson(
      [
        {'iteM_CODE': 4, 'dT_CODE': 1, 'qty': 3, 'traN_ID': 9},
        {'traN_ID': 9, 'voucheR_NO': 'SB-9', 'selleR_CODE': 'S9'},
      ],
      extra: [
        {'iteM_CODE': 4, 'dT_CODE': 1, 'qty': 3, 'dT_DESC': 'Yarn'},
        {'iteM_CODE': 4, 'dT_CODE': 1, 'qty': 9, 'dT_DESC': 'Yarn'},
        {'iteM_CODE': 8, 'dT_CODE': 2, 'qty': 1, 'dT_DESC': 'Soda'},
      ],
    );
    expect(sodaFieldLoose(mixed.master, 'voucheR_NO'), 'SB-9');
    expect(sodaFieldLoose(mixed.master, 'iteM_CODE'), isNull);
    expect(mixed.detail.length, 2);
    expect(sodaFieldLoose(mixed.detail.first, 'qty'), 3);
    expect(sodaFieldLoose(mixed.detail.last, 'iteM_CODE'), 8);

    final options = SodaOption.listFrom([
      {'code': 'S1', 'name': 'Seller One'},
    ]);
    expect(options.single.code, 'S1');
    expect(options.single.name, 'Seller One');

    final parties = SodaOption.listFrom([
      {
        'CustomerKey': 'C100',
        'adD_COMPUTER_NAME': 'SERVER',
        'CustomerName': 'Ali Traders',
      },
      {'customerKey': 'C200', 'customerName': 'CustomerKey'},
    ]);
    expect(parties.first.code, 'C100');
    expect(parties.first.name, 'Ali Traders');
    expect(parties.last.code, 'C200');
    expect(parties.last.name, 'C200');

    final apiParties = SodaOption.listFrom([
      {
        'key': 161,
        'customizedKey': '161116',
        'value': 'MOHD ALI MOTI',
        'accountCode': 116,
        'disc': 0,
        'commission': null,
      },
      {
        'key': 162,
        'customizedKey': '162117',
        'value': 'ASAN TRADERS',
        'accountCode': 117,
      },
    ]);
    expect(apiParties.length, 2);
    expect(apiParties.first.code, '161');
    expect(apiParties.first.name, 'MOHD ALI MOTI');
    expect(sodaActCode(apiParties.first.raw), 116);
    expect(apiParties.last.code, '162');
    expect(apiParties.last.name, 'ASAN TRADERS');
    expect(sodaActCode(apiParties.last.raw), 117);
  });

  test('API messages strip HTML and SQL timeout text', () {
    expect(
      ApiResponse.sanitizeMessage(
        'Execution Timeout Expired. The timeout period elapsed prior to completion of the operation or the server is not responding.<br>The wait operation timed out.',
      ),
      'The server took too long to load this data. Please try again.',
    );
  });
}
