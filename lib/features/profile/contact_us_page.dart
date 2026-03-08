// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      children: [
                        // Introductory Text
                        Text(
                          'contact_us_title'.tr(),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'contact_us_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        Lottie.asset(Assets.contactus),

                        // Contact Options
                        _buildContactCard(
                          context,
                          isDark,
                          title: 'contact_us_telegram_channel'.tr(),
                          subtitle: 'contact_us_telegram_channel_sub'.tr(),
                          icon: Assets.telegram,
                          iconColor: const Color(0xFF0088cc),
                          onTap: () =>
                              _launchUrl('https://t.me/+k6yqrFyJE1hjMWI0'),
                        ),
                        SizedBox(height: 16.h),

                        _buildContactCard(
                          context,
                          isDark,
                          title: 'contact_us_telegram_account'.tr(),
                          subtitle: 'contact_us_telegram_account_sub'.tr(),
                          icon: Assets.telegram,
                          iconColor: const Color(0xFF0088cc),
                          onTap: () => _launchUrl('https://t.me/servinoapp'),
                        ),
                        SizedBox(height: 16.h),

                        _buildContactCard(
                          context,
                          isDark,
                          title: 'contact_us_whatsapp'.tr(),
                          subtitle: 'contact_us_whatsapp_sub'.tr(),
                          icon: Assets.whatsapp,
                          iconColor: const Color(0xFF25D366),
                          onTap: () => _launchUrl('https://wa.me/201151014669'),
                        ),
                        SizedBox(height: 16.h),

                        _buildContactCard(
                          context,
                          isDark,
                          title: 'contact_us_website'.tr(),
                          subtitle: 'contact_us_website_sub'.tr(),
                          icon: Assets.website,
                          iconColor: AppColors.primary,
                          onTap: () => _launchUrl(
                            'https://walidghubara.online/servino/',
                          ),
                        ),
                        SizedBox(height: 16.h),

                        _buildContactCard(
                          context,
                          isDark,
                          title: 'contact_us_facebook'.tr(),
                          subtitle: 'contact_us_facebook_sub'.tr(),
                          icon: Assets.facebook,
                          iconColor: const Color(0xFF1877F2),
                          onTap: () => _launchUrl(
                            'https://www.facebook.com/profile.php?id=61586244876657',
                          ),
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required String icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(icon, width: 28.w, height: 28.h),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  context.locale.languageCode == 'ar'
                      ? Icons.keyboard_arrow_left_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
