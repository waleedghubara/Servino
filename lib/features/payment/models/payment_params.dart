class PaymentParams {
  final String title;
  final double amount;
  final String currency;
  final String description;
  final bool isSubscription;
  final String? planId; // For subscription
  final String? bookingId; // For consultation
  final String? providerId; // For provider payment
  final double? originalAmount;
  final int? discountPercentage;
  final String? providerPhone; // Optional provider phone for payment reference
  final String? providerEmail;
  final String? providerImage;

  PaymentParams({
    required this.title,
    required this.amount,
    required this.currency,
    required this.description,
    this.isSubscription = false,
    this.planId,
    this.bookingId,
    this.providerId,
    this.originalAmount,
    this.discountPercentage,
    this.providerPhone,
    this.providerEmail,
    this.providerImage,
  });
}
