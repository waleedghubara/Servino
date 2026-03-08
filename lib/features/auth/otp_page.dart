// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async'; // Added
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/colors.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import '../../core/theme/assets.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _start = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isRegister = arguments?['isRegister'] ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [AppColors.primary2, AppColors.backgroundDark]
                      : [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.background,
                        ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  // Animation
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Lottie.asset(Assets.enterPassword, height: 200.h),
                  ),

                  SizedBox(height: 32.h),

                  // Title & Description
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        Text(
                          'otp_title'.tr(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'otp_desc'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // OTP Fields
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => SizedBox(
                                width: 45.w,
                                height: 60.h,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  onChanged: (value) =>
                                      _onOtpChanged(value, index),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.backgroundDark
                                        : const Color(0xFFF5F6FA),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.secondaryDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                String otp = _controllers
                                    .map((e) => e.text)
                                    .join();
                                if (otp.length < 6) {
                                  ToastUtils.showError(
                                    context: context,
                                    message: "Please enter complete OTP",
                                  );
                                  return;
                                }

                                if (isRegister) {
                                  final email = arguments?['email'];
                                  if (email == null) {
                                    ToastUtils.showError(
                                      context: context,
                                      message: "Email not found",
                                    );
                                    return;
                                  }

                                  context
                                      .read<AuthProvider>()
                                      .verifyOtp(email: email, otp: otp)
                                      .then((success) {
                                        if (success) {
                                          ToastUtils.showSuccess(
                                            context: context,
                                            message: "Account Verified!",
                                          );
                                          AppRouter.navigateAndRemoveUntil(
                                            context,
                                            Routes
                                                .registerSuccess, // Go to Home after verification
                                          );
                                        } else {
                                          ToastUtils.showError(
                                            context: context,
                                            message:
                                                context
                                                    .read<AuthProvider>()
                                                    .errorMessage ??
                                                "Verification Failed",
                                          );
                                        }
                                      });
                                } else {
                                  // Reset Password Logic - Verify OTP first generally good practice
                                  // Or just pass it to next screen. Let's verify it to check validity.
                                  // BUT resetPassword endpoint needs OTP.
                                  // If we verify here, we might invalidate it? NO, verify just checks/updates status.
                                  // Actually User.verifyOtp updates is_verified = 1 and otp = NULL.
                                  // IF WE CALL VERIFYOTP HERE, 'otp' becomes NULL in DB.
                                  // THEN resetPassword will FAIL because it checks OTP.
                                  // CRITICAL: DO NOT CALL verifyOtp for Password Reset if verifyOtp clears the code!
                                  // Let's check User.php verifyOtp... Yes, it sets otp = NULL.

                                  // So for Reset Password, we should NOT call verifyOtp API.
                                  // We should just pass the OTP to the next screen.
                                  // Wait, how do we know if it's correct before navigating?
                                  // We could add a 'checkOtp' endpoint that doesn't clear it, OR allow resetPassword to handle the failure.
                                  // For now, let's navigate to ResetPasswordPage with the OTP.
                                  // If it's wrong, ResetPasswordPage will show error when submitting.

                                  final email = arguments?['email'];
                                  AppRouter.navigateTo(
                                    context,
                                    Routes.resetPassword,
                                    arguments: {'email': email, 'otp': otp},
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 5,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                              ),
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, child) {
                                  return Ink(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: auth.isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : Text(
                                              'otp_verify'.tr(),
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Resend Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 1000),
                    child: TextButton(
                      onPressed: _canResend
                          ? () {
                              final email = arguments?['email'];
                              if (email != null) {
                                context
                                    .read<AuthProvider>()
                                    .resendOtp(email: email)
                                    .then((success) {
                                      if (success) {
                                        ToastUtils.showSuccess(
                                          context: context,
                                          message: "OTP Resent!",
                                        );
                                        startTimer();
                                      } else {
                                        ToastUtils.showError(
                                          context: context,
                                          message:
                                              context
                                                  .read<AuthProvider>()
                                                  .errorMessage ??
                                              "Failed to resend",
                                        );
                                      }
                                    });
                              }
                            }
                          : null,
                      child: Text(
                        _canResend
                            ? 'otp_resend'.tr()
                            : '${'otp_resend'.tr()} ($_start)',
                        style: TextStyle(
                          color: _canResend
                              ? (isDark ? Colors.white70 : AppColors.primary)
                              : Colors.grey,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
