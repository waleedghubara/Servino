// ignore_for_file: empty_catches, deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/colors.dart';
import '../auth/logic/auth_provider.dart';
import 'logic/booking_provider.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  void _fetchBookings() {
    final userId = context.read<AuthProvider>().user?.id.toString();
    if (userId != null) {
      context.read<BookingProvider>().fetchUserBookings(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'bookings_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary2 : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark ? Colors.white : Colors.black,
                    unselectedLabelColor: isDark ? Colors.white : Colors.black,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    tabs: [
                      Tab(text: 'bookings_upcoming'.tr()),
                      Tab(text: 'bookings_past'.tr()),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<BookingProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(child: Text(provider.error!));
                      }

                      final allBookings = provider.bookings;

                      // Filter Bookings
                      final upcoming = <dynamic>[];
                      final past = <dynamic>[];

                      for (var b in allBookings) {
                        try {
                          final status = (b['status']?.toString() ?? 'pending')
                              .toLowerCase();
                          final isFinalStatus =
                              status == 'completed' ||
                              status == 'مكتمل' ||
                              status == 'cancelled' ||
                              status == 'rejected' ||
                              status == 'mlghy';

                          if (isFinalStatus) {
                            past.add(b);
                          } else {
                            upcoming.add(b);
                          }
                        } catch (e) {
                          // Fallback if parsing fails
                          past.add(b);
                        }
                      }

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingsList(context, upcoming, true),
                          _buildBookingsList(context, past, false),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    List<dynamic> bookings,
    bool isUpcoming,
  ) {
    Future<void> onRefresh() async {
      final userId = context.read<AuthProvider>().user?.id.toString();
      if (userId != null) {
        await context.read<BookingProvider>().fetchUserBookings(userId);
      }
    }

    if (bookings.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: SizedBox(
              height:
                  0.7.sh, // Take 70% of screen height ensuring scrollable area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    Assets.bookingchats,
                    height: 100.h,
                    width: 100.w,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'bookings_no_appointments'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          return _buildBookingCard(context, bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (booking['status'] as String).toLowerCase();

    // Localization for Category
    final isAr = context.locale.languageCode == 'ar';
    final categoryName = isAr
        ? (booking['category_name_ar'] ??
              booking['category_name_en'] ??
              'Service')
        : (booking['category_name_en'] ?? 'Service');

    Color statusColor;
    Color statusBg;
    String statusText;

    switch (status) {
      case 'pending':
      case 'قيد الانتظار':
        statusColor = const Color(0xFFFF9800);
        statusBg = const Color(0xFFFFF3E0);
        statusText = 'status_pending';
        break;
      case 'confirmed':
      case 'مؤكد':
        statusColor = const Color(0xFF4CAF50);
        statusBg = const Color(0xFFE8F5E9);
        statusText = 'status_confirmed';
        break;
      case 'on_way':
      case 'on the way':
      case 'في الطريق':
        statusColor = const Color(0xFF2196F3);
        statusBg = const Color(0xFFE3F2FD);
        statusText = 'status_on_way';
        break;
      case 'arrived':
      case 'وصل':
        statusColor = const Color(0xFF9C27B0);
        statusBg = const Color(0xFFF3E5F5);
        statusText = 'booking_timeline_arrived'; // "وصل"
        break;
      case 'completed':
      case 'مكتمل':
        statusColor = const Color(0xFF4DB6AC);
        statusBg = const Color(0xFFE0F2F1);
        statusText = 'status_completed';
        break;
      case 'cancelled':
      case 'rejected':
      case 'mlghy':
        statusColor = const Color(0xFFEF5350);
        statusBg = const Color(0xFFFFEBEE);
        statusText = 'status_cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey[200]!;
        statusText = status;
    }

    // Format Date/Time for display
    String dateDisplay = booking['date'];
    String timeDisplay = booking['time'];
    try {
      final dt = DateTime.parse('${booking['date']} ${booking['time']}');
      dateDisplay = DateFormat('MMM d', context.locale.languageCode).format(dt);
      timeDisplay = DateFormat('jm', context.locale.languageCode).format(dt);
    } catch (e) {}

    // Price Visibility Logic
    final bookingType = booking['type'] ?? '';
    final isConsultation =
        bookingType == 'Consultation' ||
        bookingType == 'استشارة' ||
        bookingType == 'استشاره';

    return GestureDetector(
      onTap: () {
        // Navigate to details if needed
        AppRouter.navigateTo(
          context,
          Routes.bookingDetails,
          arguments: booking,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D2447).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: booking['provider_image'] ?? '',
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 50.w,
                      height: 50.w,
                      color: Colors.grey[200],
                      child: Icon(Icons.person, color: Colors.grey[400]),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['provider_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    statusText.tr(), // Ensure translation is applied
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              height: 1,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: SvgPicture.asset(
                        Assets.bookingchats,
                        width: 18.sp,
                        height: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'booking_date'.tr()} & ${'booking_time'.tr()}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isDark ? Colors.white : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$dateDisplay • $timeDisplay',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isConsultation)
                  Text(
                    '${booking['price']} SAR',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
