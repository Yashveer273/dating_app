// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:talk24loves/main.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';

void main() {
  testWidgets('Landing page is shown on the default route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Private Audio & Video Talk'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('Phone validation enforces country-based length rules', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(LoginScreen.isValidPhoneNumberForCode('123456789', '+1'), isFalse);
    expect(LoginScreen.isValidPhoneNumberForCode('1234567890', '+1'), isTrue);
    expect(LoginScreen.isValidPhoneNumberForCode('12345678', '+61'), isTrue);
  });
}
