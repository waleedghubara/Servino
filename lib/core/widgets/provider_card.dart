// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/home/logic/home_provider.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/location_utils.dart';
import '../services/data/models/service_provider_model.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({super.key, required this.provider, required this.onTap});

  void _toggleFavorite(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id.toString();
    if (userId == null) {
      ToastUtils.showInfo(
        context: context,
        message: 'Please login to favorite',
      );
      return;
    }

    context.read<HomeProvider>().toggleFavorite(
      userId: userId,
      providerId: provider.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = provider.isFavorited;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Image with Status
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 70.w,
                      height: 70.h,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                      child: CachedNetworkImage(
                        imageUrl: provider.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Icon(
                            Icons.person,
                            color: Colors.grey.shade400,
                            size: 32.sp,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4.w,
                    top: 4.h,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: provider.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 16.sp,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Favorite Toggle
                        GestureDetector(
                          onTap: () => _toggleFavorite(context),
                          child: SvgPicture.asset(
                            isFavorite ? Assets.favoriteAt : Assets.favorite,
                            height: 20.h,
                            width: 20.w,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      provider.subCategory.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          ' (${provider.reviewCount})',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey.shade400,
                          size: 14.sp,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            LocationUtils.formatLocation(provider.location),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
