// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';
import 'package:servino_client/core/services/data/models/service_provider_model.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/features/payment/models/payment_params.dart';
import 'package:servino_client/core/widgets/animated_background.dart';

class PaymentRequiredPage extends StatelessWidget {
  final ServiceProviderModel provider;

  const PaymentRequiredPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // 0. Animated Background
          const Positioned.fill(child: AnimatedBackground()),

          // 1. Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: isDark ? Colors.white : Colors.grey,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'payment_required_title'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w), // Balance back button
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        // Provider Hero Image
                        Hero(
                          tag: 'provider_${provider.id}_image',
                          child: Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                  provider.imageUrl,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        Text(
                          provider.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          provider.subCategory.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Fee Card
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'payment_fee_label'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                '${provider.priceStart.toStringAsFixed(2)} ${provider.currency}',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                'payment_required_desc'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        final params = PaymentParams(
                          title: provider.name,
                          amount: provider.priceStart > 0
                              ? provider.priceStart
                              : 50.0,
                          currency: provider.currency,
                          description: 'consultation_fee'.tr(),
                          providerId: provider.id.toString(),
                          providerPhone:
                              '', // description field doesn't exist, passing empty
                          providerImage: provider.imageUrl,
                        );
                        AppRouter.navigateTo(
                          context,
                          Routes.paymentMethodSelection,
                          arguments: params,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'pay_now'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
