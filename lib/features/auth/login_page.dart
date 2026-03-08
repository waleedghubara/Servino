// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/assets.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/utils/toast_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  static const String _savedAccountsKey = 'saved_accounts';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSavedAccounts();
    });
  }

  Future<void> _checkSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccountsJson = prefs.getString(_savedAccountsKey);

    if (savedAccountsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedAccountsJson);
        final List<Map<String, String>> savedAccounts = decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();

        if (savedAccounts.isNotEmpty && mounted) {
          _showSavedAccountsSheet(savedAccounts);
        }
      } catch (e) {
        // debugPrint('Error decoding saved accounts: $e');
      }
    }
  }

  void _showSavedAccountsSheet(List<Map<String, String>> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'login_saved_accounts'.tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'login_choose_account'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 20.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppColors.primary),
                      ),
                      title: Text(
                        account['email'] ?? '',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () async {
                          Navigator.pop(context); // Close sheet to refresh
                          await _removeAccount(index);
                          // Re-fetch and show if still has accounts
                          _checkSavedAccounts();
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _emailController.text = account['email'] ?? '';
                          _passwordController.text = account['password'] ?? '';
                          _rememberMe = true; // Auto check if selected
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeAccount(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccountsJson = prefs.getString(_savedAccountsKey);
    if (savedAccountsJson != null) {
      List<dynamic> decoded = jsonDecode(savedAccountsJson);
      List<Map<String, String>> accounts = decoded
          .map((e) => Map<String, String>.from(e as Map))
          .toList();

      if (index >= 0 && index < accounts.length) {
        accounts.removeAt(index);
        await prefs.setString(_savedAccountsKey, jsonEncode(accounts));
      }
    }
  }

  Future<void> _saveAccount() async {
    if (!_rememberMe) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final prefs = await SharedPreferences.getInstance();
    final savedAccountsJson = prefs.getString(_savedAccountsKey);
    List<Map<String, String>> accounts = [];

    if (savedAccountsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedAccountsJson);
        accounts = decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      } catch (e) {
        // Init empty
      }
    }

    // Check if exists and update, or add new
    final index = accounts.indexWhere((element) => element['email'] == email);
    if (index != -1) {
      accounts[index] = {'email': email, 'password': password};
    } else {
      accounts.add({'email': email, 'password': password});
    }

    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
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
                  children: [
                    SizedBox(height: 10.h),

                    // Header Animation
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Lottie.asset(Assets.login, height: 250.h),
                    ),

                    SizedBox(height: 10.h),

                    // Welcome Text
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        children: [
                          Text(
                            'login_welcome'.tr(),
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
                            'login_title'.tr(),
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
                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              label: 'login_email'.tr(),
                              hint: 'login_email_hint'.tr(),
                              icon: Icons.email_outlined,
                              isDark: isDark,
                            ),

                            SizedBox(height: 20.h),

                            // Password Field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'login_password'.tr(),
                              hint: 'login_password_hint'.tr(),
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isDark: isDark,
                            ),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remember Me
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                    Text(
                                      'login_remember_me'.tr(),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                // Forgot Password
                                TextButton(
                                  onPressed: () {
                                    AppRouter.navigateTo(
                                      context,
                                      Routes.forgotPassword,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'login_forgot_password'.tr(),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24.h),

                            // Login Button
                            ElevatedButton(
                              onPressed: () async {
                                // Basic validation
                                if (_emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }

                                HapticFeedback.lightImpact();

                                // Save account if remember me is checked
                                await _saveAccount();

                                if (mounted) {
                                  context
                                      .read<AuthProvider>()
                                      .login(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        locale: context.locale.languageCode,
                                      )
                                      .then((success) {
                                        if (success) {
                                          ToastUtils.showSuccess(
                                            context: context,
                                            message: "Welcome back!",
                                          );
                                          AppRouter.navigateAndRemoveUntil(
                                            context,
                                            Routes.main,
                                          );
                                        } else {
                                          final error = context
                                              .read<AuthProvider>()
                                              .errorMessage;
                                          if (error != null &&
                                              error.toLowerCase().contains(
                                                'banned',
                                              )) {
                                            AppRouter.navigateAndRemoveUntil(
                                              context,
                                              Routes.banned,
                                            );
                                            return;
                                          } else if (error == 'Unverified') {
                                            ToastUtils.showError(
                                              context: context,
                                              message:
                                                  "Account not verified. OTP sent.",
                                            );
                                            AppRouter.navigateTo(
                                              context,
                                              Routes.otp,
                                              arguments: {
                                                'isRegister': true,
                                                'email': _emailController.text,
                                              },
                                            );
                                          } else {
                                            ToastUtils.showError(
                                              context: context,
                                              message: error ?? "Login Failed",
                                            );
                                          }
                                        }
                                      });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 56.h),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 5,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                              ),
                              child: context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'login_sign_in'.tr(),
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),

                            SizedBox(height: 20.h),
                            // Google Sign In
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  await context
                                      .read<AuthProvider>()
                                      .signInWithGoogle(context)
                                      .then((status) {
                                        if (status == 1) {
                                          ToastUtils.showSuccess(
                                            context: context,
                                            message: "Welcome back!",
                                          );
                                          AppRouter.navigateAndRemoveUntil(
                                            context,
                                            Routes.main,
                                          );
                                        } else if (status == 2) {
                                          ToastUtils.showSuccess(
                                            context: context,
                                            message:
                                                "Please complete your profile",
                                          );
                                          AppRouter.navigateAndReplace(
                                            context,
                                            Routes.completeProfile,
                                          );
                                        } else if (status == -1) {
                                          // Error handled in provider/toast
                                          final error = context
                                              .read<AuthProvider>()
                                              .errorMessage;
                                          if (error != null &&
                                              error.toLowerCase().contains(
                                                'banned',
                                              )) {
                                            return;
                                          }
                                          if (error != null) {
                                            print(error);
                                            ToastUtils.showError(
                                              context: context,
                                              message: error,
                                            );
                                          }
                                        }
                                      });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                                icon: CachedNetworkImage(
                                  imageUrl:
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/1024px-Google_"G"_logo.svg.png',
                                  height: 24.h,
                                  placeholder: (context, url) => SizedBox(
                                    height: 24.h,
                                    width: 24.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                label: Text(
                                  'register_google'.tr(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30.h),

                            // Sign Up Link
                            FadeInUp(
                              delay: const Duration(milliseconds: 600),
                              duration: const Duration(milliseconds: 1000),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "login_dont_have_account".tr(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      AppRouter.navigateTo(
                                        context,
                                        Routes.register,
                                      );
                                    },
                                    child: Text(
                                      'login_sign_up'.tr(),
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
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
    required bool isDark,
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
          obscureText: isPassword && !_isPasswordVisible,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
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
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
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
          ),
        ),
      ],
    );
  }
}
