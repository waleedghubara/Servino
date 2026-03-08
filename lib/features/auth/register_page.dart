// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/utils/toast_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _dobController = TextEditingController();
  String? _gender;
  DateTime? _selectedDate;

  bool _isPasswordVisible = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.black,
            ),
            dialogBackgroundColor:
                Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _isConfirmPasswordVisible = false;

  File? _image;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

                    // Profile Image Picker Animation
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120.r,
                              height: 120.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_image != null)
                                    CircleAvatar(
                                      radius: 58.r,
                                      backgroundImage: FileImage(_image!),
                                    )
                                  else
                                    Icon(
                                      Icons.person_outline,
                                      size: 50.sp,
                                      color: AppColors.primary,
                                    ),

                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.backgroundDark
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'imagere'.tr(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Form Container Animation
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
                              controller: _nameController,
                              label: 'register_full_name'.tr(),
                              hint: 'register_full_name_hint'.tr(),
                              icon: Icons.person_outline,
                              isDark: isDark,
                            ),

                            SizedBox(height: 16.h),

                            _buildTextField(
                              controller: _emailController,
                              label: 'login_email'.tr(),
                              hint: 'login_email_hint'.tr(),
                              icon: Icons.email_outlined,
                              isDark: isDark,
                            ),

                            SizedBox(height: 16.h),

                            _buildTextField(
                              controller: _phoneController,
                              label: 'register_phone'.tr(),
                              hint: 'register_phone_hint'.tr(),
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              isDark: isDark,
                            ),

                            SizedBox(height: 16.h),

                            // Date of Birth
                            _buildTextField(
                              controller: _dobController,
                              label: 'register_dob'.tr(),
                              hint: 'register_dob_hint'.tr(),
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                            ),

                            SizedBox(height: 16.h),

                            // Gender Dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'register_gender'.tr(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.backgroundDark
                                        : const Color(0xFFF5F6FA),
                                    prefixIcon: Icon(
                                      Icons.wc,
                                      color: AppColors.primary,
                                      size: 22.sp,
                                    ),
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
                                        color: AppColors.primary.withOpacity(
                                          0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  dropdownColor: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text(
                                        'gender_male'.tr(),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text(
                                        'gender_female'.tr(),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _gender = value;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'rating_required'.tr()
                                      : null, // Reuse generic required or add specific key
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            _buildTextField(
                              controller: _passwordController,
                              label: 'register_password'.tr(),
                              hint: 'register_password_hint'.tr(),
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isDark: isDark,
                              isConfirm: false,
                            ),

                            SizedBox(height: 16.h),

                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'register_confirm_password'.tr(),
                              hint: 'register_confirm_password_hint'.tr(),
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isDark: isDark,
                              isConfirm: true,
                            ),

                            SizedBox(height: 30.h),

                            // Register Button
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 56.h,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              HapticFeedback.lightImpact();

                                              authProvider
                                                  .register(
                                                    name: _nameController.text,
                                                    email:
                                                        _emailController.text,
                                                    phone:
                                                        _phoneController.text,
                                                    password:
                                                        _passwordController
                                                            .text,
                                                    confirmPassword:
                                                        _confirmPasswordController
                                                            .text,
                                                    dob:
                                                        _dobController
                                                            .text
                                                            .isNotEmpty
                                                        ? _dobController.text
                                                        : null,
                                                    gender: _gender,
                                                    image: _image,
                                                  )
                                                  .then((success) {
                                                    if (success) {
                                                      // Navigation
                                                      Navigator.pushReplacementNamed(
                                                        context,
                                                        Routes.otp,
                                                        arguments: {
                                                          'isRegister': true,
                                                          'email':
                                                              _emailController
                                                                  .text,
                                                        },
                                                      ); // Or wherever
                                                    } else {
                                                      ToastUtils.showError(
                                                        context: context,
                                                        message:
                                                            authProvider
                                                                .errorMessage ??
                                                            'Registration failed',
                                                      );
                                                    }
                                                  });
                                            } else {
                                              // Form Validation Failed
                                              ToastUtils.showError(
                                                context: context,
                                                message: 'register_fill_fields'
                                                    .tr(), // Or a generic message
                                                title: 'Validation Error',
                                              );
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
                                        child: authProvider.isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Text(
                                                'register_register'.tr(),
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                                            message: "Welcome!",
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
                                          final error = context
                                              .read<AuthProvider>()
                                              .errorMessage;
                                          if (error != null) {
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
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/1024px-Google_\"G\"_logo.svg.png',
                                  height: 24.h,
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
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Login Link
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 1000),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "register_already_have_account".tr(),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey.shade600,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'register_login'.tr(),
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
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    bool readOnly = false,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          onTap: onTap,
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          keyboardType: keyboardType,
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
          ),
        ),
      ],
    );
  }
}
