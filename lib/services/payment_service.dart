import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/app_enums.dart';
import '../models/payment_authorization_session.dart';
import '../models/payment_card_input.dart';
import '../models/payment_method_summary.dart';
import '../models/subscription_purchase_receipt.dart';

class PaymentService {
  static const acceptedDemoCards = <String>[
    '4242424242424242',
    '5555555555554444',
    '378282246310005',
  ];
  static const declinedDemoCards = <String>[
    '4000000000000002',
  ];

  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  String? validateCardholderName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'payment_error_cardholder_required';
    }
    if (trimmed.length < 3) {
      return 'payment_error_cardholder_short';
    }
    return null;
  }

  String? validateCardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'payment_error_card_required';
    }
    if (digits.length < 15 || digits.length > 19) {
      return 'payment_error_card_invalid_length';
    }
    if (acceptedDemoCards.contains(digits) ||
        declinedDemoCards.contains(digits)) {
      return null;
    }
    if (!_passesLuhnCheck(digits)) {
      return 'payment_error_card_invalid';
    }
    return null;
  }

  String? validateExpiryDate(String? value) {
    final normalized = (value ?? '').replaceAll(' ', '');
    final parts = normalized.split('/');
    if (parts.length != 2) {
      return 'payment_error_expiry_format';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) {
      return 'payment_error_expiry_invalid';
    }

    final now = DateTime.now();
    final fourDigitYear = 2000 + year;
    final expiresAt = DateTime(fourDigitYear, month + 1);
    if (!expiresAt.isAfter(DateTime(now.year, now.month))) {
      return 'payment_error_card_expired';
    }
    return null;
  }

  String? validateCvv(String? value, {String? cardNumber}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final normalizedCardNumber =
        (cardNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final isAmex = _detectCardBrand(normalizedCardNumber) == 'Amex';
    if (digits.isEmpty) {
      return 'payment_error_cvv_required';
    }
    if (isAmex) {
      if (digits.length != 4) {
        return 'payment_error_cvv_invalid';
      }
      return null;
    }
    if (digits.length != 3 && digits.length != 4) {
      return 'payment_error_cvv_invalid';
    }
    return null;
  }

  Future<PaymentAuthorizationResult> authorizeSubscription({
    required SubscriptionTier tier,
    required PaymentCardInput card,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: 1100 + _random.nextInt(450)),
    );

    final summary = PaymentMethodSummary(
      brand: _detectCardBrand(card.normalizedCardNumber),
      last4: card.last4,
    );

    if (declinedDemoCards.contains(card.normalizedCardNumber)) {
      return PaymentAuthorizationResult.failure(
        'payment_error_bank_declined',
      );
    }

    final verificationCode = _generateOtpCode();
    debugPrint(
      '[I Closet] Generated OTP for ${summary.label}: $verificationCode',
    );

    return PaymentAuthorizationResult.success(
      PaymentAuthorizationSession(
        authorizationId: _uuid.v4(),
        tier: tier,
        paymentMethod: summary,
        verificationCode: verificationCode,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<PaymentAuthorizationSession> resendCode(
    PaymentAuthorizationSession session,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final verificationCode = _generateOtpCode();
    debugPrint(
      '[I Closet] Resent OTP for ${session.paymentMethod.label}: $verificationCode',
    );
    return session.copyWith(
      verificationCode: verificationCode,
      createdAt: DateTime.now(),
    );
  }

  Future<PaymentVerificationResult> verifyOtp({
    required PaymentAuthorizationSession session,
    required String code,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: 900 + _random.nextInt(350)),
    );

    final normalized = code.replaceAll(RegExp(r'\D'), '');
    if (normalized != session.verificationCode) {
      return PaymentVerificationResult.failure(
        'payment_error_otp_invalid',
      );
    }

    return PaymentVerificationResult.success(
      SubscriptionPurchaseReceipt(
        tier: session.tier,
        paymentMethod: session.paymentMethod,
        transactionId: 'txn_${_uuid.v4()}',
        paidAt: DateTime.now(),
      ),
    );
  }

  String _detectCardBrand(String digits) {
    if (digits.startsWith('4')) {
      return 'Visa';
    }
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) {
      return 'Mastercard';
    }
    if (RegExp(r'^(34|37)').hasMatch(digits)) {
      return 'Amex';
    }
    return 'Card';
  }

  String _generateOtpCode() {
    final value = _random.nextInt(900000) + 100000;
    return value.toString();
  }

  bool _passesLuhnCheck(String digits) {
    var sum = 0;
    var shouldDouble = false;

    for (var index = digits.length - 1; index >= 0; index -= 1) {
      var digit = int.parse(digits[index]);
      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 == 0;
  }
}
