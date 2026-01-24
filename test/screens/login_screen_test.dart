import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:leafguard/screens/login_screen.dart';
import 'package:leafguard/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

@GenerateMocks([AuthService])
import 'login_screen_test.mocks.dart';

// Mock loader providing all keys used in Login and Reset screens
class MockAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      "login_title": "Login",
      "welcome_back": "Welcome back",
      "email": "Email",
      "password": "Password",
      "login_btn": "Login",
      "email_required": "Email is required",
      "invalid_email": "Invalid email format",
      "password_required": "Password is required",
      "password_too_short": "Password too short",
      "forgot_password_btn": "Forgot Password?",
      "dont_have_account": "Don't have account",
      "enter_valid_email_first": "Enter valid email",
      "reset_link_sent": "Reset link sent",
      "forgot_password": "Forgot Password",
      "error_occurred": "Error occurred",
      "reset_password": "Reset Password",
      "enter_reset_details": "Enter reset details",
      "reset_token": "Reset Token",
      "new_password": "New Password",
      "update_password_btn": "Update Password",
      "password_updated": "Password updated successfully",
      "token_required": "Valid token required",
    };
  }
}

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: MockAssetLoader(),
      saveLocale: false,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            initialRoute: '/',
            routes: {
              '/': (context) => LoginScreen(authService: mockAuthService),
              '/home': (context) => const Scaffold(body: Text('Home Page')),
              '/register': (context) =>
                  const Scaffold(body: Text('Register Page')),
            },
          );
        },
      ),
    );
  }

  group('LoginScreen Coverage Tests', () {
    testWidgets('Show validation errors for empty and malformed fields',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text("email_required".tr()), findsOneWidget);
      expect(find.text("password_required".tr()), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'invalidemail');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text("invalid_email".tr()), findsOneWidget);
      expect(find.text("password_too_short".tr()), findsOneWidget);
    });

    testWidgets('Successful login navigates to /home', (tester) async {
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => {'success': true});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));

      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Failed login shows SnackBar error', (tester) async {
      const errorMsg = 'Invalid Credentials';
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => {'success': false, 'error': errorMsg});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'wrong@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.byType(ElevatedButton));

      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('Toggle password visibility', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final passwordTextFieldFinder = find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byType(TextField),
      );

      TextField passwordWidget =
          tester.widget<TextField>(passwordTextFieldFinder);
      expect(passwordWidget.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      passwordWidget = tester.widget<TextField>(passwordTextFieldFinder);
      expect(passwordWidget.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Forgot Password: Shows error if email is invalid',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.tap(find.text("forgot_password_btn".tr()));
      await tester.pump();

      expect(find.text("enter_valid_email_first".tr()), findsOneWidget);
    });

    testWidgets('Forgot Password: Shows Dialog on service failure',
        (tester) async {
      when(mockAuthService.forgotPassword(any))
          .thenAnswer((_) async => {'success': false, 'error': 'Server Error'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.tap(find.text("forgot_password_btn".tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Server Error'), findsOneWidget);
    });

    testWidgets('Forgot Password: Valid email opens ResetPasswordScreen',
        (tester) async {
      when(mockAuthService.forgotPassword(any))
          .thenAnswer((_) async => {'success': true});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.tap(find.text("forgot_password_btn".tr()));

      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });
  });
}
