class PaymentCardInput {
  const PaymentCardInput({
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });

  final String cardholderName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  String get normalizedCardholderName =>
      cardholderName.trim().replaceAll(RegExp(r'\s+'), ' ');

  String get normalizedCardNumber => cardNumber.replaceAll(RegExp(r'\D'), '');

  String get normalizedExpiryDate => expiryDate.replaceAll(' ', '');

  String get normalizedCvv => cvv.replaceAll(RegExp(r'\D'), '');

  String get last4 {
    final digits = normalizedCardNumber;
    if (digits.length <= 4) {
      return digits;
    }
    return digits.substring(digits.length - 4);
  }
}
