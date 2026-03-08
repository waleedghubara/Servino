// ignore_for_file: deprecated_member_use
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/services/data/models/category_model.dart';
import '../../core/services/data/models/service_provider_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/category_item.dart';
import '../../features/home/logic/home_provider.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryModel> _filteredCategories = [];
  List<ServiceProviderModel> _filteredProviders = [];
  bool _isSearching = false;
  int _selectedFilterIndex = 0; // 0: All, 1: Categories, 2: Providers

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _filteredCategories = [];
        _filteredProviders = [];
      } else {
        _isSearching = true;

        // Smart filtering logic
        final homeProvider = context.read<HomeProvider>();
        final allCategories = homeProvider.categories;
        _filteredCategories = allCategories
            .where(
              (cat) =>
                  cat.nameEn.toLowerCase().contains(query) ||
                  cat.nameAr.toLowerCase().contains(query),
            )
            .take(15) // Limit for performance
            .toList();

        _filteredProviders = homeProvider.providers
            .where(
              (provider) =>
                  provider.name.toLowerCase().contains(query) ||
                  provider.subCategory.tr().toLowerCase().contains(query),
            )
            .take(20)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 8.h),
                _buildPremiumHeader(),
                SizedBox(height: 16.h),
                if (_isSearching) _buildPremiumFilterTabs(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildBackButton(),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.h4.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),

                cursorColor: AppColors.primary,
                keyboardAppearance: Brightness.light,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'search_hint'.tr(),
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),

                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),

                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white : Colors.grey,
                              size: 20.sp,
                            ),
                          ),
                        )
                      : null,

                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,

                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 4.w,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 45.w,
      height: 45.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.textPrimary,
          size: 20.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPremiumFilterTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = [
      'service_all'.tr(),
      'search_categories'.tr(),
      'search_providers'.tr(),
    ];

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        height: 40.h,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            final isSelected = _selectedFilterIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 0),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : isDark
                      ? AppColors.backgroundDark
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isDark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isSearching) {
      return _buildEmptyState(icon: Assets.search, title: 'search_hint'.tr());
    }

    if (_filteredCategories.isEmpty && _filteredProviders.isEmpty) {
      return _buildEmptyState(icon: Assets.search, title: 'search_hint'.tr());
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30.r),
        topRight: Radius.circular(30.r),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
        physics: const BouncingScrollPhysics(),
        children: [
          // Categories
          if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 1) &&
              _filteredCategories.isNotEmpty) ...[
            _buildSectionHeader(
              'search_categories'.tr(),
              _filteredCategories.length,
            ),
            SizedBox(height: 16.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15.w,
                mainAxisSpacing: 15.h,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 30),
                  child: CategoryItem(
                    category: _filteredCategories[index],
                    onTap: () {
                      AppRouter.navigateTo(
                        context,
                        Routes.providersList,
                        arguments: {
                          'categoryId': _filteredCategories[index].id
                              .toString(),
                          'categoryName': context.locale.languageCode == 'ar'
                              ? _filteredCategories[index].nameAr
                              : _filteredCategories[index].nameEn,
                        },
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 30.h),
          ],

          // Providers
          if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 2) &&
              _filteredProviders.isNotEmpty) ...[
            _buildSectionHeader(
              'search_providers'.tr(),
              _filteredProviders.length,
            ),
            SizedBox(height: 16.h),
            ..._filteredProviders.asMap().entries.map((entry) {
              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: entry.key * 50),
                child: _buildPremiumProviderCard(entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String icon, required String title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, width: 70.w, height: 70.h),
            SizedBox(height: 20.h),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTypography.h3.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            "$count",
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumProviderCard(ServiceProviderModel provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            AppRouter.navigateTo(
              context,
              Routes.providerDetails,
              arguments: provider,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Online Status
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        child: CachedNetworkImage(
                          imageUrl: provider.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            color: Colors.grey.shade400,
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4.w,
                      top: 4.h,
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: provider.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16.w),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              provider.name,
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 16.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${provider.priceStart.toInt()} ${provider.currency}",
                            style: AppTypography.h4.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        provider.subCategory.tr(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "${provider.rating}",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            " (${provider.reviewCount})",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              provider.location.tr(),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 11.sp,
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
      ),
    );
  }
}
