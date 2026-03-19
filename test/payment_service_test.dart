import 'package:flutter_test/flutter_test.dart';

import 'package:virtual_wardrobe_ai/core/app_enums.dart';
import 'package:virtual_wardrobe_ai/models/payment_card_input.dart';
import 'package:virtual_wardrobe_ai/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('accepts common spaced demo card numbers', () {
      expect(
        paymentService.validateCardNumber('4242 4242 4242 4242'),
        isNull,
      );
      expect(
        paymentService.validateCardNumber('5555 5555 5555 4444'),
        isNull,
      );
    });

    test('accepts standard CVV for demo cards', () {
      expect(
        paymentService.validateCvv(
          '123',
          cardNumber: '4242 4242 4242 4242',
        ),
        isNull,
      );
    });

    test('continues upgrade authorization for valid demo card input', () async {
      final result = await paymentService.authorizeSubscription(
        tier: SubscriptionTier.premium,
        card: const PaymentCardInput(
          cardholderName: 'Test User',
          cardNumber: '4242 4242 4242 4242',
          expiryDate: '12/30',
          cvv: '123',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.session, isNotNull);
      expect(result.errorMessage, isNull);
      expect(result.session?.paymentMethod.last4, '4242');
      expect(result.session?.verificationCode, matches(RegExp(r'^\d{6}$')));
    });

    test('resend code generates a fresh 6 digit otp and refreshes session',
        () async {
      final result = await paymentService.authorizeSubscription(
        tier: SubscriptionTier.premium,
        card: const PaymentCardInput(
          cardholderName: 'Test User',
          cardNumber: '4242 4242 4242 4242',
          expiryDate: '12/30',
          cvv: '123',
        ),
      );

      final initialSession = result.session!;
      final refreshedSession = await paymentService.resendCode(initialSession);

      expect(refreshedSession.verificationCode, matches(RegExp(r'^\d{6}$')));
      expect(
        refreshedSession.createdAt.isAfter(initialSession.createdAt) ||
            refreshedSession.createdAt.isAtSameMomentAs(
              initialSession.createdAt,
            ),
        isTrue,
      );
    });

    test('valid generated otp verifies successfully', () async {
      final result = await paymentService.authorizeSubscription(
        tier: SubscriptionTier.premium,
        card: const PaymentCardInput(
          cardholderName: 'Test User',
          cardNumber: '4242 4242 4242 4242',
          expiryDate: '12/30',
          cvv: '123',
        ),
      );

      final verificationResult = await paymentService.verifyOtp(
        session: result.session!,
        code: result.session!.verificationCode,
      );

      expect(verificationResult.isSuccess, isTrue);
      expect(verificationResult.receipt, isNotNull);
    });
  });
}
