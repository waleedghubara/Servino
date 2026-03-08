// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';

class BookingSuccessPage extends StatelessWidget {
  final bool isChatInitiated;
  final Map<String, dynamic>? chatArguments;

  const BookingSuccessPage({
    super.key,
    this.isChatInitiated = false,
    this.chatArguments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Card
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 40.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark.withOpacity(0.9)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated-like Success Icon
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(10.w),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green,
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              Assets.bookingSuccess,
                              width: 120.w,
                              height: 120.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        Text(
                          'booking_confirmed_msg'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'booking_success_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 40.h),

                        // Primary Button
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isChatInitiated) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  Routes.main,
                                  (route) => false,
                                );
                                AppRouter.navigateTo(
                                  context,
                                  Routes.chat,
                                  arguments: chatArguments,
                                );
                              } else {
                                AppRouter.navigateAndRemoveUntil(
                                  context,
                                  Routes.main,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 8,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              isChatInitiated
                                  ? 'start_chat'.tr()
                                  : 'booking_go_home'.tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Success Confetti/Animation Overlay "From Above"
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Lottie.asset(
                Assets.successba,
                width: 1.sw,
                height: 0.6.sh, // Cover top 60% of screen or adjust as needed
                fit: BoxFit.cover,
                repeat: false, // Play once
              ),
            ),
          ),
        ],
      ),
    );
  }
}
