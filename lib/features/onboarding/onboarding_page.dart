import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import 'package:servino_client/core/cache/cache_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'onboarding1_title',
      'description': 'onboarding1_description',
      'image': Assets.onboarding1,
    },
    {
      'title': 'onboarding2_title',
      'description': 'onboarding2_description',
      'image': Assets.onboarding2,
    },
    {
      'title': 'onboarding3_title',
      'description': 'onboarding3_description',
      'image': Assets.onboarding3,
    },
  ];

  void _showLanguagePicker() {
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
                  color: Colors.grey[300],
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
                    color: AppColors.textPrimary,
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
                    color: Colors.grey.withOpacity(0.2),
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
                          color: Colors.grey.withOpacity(0.05),
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
                              ? Colors.grey
                              : (isSelected
                                    ? AppColors.primary
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.onboardingBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // Top Bar (Language & Skip)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language Switcher Button
                    TextButton.icon(
                      onPressed: _showLanguagePicker,
                      icon: Icon(
                        Icons.language,
                        size: 20.sp,
                        color: Colors.grey,
                      ),
                      label: Text(
                        context.locale.languageCode == 'ar'
                            ? 'profile_arabic'.tr()
                            : 'profile_english'.tr(),
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    ),

                    // Skip Button
                    TextButton(
                      onPressed: () {
                        SecureCacheHelper().saveData(
                          key: 'onboarding_seen',
                          value: 'true',
                        );
                        AppRouter.navigateAndRemoveUntil(context, Routes.login);
                      },
                      child: Text(
                        'skip'.tr(),
                        style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingItem(_onboardingData[index]);
                  },
                ),
              ),

              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentPage == index ? 24.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        SecureCacheHelper().saveData(
                          key: 'onboarding_seen',
                          value: 'true',
                        );
                        AppRouter.navigateAndRemoveUntil(context, Routes.login);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? 'getStarted'.tr()
                          : 'next'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildOnboardingItem(Map<String, String> data) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(data['image']!),
          SizedBox(height: 48.h),
          Text(
            data['title']!.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            data['description']!.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
