
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_app/main.dart';
import 'package:new_flutter_app/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Navigation smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // Mock empty prefs -> no token
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppRoot());
    await tester.pumpAndSettle();

    // Verify that we are on the Home Page (Product List)
    expect(find.byType(MyHomePage), findsOneWidget);
    // Grid/List toggle button should be visible
    expect(find.byIcon(Icons.grid_view), findsOneWidget);
    // Login page should NOT be visible
    expect(find.byType(LoginPage), findsNothing);

    // Tap Profile Tab (Authentication Check)
    // Find the icon in BottomNavigationBar
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Login Page appears
    expect(find.byType(LoginPage), findsOneWidget);
    
    // Tap Close button in AppBar
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify back to Home Page
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(MyHomePage), findsOneWidget);
  });
}
