import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/payment_authorization_session.dart';
import '../../models/payment_card_input.dart';
import '../../models/subscription_purchase_receipt.dart';
import '../../providers/subscription_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/premium_scaffold.dart';

class SubscriptionCheckoutScreen extends StatefulWidget {
  const SubscriptionCheckoutScreen({
    required this.initialTier,
    this.featureName,
    super.key,
  });

  final SubscriptionTier initialTier;
  final String? featureName;

  @override
  State<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

enum _CheckoutStep {
  plans,
  payment,
  verification,
  failure,
  success,
}

class _SubscriptionCheckoutScreenState
    extends State<SubscriptionCheckoutScreen> {
  static const _maxOtpAttempts = 3;
  static const _resendCooldownSeconds = 30;

  final _paymentFormKey = GlobalKey<FormState>();
  final _cardholderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _otpController = TextEditingController();

  late SubscriptionTier _selectedTier;
  _CheckoutStep _step = _CheckoutStep.plans;
  PaymentAuthorizationSession? _authorizationSession;
  SubscriptionPurchaseReceipt? _receipt;
  bool _processingPayment = false;
  bool _verifyingCode = false;
  bool _resendingCode = false;
  String? _paymentError;
  String? _otpError;
  String? _failureMessage;
  int _otpAttempts = 0;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier;
    _otpController.addListener(_handleOtpChanged);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _isBusy => _processingPayment || _verifyingCode || _resendingCode;
  bool get _isOtpLocked => _otpAttempts >= _maxOtpAttempts;
  bool get _canVerifyOtp =>
      !_isBusy &&
      !_isOtpLocked &&
      _normalizedOtpCode.length == 6 &&
      _authorizationSession != null;
  bool get _canResendOtp =>
      !_isBusy && _authorizationSession != null && _resendSecondsRemaining == 0;
  String get _normalizedOtpCode =>
      _otpController.text.replaceAll(RegExp(r'\D'), '');

  void _handleOtpChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      if (_otpError != null && !_isOtpLocked) {
        _otpError = null;
      }
    });
  }

  String _stepTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_step) {
      case _CheckoutStep.plans:
        return l10n.t('checkout_title_upgrade');
      case _CheckoutStep.payment:
        return l10n.t('checkout_title_payment');
      case _CheckoutStep.verification:
        return l10n.t('checkout_title_verification');
      case _CheckoutStep.failure:
        return l10n.t('checkout_title_issue');
      case _CheckoutStep.success:
        return l10n.t('checkout_title_active');
    }
  }

  String? _localizedPaymentMessage(String? key) {
    if (key == null || key.isEmpty) {
      return null;
    }
    return context.l10n.t(key);
  }

  String _attemptsRemainingLabel(AppLocalizations l10n, int attemptsRemaining) {
    if (attemptsRemaining <= 0) {
      return l10n.t('checkout_too_many_attempts');
    }
    if (attemptsRemaining == 1) {
      return l10n.t('checkout_attempt_remaining_one');
    }
    return l10n.t(
      'checkout_attempt_remaining_many',
      args: {'count': '$attemptsRemaining'},
    );
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsRemaining = _resendCooldownSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _resendSecondsRemaining -= 1;
      });
    });
  }

  void _stopResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = null;
    _resendSecondsRemaining = 0;
  }

  Future<void> _submitPayment() async {
    final formState = _paymentFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _paymentError = null;
      _processingPayment = true;
    });

    final paymentService = context.read<PaymentService>();
    final result = await paymentService.authorizeSubscription(
      tier: _selectedTier,
      card: PaymentCardInput(
        cardholderName: _cardholderController.text,
        cardNumber: _cardNumberController.text,
        expiryDate: _expiryController.text,
        cvv: _cvvController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess || result.session == null) {
      setState(() {
        _processingPayment = false;
        _paymentError = _localizedPaymentMessage(result.errorMessage);
      });
      return;
    }

    setState(() {
      _authorizationSession = result.session;
      _processingPayment = false;
      _step = _CheckoutStep.verification;
      _otpError = null;
      _otpAttempts = 0;
      _failureMessage = null;
      _otpController.clear();
      _cardNumberController.clear();
      _cvvController.clear();
    });
    _startResendCooldown();
  }

  Future<void> _verifyCode() async {
    final session = _authorizationSession;
    if (session == null) {
      return;
    }

    if (_isOtpLocked) {
      setState(() {
        _otpError = context.l10n.t('checkout_too_many_attempts');
      });
      return;
    }

    final code = _normalizedOtpCode;
    if (code.length != 6) {
      setState(() {
        _otpError = context.l10n.t('checkout_error_code_length');
      });
      return;
    }

    setState(() {
      _verifyingCode = true;
      _otpError = null;
    });

    final result = await context.read<PaymentService>().verifyOtp(
          session: session,
          code: code,
        );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess || result.receipt == null) {
      final nextAttempts = _otpAttempts + 1;
      setState(() {
        _otpAttempts = nextAttempts;
        _verifyingCode = false;
        _otpError = nextAttempts >= _maxOtpAttempts
            ? context.l10n.t('checkout_too_many_attempts')
            : _localizedPaymentMessage(result.errorMessage);
      });
      return;
    }

    await context
        .read<SubscriptionProvider>()
        .completePurchase(result.receipt!);

    if (!mounted) {
      return;
    }

    setState(() {
      _receipt = result.receipt;
      _verifyingCode = false;
      _step = _CheckoutStep.success;
      _otpError = null;
    });
    _stopResendCooldown();
  }

  Future<void> _resendCode() async {
    final session = _authorizationSession;
    if (session == null || !_canResendOtp) {
      return;
    }

    setState(() {
      _resendingCode = true;
      _otpError = null;
    });

    final refreshedSession =
        await context.read<PaymentService>().resendCode(session);

    if (!mounted) {
      return;
    }

    setState(() {
      _authorizationSession = refreshedSession;
      _resendingCode = false;
      _otpAttempts = 0;
      _otpController.clear();
      _otpError = null;
      _failureMessage = null;
    });
    _startResendCooldown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.t('checkout_new_code_sent')),
      ),
    );
  }

  void _handleBackPressed() {
    if (_isBusy) {
      return;
    }

    switch (_step) {
      case _CheckoutStep.plans:
        Navigator.of(context).pop();
        return;
      case _CheckoutStep.payment:
        setState(() {
          _step = _CheckoutStep.plans;
          _paymentError = null;
        });
        _stopResendCooldown();
        return;
      case _CheckoutStep.verification:
        setState(() {
          _step = _CheckoutStep.payment;
          _otpError = null;
          _otpAttempts = 0;
          _otpController.clear();
        });
        _stopResendCooldown();
        return;
      case _CheckoutStep.failure:
        setState(() {
          _step = _CheckoutStep.verification;
          _failureMessage = null;
        });
        return;
      case _CheckoutStep.success:
        Navigator.of(context).pop(_receipt?.tier ?? _selectedTier);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final l10n = context.l10n;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(_stepTitle(context)),
        leading: IconButton(
          onPressed: _handleBackPressed,
          icon: Icon(
            _step == _CheckoutStep.plans || _step == _CheckoutStep.success
                ? Icons.close_rounded
                : Icons.arrow_back_rounded,
          ),
        ),
        actions: [
          if (_step != _CheckoutStep.success)
            TextButton(
              onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.t('common_cancel')),
            ),
          const SizedBox(width: 8),
        ],
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _CheckoutProgress(
            currentStep: _step,
            selectedTier: _selectedTier,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildStepBody(subscription),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody(SubscriptionProvider subscription) {
    switch (_step) {
      case _CheckoutStep.plans:
        return _buildPlanStep(subscription);
      case _CheckoutStep.payment:
        return _buildPaymentStep();
      case _CheckoutStep.verification:
        return _buildVerificationStep();
      case _CheckoutStep.failure:
        return _buildFailureStep();
      case _CheckoutStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildPlanStep(SubscriptionProvider subscription) {
    final l10n = context.l10n;
    final currentTier = subscription.tier;
    final selectedBullets =
        AppConstants.planFeatureBullets[_selectedTier] ?? const <String>[];

    return Column(
      key: const ValueKey('plans'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          accent: _selectedTier == SubscriptionTier.plus
              ? AppTheme.premium
              : AppTheme.accentDeep,
          icon: _selectedTier == SubscriptionTier.plus
              ? Icons.shopping_bag_outlined
              : Icons.workspace_premium_rounded,
          eyebrow: l10n.t('checkout_choose_plan_eyebrow'),
          title: widget.featureName == null
              ? l10n.t('checkout_choose_plan_title')
              : l10n.t(
                  'checkout_unlock_feature_title',
                  args: {'feature': widget.featureName!},
                ),
          body: l10n.t('checkout_choose_plan_body'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PremiumBadge(
                label: l10n.t(
                  'premium_plan_badge',
                  args: {'plan': formatSubscriptionTierLabel(_selectedTier)},
                ),
              ),
              const SizedBox(height: 10),
              Text(
                formatSubscriptionPrice(_selectedTier),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.t('checkout_select_plan_title'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('checkout_select_plan_subtitle'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _SelectablePlanCard(
          tier: SubscriptionTier.premium,
          selected: _selectedTier == SubscriptionTier.premium,
          locked: currentTier.index >= SubscriptionTier.premium.index,
          accent: AppTheme.accent,
          icon: Icons.workspace_premium_rounded,
          onTap: currentTier.index >= SubscriptionTier.premium.index
              ? null
              : () => setState(() => _selectedTier = SubscriptionTier.premium),
        ),
        const SizedBox(height: 14),
        _SelectablePlanCard(
          tier: SubscriptionTier.plus,
          selected: _selectedTier == SubscriptionTier.plus,
          locked: currentTier == SubscriptionTier.plus,
          accent: AppTheme.premium,
          icon: Icons.shopping_bag_outlined,
          onTap: currentTier == SubscriptionTier.plus
              ? null
              : () => setState(() => _selectedTier = SubscriptionTier.plus),
        ),
        const SizedBox(height: 20),
        _CheckoutSurface(
          title: l10n.t('checkout_unlocked_title'),
          subtitle: l10n.t('checkout_unlocked_subtitle'),
          child: Column(
            children: [
              ...selectedBullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BenefitRow(
                    icon: _selectedTier == SubscriptionTier.plus
                        ? Icons.auto_awesome_rounded
                        : Icons.check_circle_rounded,
                    text: bullet,
                    accent: _selectedTier == SubscriptionTier.plus
                        ? AppTheme.premium
                        : AppTheme.accentDeep,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _InfoStrip(
                icon: Icons.lock_outline_rounded,
                text: l10n.t('checkout_billing_info'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => setState(() => _step = _CheckoutStep.payment),
          icon: const Icon(Icons.lock_outline_rounded),
          label: Text(l10n.t('premium_gate_continue')),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final l10n = context.l10n;
    final paymentService = context.read<PaymentService>();

    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          accent: AppTheme.accentDeep,
          icon: Icons.credit_card_rounded,
          eyebrow: l10n.t('checkout_secure_payment_eyebrow'),
          title: l10n.t('checkout_enter_card_title'),
          body: l10n.t('checkout_enter_card_body'),
          trailing: _PriceSummary(tier: _selectedTier),
        ),
        const SizedBox(height: 20),
        if (_paymentError != null) ...[
          _InlineAlert(
            icon: Icons.error_outline_rounded,
            message: _paymentError!,
          ),
          const SizedBox(height: 16),
        ],
        _CheckoutSurface(
          title: l10n.t('checkout_payment_method_title'),
          subtitle: l10n.t('checkout_payment_method_subtitle'),
          child: Form(
            key: _paymentFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller: _cardholderController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.t('checkout_field_cardholder'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  onChanged: (_) {
                    if (_paymentError != null) {
                      setState(() => _paymentError = null);
                    }
                  },
                  validator: (value) => _localizedPaymentMessage(
                    paymentService.validateCardholderName(value),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  decoration: InputDecoration(
                    labelText: l10n.t('checkout_field_card_number'),
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    hintText: '4242 4242 4242 4242',
                  ),
                  onChanged: (_) {
                    if (_paymentError != null) {
                      setState(() => _paymentError = null);
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    _CardNumberFormatter(),
                  ],
                  validator: (value) => _localizedPaymentMessage(
                    paymentService.validateCardNumber(value),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final expiryField = TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.creditCardExpirationDate,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.t('checkout_field_expiry'),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        hintText: l10n.t('checkout_hint_expiry'),
                      ),
                      onChanged: (_) {
                        if (_paymentError != null) {
                          setState(() => _paymentError = null);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      validator: (value) => _localizedPaymentMessage(
                        paymentService.validateExpiryDate(value),
                      ),
                    );
                    final cvvField = TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.creditCardSecurityCode,
                      ],
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.t('checkout_field_cvv'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: '123',
                      ),
                      onChanged: (_) {
                        if (_paymentError != null) {
                          setState(() => _paymentError = null);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) => _localizedPaymentMessage(
                        paymentService.validateCvv(
                          value,
                          cardNumber: _cardNumberController.text,
                        ),
                      ),
                    );

                    if (constraints.maxWidth < 390) {
                      return Column(
                        children: [
                          expiryField,
                          const SizedBox(height: 14),
                          cvvField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: expiryField),
                        const SizedBox(width: 12),
                        Expanded(child: cvvField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _AcceptedCardsRow(),
                const SizedBox(height: 12),
                _InfoStrip(
                  icon: Icons.info_outline_rounded,
                  text: l10n.t('checkout_demo_cards_note'),
                ),
                const SizedBox(height: 18),
                _InfoStrip(
                  icon: Icons.security_rounded,
                  text: l10n.t('checkout_payment_info'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _processingPayment ? null : _submitPayment,
                  icon: _processingPayment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_outline_rounded),
                  label: Text(
                    _processingPayment
                        ? l10n.t('checkout_processing')
                        : l10n.t('checkout_submit_payment'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _processingPayment
                      ? null
                      : () => setState(() => _step = _CheckoutStep.plans),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(l10n.t('checkout_back_plans')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    final l10n = context.l10n;
    final session = _authorizationSession;
    if (session == null) {
      return const SizedBox.shrink();
    }

    final attemptsRemaining = 3 - _otpAttempts;

    return Column(
      key: const ValueKey('verification'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          accent: AppTheme.premium,
          icon: Icons.verified_user_rounded,
          eyebrow: l10n.t('checkout_verification_eyebrow'),
          title: l10n.t('checkout_verification_title'),
          body: l10n.t(
            'checkout_verification_body',
            args: {'plan': formatSubscriptionTierLabel(_selectedTier)},
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PremiumBadge(label: session.paymentMethod.label),
              const SizedBox(height: 10),
              Text(
                formatSubscriptionPrice(_selectedTier),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_otpError != null) ...[
          _InlineAlert(
            icon: Icons.sms_failed_outlined,
            message: _otpError!,
          ),
          const SizedBox(height: 16),
        ],
        _CheckoutSurface(
          title: l10n.t('checkout_code_title'),
          subtitle: l10n.t('checkout_code_subtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckoutCodeCard(
                title: l10n.t('checkout_in_app_code_title'),
                subtitle: l10n.t('checkout_in_app_code_subtitle'),
                code: session.verificationCode,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(
                  labelText: l10n.t('checkout_field_code'),
                  hintText: '000000',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) {
                  if (_canVerifyOtp) {
                    _verifyCode();
                  }
                },
              ),
              const SizedBox(height: 16),
              _InfoStrip(
                icon: Icons.shield_outlined,
                text: l10n.t('checkout_verification_in_app_hint'),
              ),
              const SizedBox(height: 18),
              Text(
                _attemptsRemainingLabel(l10n, attemptsRemaining),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSoft,
                    ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _canVerifyOtp ? _verifyCode : null,
                icon: _verifyingCode
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(
                  _verifyingCode
                      ? l10n.t('checkout_verifying')
                      : l10n.t('checkout_verify_activate'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _canResendOtp ? _resendCode : null,
                icon: _resendingCode
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  _resendingCode
                      ? l10n.t('checkout_sending_code')
                      : l10n.t('checkout_resend_code'),
                ),
              ),
              if (_resendSecondsRemaining > 0) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.t(
                    'checkout_resend_available_in',
                    args: {'seconds': '$_resendSecondsRemaining'},
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.t('common_cancel')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailureStep() {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('failure'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          accent: const Color(0xFF9A6A63),
          icon: Icons.error_outline_rounded,
          eyebrow: l10n.t('checkout_failure_eyebrow'),
          title: l10n.t('checkout_failure_title'),
          body: _failureMessage ?? l10n.t('checkout_failure_body'),
          trailing: const Icon(
            Icons.lock_reset_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        _CheckoutSurface(
          title: l10n.t('checkout_failure_surface_title'),
          subtitle: l10n.t('checkout_failure_surface_subtitle'),
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  setState(() {
                    _step = _CheckoutStep.verification;
                    _otpAttempts = 0;
                    _otpError = null;
                    _failureMessage = null;
                  });
                  await _resendCode();
                },
                icon: const Icon(Icons.sms_rounded),
                label: Text(l10n.t('checkout_send_new_code')),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = _CheckoutStep.payment;
                    _otpAttempts = 0;
                    _otpError = null;
                    _failureMessage = null;
                  });
                },
                icon: const Icon(Icons.credit_card_rounded),
                label: Text(l10n.t('checkout_try_another_payment')),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.t('common_cancel')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final l10n = context.l10n;
    final receipt = _receipt;
    final tier = receipt?.tier ?? _selectedTier;
    final bullets = AppConstants.planFeatureBullets[tier] ?? const <String>[];

    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          accent: AppTheme.success,
          icon: Icons.check_circle_rounded,
          eyebrow: l10n.t('checkout_success_eyebrow'),
          title: l10n.t(
            'checkout_success_title',
            args: {'plan': formatSubscriptionTierLabel(tier)},
          ),
          body: l10n.t('checkout_success_body'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PremiumBadge(label: l10n.t('checkout_success_badge')),
              const SizedBox(height: 10),
              Text(
                receipt?.paymentMethod.label ?? '',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CheckoutSurface(
          title: l10n.t('checkout_success_surface_title'),
          subtitle: l10n.t('checkout_success_surface_subtitle'),
          child: Column(
            children: [
              ...bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BenefitRow(
                    icon: Icons.check_circle_rounded,
                    text: bullet,
                    accent: AppTheme.success,
                  ),
                ),
              ),
              if (receipt != null) ...[
                const SizedBox(height: 6),
                _InfoStrip(
                  icon: Icons.receipt_long_outlined,
                  text: l10n.t(
                    'checkout_success_receipt',
                    args: {
                      'date': formatShortDate(receipt.paidAt),
                      'method': receipt.paymentMethod.label,
                      'reference': receipt.transactionId.substring(0, 12),
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_receipt?.tier ?? tier),
          icon: const Icon(Icons.verified_rounded),
          label: Text(l10n.t('checkout_return_app')),
        ),
      ],
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress({
    required this.currentStep,
    required this.selectedTier,
  });

  final _CheckoutStep currentStep;
  final SubscriptionTier selectedTier;

  int get _activeIndex {
    switch (currentStep) {
      case _CheckoutStep.plans:
        return 0;
      case _CheckoutStep.payment:
        return 1;
      case _CheckoutStep.verification:
      case _CheckoutStep.failure:
        return 2;
      case _CheckoutStep.success:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.t('checkout_progress_plan'),
      context.l10n.t('checkout_progress_payment'),
      context.l10n.t('checkout_progress_verification'),
      context.l10n.t('checkout_progress_active'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PremiumBadge(label: formatSubscriptionTierLabel(selectedTier)),
            const SizedBox(width: 10),
            Text(
              formatSubscriptionPrice(selectedTier),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.accentDeep),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(labels.length, (index) {
            final isActive = index <= _activeIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: isActive
                            ? (index == labels.length - 1
                                ? AppTheme.success
                                : AppTheme.accent)
                            : AppTheme.border,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isActive
                                ? AppTheme.accentDeep
                                : AppTheme.textSoft,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CheckoutCodeCard extends StatelessWidget {
  const _CheckoutCodeCard({
    required this.title,
    required this.subtitle,
    required this.code,
  });

  final String title;
  final String subtitle;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.softSurface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.accentDeep,
                  letterSpacing: 4,
                  height: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}

class _SelectablePlanCard extends StatelessWidget {
  const _SelectablePlanCard({
    required this.tier,
    required this.selected,
    required this.locked,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final SubscriptionTier tier;
  final bool selected;
  final bool locked;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bullets = AppConstants.planFeatureBullets[tier] ?? const <String>[];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.9),
          border: Border.all(
            color: selected ? accent : AppTheme.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: selected ? 0.16 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatSubscriptionTierLabel(tier),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSubscriptionPrice(tier),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: accent,
                            ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  PremiumBadge(label: context.l10n.t('common_active'))
                else if (selected)
                  Icon(Icons.check_circle_rounded, color: accent, size: 28),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.planTaglines[tier] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ...bullets.take(3).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          locked
                              ? Icons.check_circle_rounded
                              : Icons.lock_open_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSurface extends StatelessWidget {
  const _CheckoutSurface({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.trailing,
  });

  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.88),
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.18),
                  accent,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightCardCopy(
                      icon: icon,
                      eyebrow: eyebrow,
                      title: title,
                      body: body,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: trailing,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HighlightCardCopy(
                        icon: icon,
                        eyebrow: eyebrow,
                        title: title,
                        body: body,
                      ),
                    ),
                    const SizedBox(width: 16),
                    trailing,
                  ],
                ),
        );
      },
    );
  }
}

class _HighlightCardCopy extends StatelessWidget {
  const _HighlightCardCopy({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      letterSpacing: 0.8,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: AppTheme.accentDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAE7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6B9B2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9A6A63)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.tier,
  });

  final SubscriptionTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.l10n.t('checkout_due_today'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            formatSubscriptionPrice(tier),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _AcceptedCardsRow extends StatelessWidget {
  const _AcceptedCardsRow();

  @override
  Widget build(BuildContext context) {
    const items = ['Visa', 'Mastercard', 'Amex'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.text,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = _formatCardNumber(digits);
    final digitsBeforeCursor = _digitCountBeforeSelection(
      newValue.text,
      newValue.selection.end,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _selectionForDigitIndex(formatted, digitsBeforeCursor),
      ),
    );
  }

  String _formatCardNumber(String digits) {
    final groups = digits.startsWith('34') || digits.startsWith('37')
        ? const [4, 6, 5]
        : const [4, 4, 4, 4, 3];
    final parts = <String>[];
    var start = 0;

    for (final size in groups) {
      if (start >= digits.length) {
        break;
      }
      final end = (start + size).clamp(0, digits.length);
      parts.add(digits.substring(start, end));
      start = end;
    }

    return parts.join(' ');
  }

  int _digitCountBeforeSelection(String text, int selectionEnd) {
    final safeEnd = selectionEnd.clamp(0, text.length);
    return text.substring(0, safeEnd).replaceAll(RegExp(r'\D'), '').length;
  }

  int _selectionForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) {
      return 0;
    }

    var seenDigits = 0;
    for (var index = 0; index < formatted.length; index += 1) {
      if (RegExp(r'\d').hasMatch(formatted[index])) {
        seenDigits += 1;
      }
      if (seenDigits >= digitIndex) {
        return index + 1;
      }
    }

    return formatted.length;
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;

    for (var index = 0; index < digits.length; index += 1) {
      if (index == 2) {
        buffer.write('/');
      }
      buffer.write(digits[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: digitsBeforeCursor <= 2
            ? digitsBeforeCursor
            : (digitsBeforeCursor + 1).clamp(0, formatted.length),
      ),
    );
  }
}
