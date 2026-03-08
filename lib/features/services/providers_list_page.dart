// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../../core/services/data/models/category_model.dart';
import '../../core/widgets/provider_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import '../home/logic/home_provider.dart';
import '../auth/logic/auth_provider.dart';
import '../../core/ads/widgets/banner_ad_widget.dart';
import '../../core/ads/ads_manager.dart';

class ProvidersListPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ProvidersListPage({super.key, required this.arguments});

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  late String categoryId;
  late String categoryName;
  List<CategoryService> _services = [];
  CategoryService? _selectedService; // null means 'All'

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _searchQuery = '';
  Timer? _pollingTimer;

  // Filter States
  double _minRating = 0.0;
  RangeValues _ageRange = const RangeValues(14, 99);

  @override
  void initState() {
    super.initState();
    categoryId = widget.arguments['categoryId'] ?? '';
    categoryName = widget.arguments['categoryName'] ?? 'service_providers';
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProviders();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Optimized: Only fetch status updates, not full provider details
        context.read<HomeProvider>().updateProviderStatuses(
          categoryId: categoryId,
          serviceId: _selectedService?.id.toString(),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCategoryServices();
  }

  void _loadCategoryServices() {
    try {
      final homeProvider = context.read<HomeProvider>();
      final category = homeProvider.categories.firstWhere(
        (c) => c.id.toString() == categoryId.toString(),
        orElse: () => CategoryModel(
          id: 0,
          nameEn: 'Unknown',
          nameAr: 'Unknown',
          image: '',
          services: [],
        ),
      );

      if (category.id != 0) {
        _services = category.services;
      }
    } catch (e) {
      ToastUtils.showError(context: context, message: 'Error: $e');
    }
  }

  void _fetchProviders() {
    final userId = context.read<AuthProvider>().user?.id;
    context.read<HomeProvider>().getProviders(
      categoryId: categoryId,
      serviceId: _selectedService?.id.toString(),
      userId: userId?.toString(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onServiceSelected(CategoryService? service) {
    setState(() {
      _selectedService = service;
    });
    _fetchProviders();
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _ = context.locale.languageCode == 'ar';

    // Temporary state variables for the bottom sheet
    double tempMinRating = _minRating;
    RangeValues tempAgeRange = _ageRange;
    bool isFetchingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'filters'.tr(),
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempMinRating = 0.0;
                              tempAgeRange = const RangeValues(15, 99);
                              _locationController.clear();
                            });
                          },
                          child: Text(
                            'reset'.tr(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Location Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'location'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isFetchingLocation)
                          Text(
                            'fetching_location'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'search_location_hint'.tr(),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: isFetchingLocation
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.primary,
                                ),
                          tooltip: 'use_my_location'.tr(),
                          onPressed: isFetchingLocation
                              ? null
                              : () async {
                                  setModalState(() {
                                    isFetchingLocation = true;
                                  });
                                  try {
                                    bool serviceEnabled =
                                        await Geolocator.isLocationServiceEnabled();
                                    if (!serviceEnabled) {
                                      throw Exception('Disabled');
                                    }

                                    LocationPermission permission =
                                        await Geolocator.checkPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      permission =
                                          await Geolocator.requestPermission();
                                      if (permission ==
                                          LocationPermission.denied) {
                                        throw Exception('Denied');
                                      }
                                    }

                                    if (permission ==
                                        LocationPermission.deniedForever) {
                                      throw Exception('Denied forever');
                                    }

                                    Position position =
                                        await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.medium,
                                        );

                                    final dio = Dio();
                                    dio.options.headers['User-Agent'] =
                                        'ServinoApp/1.0';
                                    final lang = context.locale.languageCode;
                                    final res = await dio.get(
                                      'https://nominatim.openstreetmap.org/reverse',
                                      queryParameters: {
                                        'format': 'json',
                                        'lat': position.latitude,
                                        'lon': position.longitude,
                                        'accept-language': lang,
                                      },
                                    );

                                    if (res.statusCode == 200 &&
                                        res.data != null) {
                                      final address = res.data['address'];
                                      if (address != null) {
                                        String loc =
                                            address['city'] ??
                                            address['town'] ??
                                            address['village'] ??
                                            address['county'] ??
                                            address['state'] ??
                                            '';
                                        if (loc.isNotEmpty) {
                                          setModalState(() {
                                            _locationController.text = loc;
                                          });
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      String errorMsg = 'location_error'.tr();
                                      if (e is LocationServiceDisabledException ||
                                          e.toString().contains('Disabled')) {
                                        errorMsg = 'location_services_disabled'
                                            .tr();
                                        // Proactively open settings for the user
                                        Geolocator.openLocationSettings();
                                      } else if (e is PermissionDeniedException ||
                                          e.toString().contains('Denied')) {
                                        errorMsg = 'location_permission_denied'
                                            .tr();
                                      }

                                      ToastUtils.showError(
                                        context: context,
                                        message: errorMsg,
                                      );
                                      print(
                                        '!!! Location Fetch Detailed Error: $e',
                                      );
                                    }
                                  } finally {
                                    setModalState(() {
                                      isFetchingLocation = false;
                                    });
                                  }
                                },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 16.w,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Rating Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'minimum_rating'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              tempMinRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Slider(
                      value: tempMinRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (value) {
                        setModalState(() {
                          tempMinRating = value;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Age Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'age_range'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${tempAgeRange.start.round()} - ${tempAgeRange.end.round()}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: tempAgeRange,
                      min: 15,
                      max: 99,
                      divisions: 84,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey.shade300,
                      labels: RangeLabels(
                        tempAgeRange.start.round().toString(),
                        tempAgeRange.end.round().toString(),
                      ),
                      onChanged: (values) {
                        setModalState(() {
                          tempAgeRange = values;
                        });
                      },
                    ),
                    SizedBox(height: 32.h),

                    // Apply Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _minRating = tempMinRating;
                          _ageRange = tempAgeRange;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'apply_filters'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';

    bool isFilterActive =
        _minRating > 0 ||
        _ageRange.start > 15 ||
        _ageRange.end < 99 ||
        _locationController.text.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          categoryName, // Passed localized
          style: TextStyle(
            fontSize: 19.sp,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                // Search & Filter Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  '${'service_search_hint'.tr()} $categoryName...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 24.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Filter Button
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          height: 50.h,
                          width: 50.w,
                          decoration: BoxDecoration(
                            color: isFilterActive
                                ? AppColors.primary
                                : (isDark ? Colors.black : Colors.white),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isFilterActive
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: isFilterActive
                                ? Colors.white
                                : (isDark ? Colors.white : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                // Always show 'All' + Services. If services empty, just 'All'.
                Container(
                  height: 50.h,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    // +1 for "All" option
                    itemCount: _services.length + 1,
                    separatorBuilder: (_, _) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      CategoryService? service;
                      String label;
                      bool isSelected;

                      if (index == 0) {
                        // "All" Option
                        service = null;
                        label = 'service_all'.tr();
                        isSelected = _selectedService == null;
                      } else {
                        // Specific Service
                        service = _services[index - 1];
                        label = isAr ? service.nameAr : service.nameEn;
                        isSelected = _selectedService == service;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ChoiceChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _onServiceSelected(service);
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: isDark
                              ? AppColors.backgroundDark
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          elevation: isSelected ? 2 : 0,
                          shadowColor: Colors.black.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Provider List
                Expanded(
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingProviders) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.providerErrorMessage != null) {
                        return Center(
                          child: Text(
                            provider.providerErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final filteredList = provider.providers.where((p) {
                        // Name search
                        bool matchesName =
                            _searchQuery.isEmpty ||
                            p.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );

                        // Rating Filter
                        bool matchesRating = p.rating >= _minRating;

                        // Age Filter
                        // If age isn't supported/0 we ignore the filter or include them. We include them if age is 0 (default/unknown)
                        bool matchesAge = true;
                        if (p.age > 0) {
                          matchesAge =
                              p.age >= _ageRange.start &&
                              p.age <= _ageRange.end;
                        }

                        // Location Filter
                        bool matchesLocation = true;
                        if (_locationController.text.isNotEmpty) {
                          matchesLocation = p.location.toLowerCase().contains(
                            _locationController.text.toLowerCase(),
                          );
                        }

                        return matchesName &&
                            matchesRating &&
                            matchesAge &&
                            matchesLocation;
                      }).toList();

                      if (filteredList.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24.w),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    Assets.search2,
                                    height: 100.h,
                                    width: 100.w,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  'service_no_providers'.tr(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final providerItem = filteredList[index];
                          return ProviderCard(
                            provider: providerItem,
                            onTap: () {
                              AdsManager.instance.showRewardedAd(
                                onAdFinished: () {
                                  AppRouter.navigateTo(
                                    context,
                                    Routes.providerDetails,
                                    arguments: providerItem,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // Banner Ad at the bottom
                const BannerAdWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
