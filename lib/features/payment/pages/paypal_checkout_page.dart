// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/payment/data/repo/payment_repo.dart';
import 'package:servino_client/features/payment/models/payment_gateway_model.dart';
import 'package:servino_client/features/payment/models/payment_params.dart';
import 'package:servino_client/features/payment/pages/payment_success_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:servino_client/core/api/dio_consumer.dart';

class PaypalCheckoutPageParams {
  final PaymentParams params;
  final PaymentGatewayModel gateway;

  PaypalCheckoutPageParams({required this.params, required this.gateway});
}

class PaypalCheckoutPage extends StatefulWidget {
  final PaypalCheckoutPageParams args;

  const PaypalCheckoutPage({super.key, required this.args});

  @override
  State<PaypalCheckoutPage> createState() => _PaypalCheckoutPageState();
}

class _PaypalCheckoutPageState extends State<PaypalCheckoutPage> {
  late PaymentRepository _repository;
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isInitLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _repository = PaymentRepository(api: DioConsumer(dio: Dio()));
    _initPaypal();
  }

  Future<void> _initPaypal() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final res = await _repository.initiatePaypal(
        userId: user.id,
        amount: widget.args.params.amount,
        params: widget.args.params,
        methodId: widget.args.gateway.id,
        methodName: widget.args.gateway.keyword,
      );

      if (res['status'] == 1 && res['approve_url'] != null) {
        _setupWebViewController(res['approve_url'], res['order_id']);
      } else {
        throw Exception(res['message'] ?? "Unknown error initializing PayPal");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitLoading = false;
        });
      }
    }
  }

  void _setupWebViewController(String approveUrl, String orderId) {
    if (!mounted) return;

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Check for success or cancel callbacks
            if (url.contains('servino://payment/success') ||
                url.contains('#success')) {
              // Try to extract booking_id from the URL query params
              String? extractedBookingId = widget.args.params.bookingId;
              try {
                final uri = Uri.parse(url);
                if (uri.queryParameters.containsKey('booking_id') &&
                    uri.queryParameters['booking_id']!.isNotEmpty) {
                  extractedBookingId = uri.queryParameters['booking_id'];
                }
              } catch (e) {
                // Ignore parse errors
              }

              _handleSuccess(orderId, extractedBookingId);
              return NavigationDecision.prevent;
            } else if (url.contains('servino://payment/cancel') ||
                url.contains('#cancel')) {
              _handleCancel();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(approveUrl));

    setState(() {
      _controller = controller;
      _isInitLoading = false;
    });
  }

  void _handleSuccess(String orderId, String? bookingId) {
    // If it's a booking, go straight to chat/success
    if (bookingId != null && bookingId.isNotEmpty) {
      AppRouter.navigateAndRemoveUntil(
        context,
        Routes.bookingSuccess,
        arguments: {
          'isChatInitiated': true,
          'chatArguments': {
            'providerId': widget.args.params.providerId,
            'bookingId': bookingId,
            'isConsultation': true,
            'providerName': widget.args.params.title,
            'providerImage': widget.args.params.providerImage,
          },
        },
      );
    } else {
      // Normal payment success
      AppRouter.navigateAndRemoveUntil(
        context,
        Routes.paymentSuccess,
        arguments: PaymentSuccessPageParams(params: widget.args.params),
      );
    }
  }

  void _handleCancel() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment was cancelled.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/paypal_banner.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          title: Text(
            'Paypal Payment',
            style: TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _handleCancel(),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_error.isNotEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!),

          if (_isInitLoading || _isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
