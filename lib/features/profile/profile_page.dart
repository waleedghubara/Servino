// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/theme_manager.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          CustomScrollView(
            slivers: [
              // Premium Gradient Header (Transparent to show AnimatedBG or standard gradient)
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20.h,
                    bottom: 30.h,
                    left: 24.w,
                    right: 24.w,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.9),
                        AppColors.primary2,
                        AppColors.secondaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32.r),
                      bottomRight: Radius.circular(32.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'profile_title'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          final user = auth.user;
                          return Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 40.r,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      user?.fullImage != null &&
                                          user!.fullImage!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          user.fullImage!,
                                        )
                                      : null,
                                  onBackgroundImageError:
                                      user?.fullImage != null &&
                                          user!.fullImage!.isNotEmpty
                                      ? (_, _) {}
                                      : null,
                                  child:
                                      user?.fullImage == null ||
                                          user!.fullImage!.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 45.sp,
                                          color: AppColors.primary2,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(width: 20.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'Servino',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      user?.email ?? '',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Sections
              SliverPadding(
                padding: EdgeInsets.all(24.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileCard(context, [
                      // View Personal Info
                      _buildMenuTile(
                        context,
                        icon: Icons.person_outline,
                        title: 'profile_view_personal_info'.tr(),
                        onTap: () => AppRouter.navigateTo(
                          context,
                          Routes.personalInformation,
                        ),
                      ),
                      // Language
                      _buildMenuTile(
                        context,
                        icon: Icons.language_outlined,
                        title: 'profile_language'.tr(),
                        subtitle: context.locale.languageCode == 'ar'
                            ? 'profile_arabic'.tr()
                            : 'profile_english'.tr(),
                        onTap: () => _showLanguagePicker(context),
                      ),
                      // Theme
                      _buildMenuTile(
                        context,
                        icon: Icons.brightness_6_outlined,
                        title: 'profile_theme'.tr(),
                        onTap: () => _showThemePicker(context),
                      ),
                      // Help
                      _buildMenuTile(
                        context,
                        icon: Icons.help_outline,
                        title: 'profile_help'.tr(),
                        onTap: () =>
                            AppRouter.navigateTo(context, Routes.helpCenter),
                      ),
                      // Contact Us
                      _buildMenuTile(
                        context,
                        icon: Icons.contact_support_outlined,
                        title: 'تواصل معنا', // 'contact_us'.tr()
                        subtitle: 'تليجرام، واتساب والمزيد',
                        onTap: () =>
                            AppRouter.navigateTo(context, Routes.contactUs),
                      ),
                      // Terms of Use
                      _buildMenuTile(
                        context,
                        icon: Icons.description_outlined,
                        title: 'profile_terms'.tr(),
                        onTap: () =>
                            AppRouter.navigateTo(context, Routes.termsOfUse),
                      ),
                      // Privacy
                      _buildMenuTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: 'profile_privacy'.tr(),
                        onTap: () =>
                            AppRouter.navigateTo(context, Routes.privacyPolicy),
                      ),
                      // Logout
                      _buildMenuTile(
                        context,
                        icon: Icons.logout,
                        title: 'profile_logout'.tr(),
                        titleColor: Colors.redAccent,
                        iconColor: Colors.redAccent,
                        showTrailing: false,
                        onTap: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            AppRouter.navigateAndRemoveUntil(
                              context,
                              Routes.login,
                            );
                          }
                        },
                      ),
                    ]),
                    SizedBox(height: 110.h),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                child: Text(
                  'profile_theme'.tr(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildThemeOption(
                context,
                'theme_light',
                ThemeMode.light,
                Icons.light_mode_outlined,
              ),
              _buildThemeOption(
                context,
                'theme_dark',
                ThemeMode.dark,
                Icons.dark_mode_outlined,
              ),
              _buildThemeOption(
                context,
                'theme_system',
                ThemeMode.system,
                Icons.brightness_auto_outlined,
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String key,
    ThemeMode mode,
    IconData icon,
  ) {
    bool isSelected = ThemeManager().themeModeNotifier.value == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: () {
        ThemeManager().setThemeMode(mode);
        Navigator.pop(context);
      },
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white : Colors.grey[600]),
          size: 22.sp,
        ),
      ),
      title: Text(
        key.tr(),
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.primary
              : isDark
              ? Colors.white
              : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp)
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'code': 'en', 'name': 'profile_english', 'flag': '🇺🇸'},
      {'code': 'ar', 'name': 'profile_arabic', 'flag': '🇸🇦'},
      {
        'code': 'tr',
        'name': 'language_turkish',
        'flag': '🇹🇷',
        'isComingSoon': true,
      },
      {
        'code': 'de',
        'name': 'language_german',
        'flag': '🇩🇪',
        'isComingSoon': true,
      },
      {
        'code': 'it',
        'name': 'language_italian',
        'flag': '🇮🇹',
        'isComingSoon': true,
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      backgroundColor: Colors.transparent, // For custom container decoration
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              // Drag Indicator
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                child: Text(
                  'profile_language'.tr(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 8.h,
                  ),
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected =
                        context.locale.languageCode == lang['code'];
                    final isComingSoon = lang['isComingSoon'] == true;

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      leading: Container(
                        width: 48.r,
                        height: 48.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          lang['flag'] as String,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
                      title: Text(
                        (lang['name'] as String).tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isComingSoon
                              ? isDark
                                    ? Colors.white
                                    : Colors.grey
                              : (isSelected
                                    ? AppColors.primary
                                    : isDark
                                    ? Colors.white
                                    : AppColors.textPrimary),
                        ),
                      ),
                      trailing: isComingSoon
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'coming_soon'.tr(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : (isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 24.sp,
                                  )
                                : null),
                      onTap: () async {
                        if (isComingSoon) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${(lang['name'] as String).tr()} ${'coming_soon'.tr()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.black87,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16.r),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                        } else {
                          await context.setLocale(
                            Locale(lang['code'] as String),
                          );
                          if (context.mounted) {
                            AppRouter.navigateAndRemoveUntil(
                              context,
                              Routes.splash,
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white.withOpacity(0.95), // Slight transparency
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 2,
        ), // White border highlight
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05), // Subtle primary tint
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int index = entry.key;
          Widget child = entry.value;
          // Add dividers between items, but not after the last one
          if (index != children.length - 1) {
            return Column(
              children: [
                child,
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 60.w, // Indent to align with text
                  endIndent: 24.w,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ],
            );
          }
          return child;
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(10.w), // Slightly larger padding
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp, // Slightly larger font
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white : Colors.grey,
                ),
              ),
            )
          : null,
      trailing: showTrailing
          ? Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                context.locale.languageCode == 'ar'
                    ? Icons.keyboard_arrow_left_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: isDark ? Colors.white : Colors.grey[400],
                size: 18.sp,
              ),
            )
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      hoverColor: Colors.transparent,
    );
  }
}
