// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';

class ConsultationCompletionDialog extends StatefulWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const ConsultationCompletionDialog({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  State<ConsultationCompletionDialog> createState() =>
      _ConsultationCompletionDialogState();
}

class _ConsultationCompletionDialogState
    extends State<ConsultationCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Effect Container
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon (Gradient Circle with Lottie)
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.4),
                                AppColors.primary.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Lottie.asset(
                            Assets.bookingSuccess,
                            height: 60.sp,
                            width: 60.sp,
                            repeat: false,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Question
                        Text(
                          'consultation_completed_question'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primary
                                : AppColors.primary22,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 12.h,
                        ), // Provider uses 24.h space next?

                        Text(
                          'consultation_completed_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.white,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                context,
                                'no'.tr(),
                                widget.onNo,
                                isPrimary: false,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildButton(
                                context,
                                'yes'.tr(),
                                widget.onYes,
                                isPrimary: true,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    required bool isPrimary,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.8)
              : (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.2),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? Colors.white
                  : (isDark
                        ? Colors.white
                        : AppColors.surface), // Matches provider
            ),
          ),
        ),
      ),
    );
  }
}
