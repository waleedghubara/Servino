// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/services/data/models/review_model.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/home/logic/home_provider.dart';
import 'package:provider/provider.dart';

import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/location_utils.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/services/data/models/service_provider_model.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/rating_bottom_sheet.dart';
import '../chat/data/repo/chat_repository.dart';
import 'dart:async';
import 'package:servino_client/injection_container.dart' as di;

class ProviderDetailsPage extends StatefulWidget {
  final ServiceProviderModel provider;

  const ProviderDetailsPage({super.key, required this.provider});

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = false;
  bool _isLoadingProvider = false;
  late ServiceProviderModel _currentProvider;
  late bool isFavorite;
  bool _isProviderOnline = false;
  Timer? _statusTimer;
  late final ChatRepository _chatRepository;

  @override
  void initState() {
    super.initState();
    _chatRepository = di.sl<ChatRepository>();
    _currentProvider = widget.provider;
    isFavorite = _currentProvider.isFavorited;
    _isProviderOnline = _currentProvider.isOnline;
    _loadReviews();
    _incrementViews();
    _checkAndFetchFullProvider();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchProviderStatus();
    });
  }

  Future<void> _fetchProviderStatus() async {
    if (!mounted) return;
    try {
      final statusData = await _chatRepository.getUserStatus(
        _currentProvider.id,
        role: 'provider',
      );
      if (mounted && statusData != null) {
        final online = statusData['is_online'] == true;
        if (online != _isProviderOnline) {
          setState(() {
            _isProviderOnline = online;
          });
        }
      }
    } catch (e) {
      debugPrint('ProviderDetailsPage: Error fetching status: $e');
    }
  }

  Future<void> _checkAndFetchFullProvider() async {
    // If about is empty or yearsOfExperience is 0, it's likely a partial model from favorites
    if (_currentProvider.about.isEmpty ||
        _currentProvider.yearsOfExperience == 0) {
      setState(() => _isLoadingProvider = true);
      final userId = context.read<AuthProvider>().user?.id.toString();
      final result = await context.read<HomeProvider>().getProviderById(
        _currentProvider.id,
        userId: userId,
      );
      result.fold(
        (error) => setState(() => _isLoadingProvider = false),
        (fullProvider) => setState(() {
          _currentProvider = fullProvider;
          isFavorite = _currentProvider.isFavorited;
          _isLoadingProvider = false;
        }),
      );
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final result = await context.read<HomeProvider>().getReviews(
      _currentProvider.id,
    );
    result.fold(
      (error) => setState(() => _isLoadingReviews = false),
      (reviews) => setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      }),
    );
  }

  void _incrementViews() {
    // print(
    //   'DEBUG: ProviderDetailsPage._incrementViews triggered for ${_currentProvider.id}',
    // );
    final userId =
        context.read<AuthProvider>().user?.id.toString() ??
        '1'; // Default to 1 (Guest) if not logged in
    context.read<HomeProvider>().incrementViews(
      providerId: _currentProvider.id,
      viewerId: userId,
    );
  }

  void _toggleFavorite() {
    final userId = context.read<AuthProvider>().user?.id.toString();
    if (userId == null) {
      ToastUtils.showError(
        context: context,
        message: 'Please login to favorite',
      );
      return;
    }

    setState(() {
      isFavorite = !isFavorite;
    });

    context.read<HomeProvider>().toggleFavorite(
      userId: userId,
      providerId: _currentProvider.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Transparent for background
      body: _isLoadingProvider
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 0. Background Animation
                const Positioned.fill(child: AnimatedBackground()),

                // 1. Main Content
                CustomScrollView(
                  slivers: [
                    // Sliver App Bar with Image
                    SliverAppBar(
                      expandedHeight: 350.h, // Increased height for better view
                      pinned: true,
                      backgroundColor: Colors
                          .transparent, // Let background show initially or handle scroll
                      elevation: 0,
                      actions: [
                        SizedBox(width: 5.w),
                        GestureDetector(
                          onTap: () => _toggleFavorite(),
                          child: Container(
                            height: 35.h,
                            width: 35.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                height: 20.h,
                                width: 20.w,
                                isFavorite
                                    ? Assets.favoriteAt
                                    : Assets.favorite,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                      ],
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: GestureDetector(
                          onTap: () => _showFullScreenImage(
                            context,
                            _currentProvider.imageUrl,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'provider_${_currentProvider.id}_image',
                                child: CachedNetworkImage(
                                  imageUrl: _currentProvider.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 80.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              // Gradient Overlay for text readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                      Colors.black.withOpacity(0.9),
                                    ],
                                    stops: const [0.5, 0.8, 1.0],
                                  ),
                                ),
                              ),
                              // Basic Info Overlay
                              Positioned(
                                bottom: 20.h,
                                left: 20.w,
                                right: 20.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _currentProvider.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 26.sp,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 3.0,
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_currentProvider.isVerified)
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.w),
                                            child: Icon(
                                              Icons.verified,
                                              color: Colors.blueAccent,
                                              size: 28.sp,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _currentProvider.subCategory.tr(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    // Online Status
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10.w,
                                            height: 10.w,
                                            decoration: BoxDecoration(
                                              color: _isProviderOnline
                                                  ? AppColors.success
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                if (_isProviderOnline)
                                                  BoxShadow(
                                                    color: AppColors.success
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            _isProviderOnline
                                                ? 'chat_online'.tr()
                                                : 'chat_offline'.tr(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content Body
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 24.w, 20.w, 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Row
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 20.h,
                                horizontal: 16.w,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.white.withOpacity(0.9),

                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    context,
                                    value: _currentProvider.rating
                                        .toStringAsFixed(1),
                                    label: 'service_rating'.tr(),
                                    icon: Assets.star,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40.h,
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                  ),
                                  _buildStatItem(
                                    context,
                                    value:
                                        '${_currentProvider.yearsOfExperience}',
                                    label: 'service_experience_years'.tr(),
                                    icon: Assets.work,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40.h,
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                  ),
                                  _buildStatItem(
                                    context,
                                    value: '${_currentProvider.reviewCount}',
                                    label: 'service_reviews'.tr(),
                                    icon: Assets.people,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // About Section - Using a Glass Card for better readability
                            _buildSectionTitle(context, 'service_about'),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                _currentProvider.about.tr(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[800],
                                  fontSize: 15.sp,
                                  height: 1.6,
                                ),
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Details Grid
                            _buildSectionTitle(context, 'service_info'),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    context,
                                    icon: Assets.location,
                                    label: 'service_location',
                                    value: LocationUtils.formatLocation(
                                      _currentProvider.location,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                    ),
                                  ),
                                  _buildInfoRow(
                                    context,
                                    icon: Assets.monetization,
                                    label: 'service_price_start',
                                    value:
                                        '${_currentProvider.priceStart.toStringAsFixed(2)} ${_currentProvider.currency}',
                                    valueColor: AppColors.primary,
                                    isBold: true,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                    ),
                                  ),
                                  _buildInfoRow(
                                    context,
                                    icon: Assets.access,
                                    label: 'booking_status',
                                    value: _currentProvider.isAvailable
                                        ? 'provider_available'.tr()
                                        : 'provider_busy'.tr(),
                                    valueColor: _currentProvider.isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reviews Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10.w, 0, 20.w, 120.w),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(context, 'reviews_title'),
                                TextButton(
                                  onPressed: () => _showAddReviewSheet(context),
                                  child: Text(
                                    'write_review'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _isLoadingReviews
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _reviews.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        SvgPicture.asset(
                                          Assets.star,
                                          height: 150.h,
                                          width: 150.w,
                                        ),
                                        Text(
                                          'no_reviews_yet'.tr(),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _reviews.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(height: 16.h),
                                    itemBuilder: (context, index) {
                                      final review = _reviews[index];
                                      return _buildReviewItem(review);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. Floating Bottom Action Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 24.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Contact Button (Chat)
                        InkWell(
                          onTap: () {
                            _showChatTypeSelection(context);
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.all(9.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: SvgPicture.asset(
                              Assets.chat2,
                              height: 30.h,
                              width: 30.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Book Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              AppRouter.navigateTo(
                                context,
                                Routes.booking,
                                arguments: _currentProvider,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              'service_book_appointment'.tr(),
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildReviewItem(ReviewModel review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white.withOpacity(0.9),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: CachedNetworkImageProvider(review.userImage),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 14.sp,
                          direction: Axis.horizontal,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          DateFormat.yMMMd().format(review.date),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingBottomSheet(
        onSubmit: (rating, comment) async {
          final userId = context.read<AuthProvider>().user?.id.toString();
          if (userId == null) {
            ToastUtils.showError(
              context: context,
              message: 'Please login to review',
            );
            return false;
          }

          final success = await context.read<HomeProvider>().addReview(
            userId: userId,
            providerId: _currentProvider.id,
            rating: rating,
            comment: comment,
          );

          if (mounted) {
            if (success) {
              _loadReviews();
              ToastUtils.showSuccess(
                context: context,
                message: 'review_submitted'.tr(),
              );
              Navigator.pop(context);
            } else {
              ToastUtils.showError(
                context: context,
                message: 'review_submitted_failed'.tr(),
              );
            }
          }
          return success;
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Full screen
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Allow tapping background to dismiss
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Hero(
                tag: 'provider_${_currentProvider.id}_image',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 20.w,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required String icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SvgPicture.asset(icon, height: 28.h, width: 28.w),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        titleKey.tr(),
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(icon, height: 22.sp, width: 22.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white : Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : valueColor ?? Colors.black87,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChatTypeSelection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Option 1: Consultation (Paid)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // Navigate to Payment Flow
                AppRouter.navigateTo(
                  context,
                  Routes.paymentRequired,
                  arguments: _currentProvider,
                );
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16.r),
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.premium,

                      height: 40.sp,
                      width: 40.sp,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'consultation_option'.tr(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'consultation_desc'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
