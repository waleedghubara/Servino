import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/utils/toast_utils.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,

      extendBodyBehindAppBar: true,
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // Title & Description Animation
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        children: [
                          FadeInDown(
                            duration: const Duration(milliseconds: 1000),
                            child: Lottie.asset(
                              Assets.enterPassword,
                              height: 250.h,
                            ),
                          ),

                          SizedBox(height: 24.h),
                          Text(
                            'new_password_title'.tr(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'new_password_desc'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Form Container
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
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
                            _buildTextField(
                              controller: _passwordController,
                              label: 'register_password'.tr(),
                              hint: 'register_password_hint'.tr(),
                              icon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'password_required'.tr();
                                }
                                if (value.length < 6) {
                                  return 'password_too_short'.tr();
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 20.h),

                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'register_confirm_password'.tr(),
                              hint: 'register_confirm_password_hint'.tr(),
                              icon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              isPassword: true,
                              isConfirm: true,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'passwords_dont_match'.tr();
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 32.h),

                            // Reset Button
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, child) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        HapticFeedback.lightImpact();

                                        final args =
                                            ModalRoute.of(
                                                  context,
                                                )?.settings.arguments
                                                as Map<String, dynamic>?;
                                        final email = args?['email'];
                                        final otp = args?['otp'];

                                        if (email != null && otp != null) {
                                          context
                                              .read<AuthProvider>()
                                              .resetPassword(
                                                email: email,
                                                otp: otp,
                                                newPassword:
                                                    _passwordController.text,
                                              )
                                              .then((success) {
                                                if (success) {
                                                  ToastUtils.showSuccess(
                                                    context: context,
                                                    message:
                                                        "Password reset successfully",
                                                  );
                                                  AppRouter.navigateAndRemoveUntil(
                                                    context,
                                                    Routes.passwordResetSuccess,
                                                  );
                                                } else {
                                                  ToastUtils.showError(
                                                    context: context,
                                                    message:
                                                        auth.errorMessage ??
                                                        "Reset Failed",
                                                  );
                                                }
                                              });
                                        } else {
                                          ToastUtils.showError(
                                            context: context,
                                            message: "Missing Data (Email/OTP)",
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      elevation: 5,
                                      shadowColor: AppColors.primary
                                          .withOpacity(0.4),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: auth.isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Text(
                                                'password_reset'.tr(),
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF5F6FA),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22.sp),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirm
                              ? _isConfirmPasswordVisible
                              : _isPasswordVisible)
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
                      });
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
