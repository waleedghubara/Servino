import 'dart:async';
// import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePlayService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onError;

  void initialize({
    required Function(PurchaseDetails) onSuccess,
    required Function(String) onError,
  }) {
    onPurchaseSuccess = onSuccess;
    this.onError = onError;

    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        // debugPrint('IAP Error: $error');
        onError('Payment stream error: $error');
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Initiates a purchase for a specific product ID.
  /// Note: The product must be configured in Google Play Console.
  Future<void> buyProduct(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      onError?.call('Google Play Store is not available');
      return;
    }

    // Set of product IDs to query
    final Set<String> kIds = <String>{productId};

    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );

    if (response.notFoundIDs.isNotEmpty) {
      if (response.notFoundIDs.contains(productId)) {
        if (productId == 'android.test.purchased') {
          // debugPrint(
          //   'Test product not found. SIMULATING SUCCESS for development.',
          // );
          // Simulate success
          final fakePurchase = PurchaseDetails(
            purchaseID: 'simulated_purchase_id',
            productID: productId,
            verificationData: PurchaseVerificationData(
              localVerificationData: 'sim_local_data',
              serverVerificationData: 'sim_server_token',
              source: 'google_play',
            ),
            transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
            status: PurchaseStatus.purchased,
          );
          _onPurchaseUpdate([fakePurchase]);
          return;
        }

        onError?.call(
          'Product $productId not found in Store. Ensure it is published and active.',
        );
        return;
      }
    }

    ProductDetails? productDetails;
    if (response.productDetails.isNotEmpty) {
      productDetails = response.productDetails.firstWhere(
        (p) => p.id == productId,
        orElse: () => response.productDetails.first,
      );
    } else {
      onError?.call('Product details not found for $productId.');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    // Auto-consume is handled in _onPurchaseUpdate for consumables
    // We assume these are consumables (one-time payments)
    try {
      final bool result = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
      );
      if (!result) {
        onError?.call('Failed to launch purchase flow.');
      }
    } catch (e) {
      onError?.call('Exception launching purchase: $e');
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // debugPrint('Purchase Pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          onError?.call(purchaseDetails.error?.message ?? 'Unknown error');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Deliver the product
          if (onPurchaseSuccess != null) {
            onPurchaseSuccess!(purchaseDetails);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }
}
