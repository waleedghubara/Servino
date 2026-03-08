// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/core/widgets/category_item.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/assets.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/features/home/logic/home_provider.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
// import 'package:servino_client/core/services/data/models/category_model.dart'; // It was unused because I commented out the local variable, but I might need it if I use the type explicitly. The lint said it was unused, so I'll trust the lint.
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().getBanners();
      context.read<HomeProvider>().getCategories();
    });
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final provider = context.read<HomeProvider>();
      if (provider.banners.isEmpty) return;

      if (_bannerController.hasClients) {
        if (_currentBannerIndex < provider.banners.length - 1) {
          _currentBannerIndex++;
        } else {
          _currentBannerIndex = 0;
        }
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Removed local declaration: final categories = CategoryModel.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                backgroundColor: isDark
                    ? AppColors.backgroundDark
                    : Colors.white,
                elevation: 0,

                flexibleSpace: FlexibleSpaceBar(
                  background: Center(
                    child: Container(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 2),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? LinearGradient(
                                colors: [
                                  AppColors.surfaceDark,
                                  AppColors.backgroundDark,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isDark ? null : Colors.white,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final user = authProvider.user;
                              return FadeInLeft(
                                duration: const Duration(milliseconds: 800),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 22.r,
                                        backgroundColor: AppColors.background,
                                        backgroundImage:
                                            user?.fullImage != null &&
                                                user!.fullImage!.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                user.fullImage!,
                                              )
                                            : AssetImage(Assets.logoApp)
                                                  as ImageProvider,
                                        onBackgroundImageError:
                                            user?.fullImage != null &&
                                                user!.fullImage!.isNotEmpty
                                            ? (_, _) {}
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'home_welcome'.tr(),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          user?.name ?? 'Servino',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          FadeInRight(
                            duration: const Duration(milliseconds: 800),
                            child: GestureDetector(
                              onTap: () => AppRouter.navigateTo(
                                context,
                                Routes.notifications,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  Assets.notifications,

                                  width: 26.sp,
                                  height: 26.sp,
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

              // Search Bar
              SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AppRouter.navigateTo(context, Routes.search);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16.r),
                          bottomRight: Radius.circular(16.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.grey.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'home_search_hint'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Banner Section
              SliverToBoxAdapter(
                child: Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingBanners) {
                      return Shimmer.fromColors(
                        baseColor: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        highlightColor: isDark
                            ? Colors.grey[700]!
                            : Colors.grey[100]!,
                        child: Container(
                          height: 120.h,
                          margin: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      );
                    }

                    if (provider.banners.isEmpty) {
                      return const SizedBox();
                    }

                    return FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 120.h,
                            child: PageView.builder(
                              controller: _bannerController,
                              itemCount: provider.banners.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentBannerIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final banner =
                                    provider.banners[index]; // Use BannerModel
                                ImageProvider imageProvider;
                                if (banner.image.startsWith('http')) {
                                  imageProvider = CachedNetworkImageProvider(
                                    banner.image,
                                  );
                                } else if (banner.image.startsWith('assets/')) {
                                  imageProvider = AssetImage(banner.image);
                                } else {
                                  imageProvider = CachedNetworkImageProvider(
                                    '${EndPoint.imageBaseUrl}${banner.image}',
                                  );
                                }

                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.15,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Indicators
                          if (provider.banners.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                provider.banners.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentBannerIndex == index
                                      ? 24.w
                                      : 8.w,
                                  height: 6.h,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.r),
                                    color: _currentBannerIndex == index
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.grey[700]
                                              : Colors.grey[300]),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Categories Grid
              SliverPadding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Consumer<HomeProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return Shimmer.fromColors(
                              baseColor: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                            );
                          }

                          if (provider.categories.isEmpty) {
                            if (provider.errorMessage != null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      provider.errorMessage!,
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    TextButton(
                                      onPressed: () => provider.getCategories(),
                                      child: Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Center(child: Text("No categories found"));
                          }

                          if (index >= provider.categories.length) {
                            return const SizedBox();
                          }

                          final category = provider.categories[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 200),
                            child: CategoryItem(
                              category: category,
                              onTap: () => AppRouter.navigateTo(
                                context,
                                Routes.providersList,
                                arguments: {
                                  'categoryId': category.id.toString(),
                                  'categoryName':
                                      context.locale.languageCode == 'ar'
                                      ? category.nameAr
                                      : category.nameEn,
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: context.watch<HomeProvider>().categories.isEmpty
                        ? (context.watch<HomeProvider>().isLoading ? 6 : 0)
                        : context.watch<HomeProvider>().categories.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          ),
        ],
      ),
    );
  }
}
