import 'package:flutter_test/flutter_test.dart';

import 'package:empire_app/main.dart';

void main() {
  testWidgets('Login screen is shown on app start', (WidgetTester tester) async {
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
}
