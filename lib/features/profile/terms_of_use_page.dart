import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

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
          'profile_terms'.tr(),
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
                    'terms_intro_title'.tr(),
                    'terms_intro_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_accounts_title'.tr(),
                    'terms_accounts_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_services_title'.tr(),
                    'terms_services_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_conduct_title'.tr(),
                    'terms_conduct_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_payments_title'.tr(),
                    'terms_payments_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_ip_title'.tr(),
                    'terms_ip_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_liability_title'.tr(),
                    'terms_liability_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_changes_title'.tr(),
                    'terms_changes_content'.tr(),
                  ),
                  _buildSection(
                    context,
                    'terms_contact_title'.tr(),
                    'terms_contact_content'.tr(),
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
