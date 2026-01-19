// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_app/main.dart';
import 'package:new_flutter_app/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // Mock empty prefs -> no token
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(); // Wait for FutureBuilder

    // Verify that we are on the login page
    expect(find.byType(LoginPage), findsOneWidget);
    
    // Verify UI elements
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
