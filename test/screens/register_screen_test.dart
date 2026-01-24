import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:leafguard/screens/register_screen.dart';
import 'package:leafguard/services/auth_service.dart';
import '../test_helper.dart';

@GenerateMocks([AuthService])
import 'register_screen_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await localizationSetup();
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Future<void> pumpRegisterScreen(WidgetTester tester) async {
    // FIX: Ensure the virtual screen is large enough to see all widgets
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // We only pass the Screen itself because test_helper provides the MaterialApp wrapper
    await tester.pumpWidget(
      wrapWithLocalization(
        child: RegisterScreen(authService: mockAuthService),
      ),
    );

    // Crucial: Wait for the FakeAssetLoader to finish and the UI to settle
    await tester.pumpAndSettle();
  }

  group('RegisterScreen Tests', () {
    testWidgets('RegisterScreen renders all required fields', (tester) async {
      await pumpRegisterScreen(tester);

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Shows validation errors on empty submit', (tester) async {
      await pumpRegisterScreen(tester);

      final registerButton = find.byType(ElevatedButton);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password too short'), findsOneWidget);
    });

    testWidgets('Registration success flow', (tester) async {
      when(mockAuthService.register(any, any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return {'success': true};
      });

      await pumpRegisterScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'john@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      final registerButton = find.byType(ElevatedButton);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      // Wait for mock
      await tester.pumpAndSettle(); // Finish animations

      verify(mockAuthService.register(
        'John Doe',
        'john@test.com',
        'password123',
      )).called(1);
    });

    testWidgets('Shows error SnackBar on registration failure', (tester) async {
      when(mockAuthService.register(any, any, any)).thenAnswer((_) async => {
            'success': false,
            'error': 'Email already exists',
          });

      await pumpRegisterScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'jane@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      final registerButton = find.byType(ElevatedButton);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Email already exists'), findsOneWidget);
    });
  });
}
