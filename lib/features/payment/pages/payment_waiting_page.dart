// ignore_for_file: unused_field, deprecated_member_use

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/api/dio_consumer.dart';

import 'package:servino_client/features/payment/data/repo/payment_repo.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/payment/pages/payment_success_page.dart';
import 'package:servino_client/features/payment/models/payment_params.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';

class PaymentWaitingPage extends StatefulWidget {
  final PaymentParams params;
  final String? transactionId;

  const PaymentWaitingPage({
    super.key,
    required this.params,
    this.transactionId,
  });

  @override
  State<PaymentWaitingPage> createState() => _PaymentWaitingPageState();
}

class _PaymentWaitingPageState extends State<PaymentWaitingPage>
    with TickerProviderStateMixin {
  late Timer _timer;
  int _start = 900; // 15 minutes in seconds
  double _progress = 0.0;
  String _statusKey = 'payment_status_verifying';

  late AnimationController _pulseController;
  late PaymentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = PaymentRepository(api: DioConsumer(dio: Dio()));
    _startTimer();

    if (widget.transactionId != null) {
      _startPolling();
    } else {
      _simulateVerification();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          // Timeout reached
          if (mounted) {
            AppRouter.navigateTo(
              context,
              Routes.paymentSuccess,
              arguments: PaymentSuccessPageParams(
                params: widget.params,
                status: PaymentStatus.timeout,
              ),
            );
          }
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _startPolling() async {
    // Poll every 5 seconds
    while (_start > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      final result = await _repository.checkTransactionStatus(
        widget.transactionId!,
      );

      final statusStr = result['status'].toString().toLowerCase();
      final bookingId = result['bookingId']?.toString();

      if (statusStr == 'approved' ||
          statusStr == 'success' ||
          statusStr == 'confirmed') {
        _paymentApproved(bookingId);
        break;
      } else if (statusStr == 'rejected' ||
          statusStr == 'declined' ||
          statusStr == 'failed') {
        if (mounted) {
          AppRouter.navigateTo(
            context,
            Routes.paymentSuccess,
            arguments: PaymentSuccessPageParams(
              params: widget.params,
              status: PaymentStatus.failed,
            ),
          );
        }
        break;
      }
    }
  }

  void _paymentApproved(String? bookingId) {
    setState(() {
      _progress = 1.0;
      _statusKey = 'payment_status_confirmed';
    });

    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      // Refresh User Profile to get subscription details
      try {
        await context.read<AuthProvider>().loadUser();
      } catch (e) {
        debugPrint('Refresh user failed: $e');
      }

      if (!mounted) return;

      if (bookingId != null && bookingId.isNotEmpty) {
        // Navigate to Success Page first, passing Chat arguments
        AppRouter.navigateTo(
          context,
          Routes.bookingSuccess,
          arguments: {
            'isChatInitiated': true,
            'chatArguments': {
              'providerId': widget.params.providerId,
              'bookingId': bookingId,
              'isConsultation': true,
              'providerName': widget.params.title,
              'providerImage': widget.params.providerImage,
            },
          },
        );
      } else {
        AppRouter.navigateTo(
          context,
          Routes.paymentSuccess,
          arguments: PaymentSuccessPageParams(
            params: widget.params,
            status: PaymentStatus.success,
          ),
        );
      }
    });
  }

  void _simulateVerification() async {
    // Stage 1: Verifying
    setState(() => _progress = 0.3);
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;
    setState(() => _progress = 0.6);
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Stage 2: Confirmed (Mock)
    setState(() {
      _progress = 1.0;
      _statusKey = 'payment_status_confirmed';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Navigate to Success
    AppRouter.navigateTo(
      context,
      Routes.paymentSuccess,
      arguments: PaymentSuccessPageParams(
        params: widget.params, // Pass params
        status: PaymentStatus.success,
      ),
    );
  }

  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(32.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Pulse Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 160.w,
                              height: 160.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.2),
                                    AppColors.primary.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 120.w,
                            height: 120.w,
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : Colors.white,

                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120.w,
                                  height: 120.w,
                                  child: CircularProgressIndicator(
                                    value: _progress == 0 ? null : _progress,
                                    strokeWidth: 6,
                                    backgroundColor: isDark
                                        ? AppColors.backgroundDark
                                        : Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  timerText,
                                  style: TextStyle(
                                    fontSize: 40.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'BOOTERFF',
                                    letterSpacing: 1.0,
                                  ),
                                ),

                                Positioned(
                                  bottom: 17.h,
                                  child: Text(
                                    'payment_timer_label'.tr(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32.h),

                      Text(
                        'payment_waiting_title'.tr(),
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Text(
                        'payment_waiting_desc'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Status Steps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusStep('payment_status_sent'.tr(), true),
                          _buildConnector(true),
                          _buildStatusStep(
                            'payment_status_verifying'.tr(),
                            true,
                          ),
                          _buildConnector(_progress == 1.0),
                          _buildStatusStep(
                            'payment_status_confirmed'.tr(),
                            _progress == 1.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, bool isActive) {
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = Colors.grey[300]!;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check,
            color: isActive ? activeColor : Colors.transparent,
            size: 14.sp,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 30.w,
      height: 2.h,
      color: isActive ? AppColors.primary : Colors.grey[200],
      margin: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 14.h,
      ), // adjusted vertical margin to align with circle
      transform: Matrix4.translationValues(
        0,
        -10.h,
        0,
      ), // Shift up to align with dots
    );
  }
}
