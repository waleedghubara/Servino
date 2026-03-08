// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import '../../core/widgets/provider_card.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';

import 'package:provider/provider.dart';
import '../home/logic/home_provider.dart';
import '../auth/logic/auth_provider.dart';
import '../../core/utils/toast_utils.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavorites();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchFavorites() {
    final userId = context.read<AuthProvider>().user?.id.toString();
    if (userId != null) {
      context.read<HomeProvider>().getFavorites(userId).then((_) {
        if (mounted) {
          final error = context.read<HomeProvider>().favoriteErrorMessage;
          if (error != null) {
            ToastUtils.showError(context: context, message: error);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'favorites_title'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: AppColors.primary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                if (homeProvider.isLoadingFavorites) {
                  return const Center(child: CircularProgressIndicator());
                }

                final favoriteProviders = homeProvider.favoriteProviders;

                // Filter logic
                final filteredProviders = favoriteProviders.where((provider) {
                  final name = provider.name.toLowerCase();
                  final category = provider.subCategory
                      .toLowerCase(); // Or category name
                  return name.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                return Column(
                  children: [
                    SizedBox(height: 30),

                    // Search Bar
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
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
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'home_search_hint'
                                .tr(), // "Search for services..."
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey : Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                      size: 20.sp,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: filteredProviders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.favoriteAt,
                                    width: 60.w,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.red,
                                      BlendMode.srcIn,
                                    ),
                                    height: 60.h,
                                  ),
                                  SizedBox(height: 24.h),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'favorites_no_favorites'.tr()
                                        : 'favorites_no_results'.tr(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                10.h,
                                20.w,
                                20.h,
                              ), // Adjusted padding
                              itemCount: filteredProviders.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(height: 16.h),
                              itemBuilder: (context, index) {
                                return ProviderCard(
                                  provider: filteredProviders[index],
                                  onTap: () => AppRouter.navigateTo(
                                    context,
                                    Routes.providerDetails,
                                    arguments: filteredProviders[index],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
