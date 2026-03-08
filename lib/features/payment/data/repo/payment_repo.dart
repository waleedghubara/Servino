import 'dart:io';
import 'package:dio/dio.dart';
import 'package:servino_client/core/api/dio_consumer.dart';
import 'package:servino_client/features/payment/models/payment_gateway_model.dart';
import 'package:servino_client/features/payment/models/payment_params.dart';

class PaymentRepository {
  final DioConsumer api;

  PaymentRepository({required this.api});

  Future<List<PaymentGatewayModel>> getGateways() async {
    try {
      final response = await api.get('payment/get_gateways.php');

      if (response['status'] == 1 && response['data'] != null) {
        final List data = response['data'];
        return data.map((e) => PaymentGatewayModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> createTransaction({
    required int userId,
    required double amount,
    required int methodId,
    required String methodName,
    required String senderFrom,
    String? receiptImageInfo,
    String? planId,
    bool isSubscription = false,
    String? description,
    String? currency,
    double? originalAmount,
    int? discountPercentage,
    String? title,
    String? deviceInfo,
    String? bookingId,
    String? providerId,
    // Payer Details
    String? payerName,
    String? payerPhone,
    String? payerEmail,
    String? payerLocation,
    String? payerImage,
    // Provider Details
    String? providerName,
    String? providerPhone,
    String? providerEmail,
    String? providerImage,
    // App Info
    String? appOrigin,
  }) async {
    try {
      final response = await api.post(
        'payment/create_transaction.php',
        data: {
          'user_id': userId,
          'amount': amount,
          'method_id': methodId,
          'method_name': methodName,
          'sender_from': senderFrom,
          'receipt_image': receiptImageInfo ?? '',
          'plan_id': planId ?? '',
          'is_subscription': isSubscription ? 1 : 0,
          'description': description ?? '',
          'currency': currency ?? '',
          'original_amount': originalAmount ?? 0,
          'discount_percentage': discountPercentage ?? 0,
          'title': title ?? '',
          'app_type': 'provider', // Explicitly identifying this app
          'device_info': deviceInfo ?? '',
          'booking_id': bookingId,
          'provider_id': providerId,
          // Payer Details
          'payer_name': payerName ?? '',
          'payer_phone': payerPhone ?? '',
          'payer_email': payerEmail ?? '',
          'payer_location': payerLocation ?? '',
          'payer_image': payerImage ?? '',
          // Provider Details
          'provider_name': providerName ?? '',
          'provider_phone': providerPhone ?? '',
          'provider_email': providerEmail ?? '',
          'provider_image': providerImage ?? '',
          // App Info
          'app_origin':
              appOrigin ?? 'servino_client', // Default to 'servino_client'
        },
      );

      if (response['status'] == 1) {
        return response['transaction_id']?.toString();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus(
    String transactionId,
  ) async {
    try {
      final response = await api.get(
        'payment/check_status.php',
        queryParameters: {'transaction_id': transactionId},
      );

      if (response['status'] == 1 && response['data'] != null) {
        return {
          'status': response['data']['transaction_status'] ?? 'pending',
          'bookingId': response['data']['booking_id'],
        };
      }
      return {'status': 'pending'};
    } catch (e) {
      return {
        'status': 'pending',
      }; // Default to pending on error to keep polling
    }
  }

  Future<Map<String, dynamic>> verifyGoogleTransaction({
    required int userId,
    required String token,
    required double amount,
    required PaymentParams params,
    String? payerName,
    String? payerPhone,
    String? payerEmail,
    String? payerLocation,
  }) async {
    try {
      final response = await api.post(
        'payment/verify_google_transaction.php',
        data: {
          'user_id': userId,
          'token': token,
          'amount': amount,
          // Extract from params
          'currency': params.currency,
          'plan_id': params.planId,
          'is_subscription': params.isSubscription ? 1 : 0,
          'description': params.description,
          'original_amount': params.originalAmount,
          'discount_percentage': params.discountPercentage,
          'title': params.title,
          'app_type': 'provider',
          'booking_id': params.bookingId,
          'provider_id': params.providerId,
          // Payer Details
          'payer_name': payerName,
          'payer_phone': payerPhone,
          'payer_email': payerEmail,
          'payer_location': payerLocation,
          // Provider Details
          'provider_name': params.title,
          'provider_phone': params.providerPhone,
          'provider_email': params.providerEmail,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiatePaypal({
    required int userId,
    required double amount,
    required PaymentParams params,
    String? methodName,
    int? methodId,
  }) async {
    try {
      final response = await api.post(
        'payment/paypal_init.php',
        data: {
          'user_id': userId,
          'amount': amount,
          'currency': params.currency,
          'method_name': methodName ?? 'PayPal',
          'method_id': methodId ?? 0,
          'plan_id': params.planId,
          'is_subscription': params.isSubscription ? 1 : 0,
          'title': params.title,
          'description': params.description,
          'provider_id': params.providerId,
          'booking_id': params.bookingId,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadReceipt(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await api.post(
        'upload/file.php',
        data: formData,
        isFromData: false,
      );

      if (response['status'] == 1) {
        return response['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
