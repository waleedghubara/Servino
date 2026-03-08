// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:provider/provider.dart';
import 'package:servino_client/core/services/data/models/category_model.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/booking/logic/booking_provider.dart';
import 'package:servino_client/core/widgets/rating_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  Timer? _timer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshStatus();
    });
  }

  Future<void> _refreshStatus() async {
    if (_isUpdating) return;
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<BookingProvider>().silentlyRefreshBookings(
        user.id.toString(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for updates
    final bookingList = context.watch<BookingProvider>().bookings;

    // Find our specific booking in the list to get live updates
    final Map<String, dynamic> booking = bookingList.firstWhere(
      (b) => b['id'].toString() == widget.booking['id'].toString(),
      orElse: () => widget.booking,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusRaw =
        (booking['status'] as String?)?.toLowerCase() ?? 'pending';

    // Normalize status for UI logic
    String currentStatus = statusRaw;
    if (statusRaw == 'on the way' ||
        statusRaw == 'في الطريق' ||
        statusRaw == 'on_way') {
      currentStatus = 'on_way';
    } else if (statusRaw == 'وصل' || statusRaw == 'arrived') {
      currentStatus = 'arrived';
    } else if (statusRaw == 'مؤكد' || statusRaw == 'confirmed') {
      currentStatus = 'confirmed';
    } else if (statusRaw == 'مكتمل' ||
        statusRaw == 'completed' ||
        statusRaw == 'finished') {
      currentStatus = 'completed';
    } else if (statusRaw == 'cancelled' ||
        statusRaw == 'rejected' ||
        statusRaw == 'mlghy') {
      currentStatus = 'cancelled';
    } else if (statusRaw == 'completionrequested' ||
        statusRaw == 'completion_requested' ||
        statusRaw == 'طلب إنهاء الاستشارة') {
      currentStatus = 'completionrequested';
    }

    if (bookingList.isNotEmpty &&
        !bookingList.any(
          (b) => b['id'].toString() == widget.booking['id'].toString(),
        )) {
      debugPrint(
        'WARNING: Booking ${widget.booking['id']} not found in provider list!',
      );
    }

    final isCompleted = currentStatus == 'completed';
    final isCancelled = currentStatus == 'cancelled';
    final isCompletionRequested = currentStatus == 'completionrequested';

    // API returns 'type' but if missing default to 'service'
    final type = (booking['type'] ?? 'service').toString().toLowerCase();
    final isConsultation =
        type == 'consultation' || type == 'استشارة' || type == 'استشاره';

    // Logic to hide tracking if user travels to provider
    // Check local 'type' values from BookingPage.dart: 'Going to Him'
    final isUserGoingToProvider =
        type.contains('going to him') ||
        type.contains('clinic') ||
        type.contains('center') ||
        type.contains('workshop') ||
        type.contains('office') ||
        type.contains('visit') ||
        type.contains('arrival') ||
        type.contains('appointment') ||
        type.contains('عيادة') ||
        type.contains('مركز') ||
        type.contains('ورشة') ||
        type.contains('مكتب') ||
        type.contains('زيارة') ||
        type.contains('موعد') ||
        type.contains('حضور') ||
        type.contains('الذهاب اليه') || // Arabic translation of Going to Him
        type.contains('قدوم'); // User mentioned "Qudum"

    final shouldShowTimeline = !isConsultation && !isUserGoingToProvider;

    // Map API keys to local variables for safety
    final providerName =
        booking['provider_name'] ?? booking['name'] ?? 'Unknown Provider';

    // Localized Service Name
    final isAr = context.locale.languageCode == 'ar';
    final categoryName = isAr
        ? (booking['category_name_ar'] ??
              booking['category_name_en'] ??
              'Service')
        : (booking['category_name_en'] ?? 'Service');

    // Prefer specific service name if available, else category name
    final serviceName = isAr
        ? (booking['service_name_ar'] ??
              booking['service_name_en'] ??
              categoryName)
        : (booking['service_name_en'] ?? categoryName);

    final providerImage = booking['provider_image'] ?? booking['image'] ?? '';
    final dateStr = booking['date'] ?? '';
    final timeStr = booking['time'] ?? '';

    // Find category for image
    CategoryModel? category;
    if (booking['category_id'] != null) {
      category = CategoryModel.categories.firstWhere(
        (c) => c.id.toString() == booking['category_id'].toString(),
        orElse: () => CategoryModel.categories.first,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          // 1. Hero Header (Map + Overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300.h,
            child: Stack(
              children: [
                // Map Placeholder
                // Header Image (Map or Category)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image:
                          (booking['category_image'] != null &&
                              booking['category_image'].toString().isNotEmpty)
                          ? CachedNetworkImageProvider(
                              booking['category_image'],
                            )
                          : (category != null && category.image.isNotEmpty
                                    ? (category.image.startsWith('http')
                                          ? CachedNetworkImageProvider(
                                              category.image,
                                            )
                                          : AssetImage(category.image))
                                    : AssetImage(Assets.onboardingBackground))
                                as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.4), // Dark Overlay
                  ),
                ),

                // AppBar Elements
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        _buildGlassIconBtn(
                          context,
                          Icons.arrow_back_ios_new_rounded,
                          () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          'booking_details_title'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildGlassIconBtn(
                          context,
                          Icons.help_outline_rounded,
                          () {
                            AppRouter.navigateTo(
                              context,
                              Routes.helpCenter,
                              arguments: {
                                'additionalHiddenInfo':
                                    'Booking ID: ${booking['id']}\nService: $serviceName\nProvider: $providerName',
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content (Scrollable Sheet)
          Positioned.fill(
            top: 220.h,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            serviceName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '$dateStr • $timeStr',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    if (shouldShowTimeline) ...[
                      // Tracking Timeline
                      Text(
                        'track_booking'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildTimeline(context, currentStatus),
                      SizedBox(height: 32.h),
                    ] else if (isUserGoingToProvider) ...[
                      // Visit Info Card (Replacement for Timeline)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 24.h,
                          horizontal: 20.w,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                Assets.bookingchats,
                                height: 50.h,
                                width: 50.w,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'appointment_visit_provider'
                                  .tr(), // "Appointment to Visit Provider"
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '$dateStr  |  $timeStr',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'provider_location_visit'
                                    .tr(), // "Please arrive on time"
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],

                    if (isCompletionRequested) ...[
                      // Completion Request Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions_rounded,
                              color: Colors.orange,
                              size: 40.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'consultation_completion_request'.tr(),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'provider_requested_completion_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final bookingId = widget.booking['id']
                                          ?.toString();
                                      if (bookingId != null) {
                                        setState(() => _isUpdating = true);
                                        // No userId needed, handled by token in backend
                                        final success = await context
                                            .read<BookingProvider>()
                                            .rejectCompletion(bookingId);

                                        if (success && mounted) {
                                          // Ensure small delay for server to persist
                                          await Future.delayed(
                                            const Duration(milliseconds: 1000),
                                          );
                                          setState(() => _isUpdating = false);
                                          await _refreshStatus();
                                          if (mounted) {
                                            ToastUtils.showSuccess(
                                              context: context,
                                              message:
                                                  'booking_rejection_feedback'
                                                      .tr(),
                                            );
                                          }
                                        } else if (!success && mounted) {
                                          setState(() => _isUpdating = false);
                                          ToastUtils.showError(
                                            context: context,
                                            message:
                                                context
                                                    .read<BookingProvider>()
                                                    .error ??
                                                'Failed to reject completion',
                                          );
                                        } else if (mounted) {
                                          setState(() => _isUpdating = false);
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                    child: Text('reject'.tr()),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final bookingId = widget.booking['id']
                                          ?.toString();
                                      if (bookingId != null) {
                                        setState(() => _isUpdating = true);

                                        final success = await context
                                            .read<BookingProvider>()
                                            .completeBooking(bookingId);

                                        if (success && mounted) {
                                          // Ensure small delay for server to persist
                                          await Future.delayed(
                                            const Duration(milliseconds: 1000),
                                          );
                                          setState(() => _isUpdating = false);
                                          await _refreshStatus();
                                          if (mounted) {
                                            ToastUtils.showSuccess(
                                              context: context,
                                              message: 'consultation_completed'
                                                  .tr(),
                                            );
                                          }
                                        } else if (!success && mounted) {
                                          setState(() => _isUpdating = false);
                                          ToastUtils.showError(
                                            context: context,
                                            message:
                                                context
                                                    .read<BookingProvider>()
                                                    .error ??
                                                'Failed to complete booking',
                                          );
                                        } else if (mounted) {
                                          setState(() => _isUpdating = false);
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                    child: Text('confirm_completion'.tr()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],

                    if (isConsultation &&
                        !isCompleted &&
                        !isCancelled &&
                        !isCompletionRequested) ...[
                      // Consultation Reason
                      Text(
                        'consultation_reason_title'
                            .tr(), // Needs localization key eventually
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          booking['consultation_reason'] ??
                              'booking_consultation_reason_placeholder'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],

                    SizedBox(height: 32.h),

                    // Provider Details (Mini Card)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24.r,
                            backgroundImage: CachedNetworkImageProvider(
                              providerImage,
                            ),
                            backgroundColor: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  providerName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final rating =
                                        double.tryParse(
                                          booking['provider_rating']
                                                  ?.toString() ??
                                              '0',
                                        ) ??
                                        0.0;
                                    final count =
                                        booking['provider_review_count'] ?? 0;
                                    return Text(
                                      '⭐ ${rating.toStringAsFixed(1)} ($count ${'service_reviews'.tr()})',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Only show communication for active, non-cancelled bookings
                          if (!isCompleted &&
                              !isCompletionRequested &&
                              !isCancelled &&
                              isConsultation)
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  AppRouter.navigateTo(
                                    context,
                                    Routes.chat,
                                    arguments: {
                                      'providerId': booking['provider_id'],
                                      'providerName': booking['provider_name'],
                                      'providerImage':
                                          booking['provider_image'],
                                      'bookingId': booking['id'],
                                      'isConsultation': isConsultation,
                                    },
                                  );
                                },
                              ),
                            ),
                          if (!isCompleted && !isCancelled) ...[
                            SizedBox(width: 8.w),
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: AppColors.primary,
                                ),
                                onPressed: () async {
                                  final phone = booking['provider_phone'];
                                  if (phone != null &&
                                      phone.toString().isNotEmpty) {
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      if (context.mounted) {
                                        ToastUtils.showError(
                                          context: context,
                                          message:
                                              'Could not launch dialer for $phone',
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ToastUtils.showError(
                                        context: context,
                                        message: 'No phone number available',
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (isConsultation &&
                        !isCompleted &&
                        !isCancelled &&
                        !isCompletionRequested) ...[
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: () {
                          AppRouter.navigateTo(
                            context,
                            Routes.chat,
                            arguments: {
                              'providerId': booking['provider_id'],
                              'providerName': booking['provider_name'],
                              'providerImage': booking['provider_image'],
                              'bookingId': booking['id'],
                              'isConsultation': isConsultation,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: Size(double.infinity, 54.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 5,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'continue_consultation'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Provider Avatar (Overlapping Header & Sheet)
          Positioned(
            top: 180.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36.r,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: NetworkImage(providerImage),
                ),
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Button for Cancel/Report
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: SizedBox(
          width: double.infinity,
          height: 56.h,
          child: Consumer<BookingProvider>(
            builder: (context, provider, child) {
              if (isUserGoingToProvider &&
                  (currentStatus == 'pending' ||
                      currentStatus == 'confirmed')) {
                // Show TWO buttons: Cancel (Red) & Confirm (Green)
                return Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('booking_cancel_title'.tr()),
                                    content: Text(
                                      'booking_cancel_content'.tr(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('cancel'.tr()),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: Text('confirm'.tr()),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final userId = context
                                      .read<AuthProvider>()
                                      .user
                                      ?.id
                                      .toString();
                                  if (userId != null) {
                                    final success = await provider
                                        .cancelBooking(
                                          booking['id'].toString(),
                                          userId,
                                        );
                                    if (success) {
                                      Navigator.pop(context); // Go back to list
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'booking_cancelled_success'.tr(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            provider.error ??
                                                'cancellation_failed'.tr(),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: provider.isLoading
                            ? SizedBox(
                                height: 20.sp,
                                width: 20.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Text(
                                'cancel'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Confirm Success Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                final userId = context
                                    .read<AuthProvider>()
                                    .user
                                    ?.id
                                    .toString();
                                if (userId != null) {
                                  // Using completeBooking as "Confirm Success"
                                  final success = await provider
                                      .completeBooking(
                                        booking['id'].toString(),
                                      );

                                  if (success) {
                                    await _refreshStatus();
                                    if (context.mounted) {
                                      ToastUtils.showSuccess(
                                        context: context,
                                        message: 'booking_completed_success'
                                            .tr(), // "Booking completed successfully"
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ToastUtils.showError(
                                        context: context,
                                        message: provider.error ?? 'error'.tr(),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 2,
                        ),
                        child: provider.isLoading
                            ? SizedBox(
                                height: 20.sp,
                                width: 20.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'confirm_booking'.tr(), // "Confirm Booking"
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }

              // ORIGINAL LOGIC for other types / statuses
              return ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (currentStatus == 'completed') {
                          _showRatingSheet();
                        } else if (currentStatus == 'pending' ||
                            currentStatus == 'confirmed') {
                          // Cancel Logic
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('booking_cancel_title'.tr()),
                              content: Text('booking_cancel_content'.tr()),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('cancel'.tr()),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: Text('confirm'.tr()),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final userId = context
                                .read<AuthProvider>()
                                .user
                                ?.id
                                .toString();
                            if (userId != null) {
                              final success = await provider.cancelBooking(
                                booking['id'].toString(),
                                userId,
                              );
                              if (success) {
                                Navigator.pop(context); // Go back to list
                                ToastUtils.showSuccess(
                                  context: context,
                                  message: 'booking_cancelled_success'.tr(),
                                );
                              } else {
                                ToastUtils.showError(
                                  context: context,
                                  message:
                                      provider.error ??
                                      'cancellation_failed'.tr(),
                                );
                              }
                            }
                          }
                        } else {
                          // Support - New Help Center
                          AppRouter.navigateTo(
                            context,
                            Routes.helpCenter,
                            arguments: {
                              'additionalHiddenInfo':
                                  'Booking ID: ${booking['id']}\nService: $serviceName\nProvider: $providerName',
                            },
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStatus == 'completed'
                      ? AppColors.primary
                      : isDark
                      ? AppColors.backgroundDark
                      : Colors.white,
                  foregroundColor: currentStatus == 'completed'
                      ? Colors.white
                      : Colors.red,
                  side: currentStatus == 'completed'
                      ? null
                      : BorderSide(color: Colors.red.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: currentStatus == 'completed' ? 4 : 0,
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        currentStatus == 'completed'
                            ? 'service_rating'.tr()
                            : (currentStatus == 'pending' ||
                                  currentStatus == 'confirmed')
                            ? 'booking_cancel'.tr()
                            : 'booking_report_issue'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRatingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingBottomSheet(
        onSubmit: (rating, comment) async {
          final providerId = widget.booking['provider_id'].toString();
          final userId = context.read<AuthProvider>().user?.id.toString();

          if (userId == null) return false;

          final success = await context.read<BookingProvider>().submitReview(
            providerId: providerId,
            userId: userId,
            rating: rating,
            comment: comment,
          );

          if (mounted) {
            if (success) {
              ToastUtils.showSuccess(
                context: context,
                message: 'review_submitted'.tr(),
              );
              Navigator.pop(context); // Close sheet
            } else {
              ToastUtils.showError(
                context: context,
                message:
                    context.read<BookingProvider>().error ??
                    'failed_submit_review'.tr(),
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

  Widget _buildGlassIconBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.white.withOpacity(0.2),
          child: IconButton(
            icon: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black,
              size: 20.sp,
            ),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    final steps = [
      {
        'key': 'booking_timeline_requested',
        'status': 'pending',
        'icon': Icons.calendar_today_outlined,
      },
      {
        'key': 'booking_timeline_confirmed',
        'status': 'confirmed',
        'icon': Icons.check_circle_outline,
      },
      {
        'key': 'booking_timeline_on_way',
        'status': 'on_way',
        'icon': Icons.directions_car_filled_outlined,
      },
      {
        'key': 'booking_timeline_arrived',
        'status': 'arrived',
        'icon': Icons.location_on_outlined,
      },
      {
        'key': 'booking_timeline_completed',
        'status': 'completed',
        'icon': Icons.verified_user_outlined,
      },
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Default or cancelled
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        final isActive = index == currentIndex;

        Color color = isCompleted ? AppColors.primary : Colors.grey[300]!;
        if (isActive && currentStatus == 'on_way') color = Colors.blue;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line & Icon
              Column(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: 2.w,
                      ),
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 16.sp,
                      color: isCompleted ? AppColors.primary : Colors.grey[400],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.w,
                        color: isCompleted && index < currentIndex
                            ? AppColors.primary
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
              // Text Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (step['key']!.toString()).tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCompleted
                              ? isDark
                                    ? Colors.white
                                    : AppColors.textPrimary
                              : Colors.grey[400],
                        ),
                      ),
                      if (isActive && currentStatus == 'on_way')
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'tracking_provider_status'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
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
      },
    );
  }
}
