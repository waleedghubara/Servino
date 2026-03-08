// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile_privacy'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(color: Colors.transparent),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    'privacy_intro_title'.tr(),
                    'privacy_intro_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_usage_title'.tr(),
                    'privacy_usage_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_sharing_title'.tr(),
                    'privacy_sharing_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_security_title'.tr(),
                    'privacy_security_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_rights_title'.tr(),
                    'privacy_rights_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_children_title'.tr(),
                    'privacy_children_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_changes_title'.tr(),
                    'privacy_changes_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'privacy_contact_title'.tr(),
                    'privacy_contact_content'.tr(),
                  ),
                  SizedBox(height: 40.h),
                  Center(
                    child: Text(
                      'last_updated'.tr(),
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
