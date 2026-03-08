// ignore_for_file: deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/payment/models/payment_params.dart';

enum PaymentStatus { success, failed, timeout }

class PaymentSuccessPageParams {
  final PaymentParams params;
  final PaymentStatus status;

  PaymentSuccessPageParams({
    required this.params,
    this.status = PaymentStatus.success, // Default to success
  });
}

class PaymentSuccessPage extends StatefulWidget {
  final PaymentSuccessPageParams params;

  const PaymentSuccessPage({super.key, required this.params});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late PaymentStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.params.status;

    // Auto-redirect if success and subscription
    if (_status == PaymentStatus.success) {
      if (widget.params.params.isSubscription) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _goHome(); // Or navigate to active subscription page
          }
        });
      }
    }
  }

  void _contactSupport() {
    AppRouter.navigateTo(
      context,
      Routes.helpCenter,
      arguments: {
        'initialDescription':
            '${'payment_failed_title'.tr()} - Status: ${_status.name}',
      },
    );
  }

  void _goHome() {
    AppRouter.navigateAndRemoveUntil(context, Routes.main);
  }

  String _getLottieAsset() {
    switch (_status) {
      case PaymentStatus.success:
        return Assets.success;
      case PaymentStatus.failed:
        return Assets.unsuccessful;
      case PaymentStatus.timeout:
        return Assets.support;
    }
  }

  String _getTitle() {
    final bool isSub = widget.params.params.isSubscription;
    switch (_status) {
      case PaymentStatus.success:
        return isSub
            ? 'subscription_success_title'.tr()
            : 'payment_success_title'.tr();
      case PaymentStatus.failed:
        return isSub
            ? 'subscription_failed_title'.tr()
            : 'payment_failed_title'.tr();
      case PaymentStatus.timeout:
        return 'payment_timeout_title'.tr();
    }
  }

  String _getDesc() {
    final bool isSub = widget.params.params.isSubscription;
    switch (_status) {
      case PaymentStatus.success:
        return isSub
            ? 'subscription_success_desc'.tr()
            : 'payment_success_desc'.tr();
      case PaymentStatus.failed:
        return isSub
            ? 'subscription_failed_desc'.tr()
            : 'payment_failed_desc'.tr();
      case PaymentStatus.timeout:
        return 'payment_timeout_desc'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Lottie.asset(
                        _getLottieAsset(),
                        height: 250.h,
                        repeat: _status != PaymentStatus.success,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      _getTitle(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: _status == PaymentStatus.failed
                            ? Colors.red
                            : const Color.fromARGB(255, 0, 255, 8),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _getDesc(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDark ? Colors.white : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 48.h),

                    // Actions
                    if (_status == PaymentStatus.success)
                      _buildButton(
                        'back_to_home',
                        AppColors.primary,
                        isDark ? Colors.white : Colors.white,
                        _goHome,
                      )
                    else if (_status == PaymentStatus.failed)
                      Column(
                        children: [
                          _buildButton(
                            'contact_support',
                            AppColors.primary,
                            isDark ? Colors.white : Colors.black,
                            _contactSupport,
                          ),
                          SizedBox(height: 16.h),
                          _buildButton(
                            'back_to_home',
                            isDark ? Colors.white : Colors.black,
                            AppColors.primary,
                            _goHome,
                            isOutlined: true,
                          ),
                        ],
                      )
                    else if (_status == PaymentStatus.timeout)
                      _buildButton(
                        'contact_support',
                        AppColors.primary,
                        isDark ? Colors.white : Colors.white,
                        _contactSupport,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String key,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : bgColor,
          elevation: isOutlined ? 0 : 8,
          shadowColor: isOutlined ? null : bgColor.withOpacity(0.4),
          side: isOutlined ? BorderSide(color: textColor, width: 2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          key.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
