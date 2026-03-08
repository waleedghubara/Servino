// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/theme/typography.dart';
import 'package:servino_client/core/routes/routes.dart';

class BannedPage extends StatelessWidget {
  const BannedPage({super.key});

  void _showContactOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                'contact_options_title'.tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              _buildContactOption(
                context,
                icon: Icons.telegram,
                title: 'contact_telegram'.tr(),
                color: Colors.blue,
                onTap: () => _launchURL('https://t.me/servinoapp'),
              ),
              const Divider(height: 1),
              _buildContactOption(
                context,
                icon: Icons.chat,
                title: 'contact_whatsapp'.tr(),
                color: Colors.green,
                onTap: () => _launchURL('https://wa.me/201151014669'),
              ),
              const Divider(height: 1),
              _buildContactOption(
                context,
                icon: Icons.language,
                title: 'contact_website'.tr(),
                color: AppColors.primary,
                onTap: () => _launchURL('https://walidghubara.online/servino'),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: WillPopScope(
        onWillPop: () async => false, // Prevent back navigation
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Vibrant Background Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Color(0xFF1F1012), // Deep dark red tint
                              Color(0xFF121212),
                            ]
                          : [
                              Color(0xFFFFEBEE), // Light red tint
                              Colors.white,
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Decorative Animated Blur Blobs
              Positioned(
                top: -100.h,
                left: -50.w,
                child: Container(
                  width: 300.w,
                  height: 300.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withOpacity(isDark ? 0.3 : 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animation inside a beautiful container
                          Container(
                            height: 250.h,
                            width: 250.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.15),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              Assets
                                  .unsuccessful, // Utilizing the unsuccessful animation
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                          SizedBox(height: 40.h),

                          // Glassmorphic Card for Text & Buttons
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: EdgeInsets.all(32.w),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 30,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'account_suspended'.tr(),
                                      style: AppTypography.h1.copyWith(
                                        color: AppColors.error,
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'account_suspended_desc'.tr(),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                        height: 1.6,
                                        fontSize: 14.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 40.h),

                                    // Action Buttons
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showContactOptions(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                          ),
                                          elevation: 5,
                                          shadowColor: AppColors.error
                                              .withOpacity(0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'contact_support'.tr(),
                                          style: AppTypography.button.copyWith(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(
                                          context,
                                        ).pushNamedAndRemoveUntil(
                                          Routes.login,
                                          (route) => false,
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.h,
                                          horizontal: 24.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Text(
                                          'back_to_login'.tr(),
                                          style: AppTypography.button.copyWith(
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
