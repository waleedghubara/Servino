// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes.dart';
import '../../core/services/data/models/service_provider_model.dart';
import '../auth/logic/auth_provider.dart';
import 'logic/booking_provider.dart';

class BookingPage extends StatefulWidget {
  final ServiceProviderModel provider;
  final bool isChatInitiated;

  const BookingPage({
    super.key,
    required this.provider,
    this.isChatInitiated = false,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  DateTime? _customTime;

  List<DateTime> get _rawTimeSlots {
    final now = DateTime.now();
    final baseTime = DateTime(now.year, now.month, now.day);

    final defaultSlots = [
      baseTime.copyWith(hour: 9),
      baseTime.copyWith(hour: 10),
      baseTime.copyWith(hour: 11),
      baseTime.copyWith(hour: 12),
      baseTime.copyWith(hour: 14),
      baseTime.copyWith(hour: 15),
      baseTime.copyWith(hour: 16),
      baseTime.copyWith(hour: 17),
      baseTime.copyWith(hour: 18),
      baseTime.copyWith(hour: 19),
    ];

    return defaultSlots;
  }

  Future<void> _pickCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _customTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _selectedTimeIndex = -999;
      });
    }
  }

  String _locationType =
      'bookings_tab_going_to_him'; // 'bookings_tab_going_to_him', 'bookings_tab_coming_to_me', or 'consultation'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),

          Column(
            children: [
              AppBar(
                title: Text(
                  'booking_appointment_title'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: AppColors.primary,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.black,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 10.w, 20.w, 100.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProviderCard(),
                      SizedBox(height: 24.h),

                      _buildSectionHeader('booking_location_type'),
                      SizedBox(height: 12.h),
                      _buildLocationSelector(),
                      SizedBox(height: 24.h),

                      _buildSectionHeader('booking_select_date'),
                      SizedBox(height: 12.h),
                      _buildDateSelector(),
                      SizedBox(height: 24.h),

                      _buildSectionHeader('booking_select_time'),
                      SizedBox(height: 12.h),
                      _buildTimeSelector(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),

              _buildBottomBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          _buildLocationOption(
            'bookings_tab_going_to_him',
            'bookings_tab_going_to_him'.tr(),
            Icons.store_mall_directory_outlined,
          ),
          _buildLocationOption(
            'bookings_tab_coming_to_me',
            'bookings_tab_coming_to_me'.tr(),
            Icons.home_outlined,
          ),
          _buildLocationOption(
            'consultation',
            'bookings_tab_consultation'.tr(),
            Icons.video_chat_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(String type, String label, IconData icon) {
    final isSelected = _locationType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _locationType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      titleKey.tr(),
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildProviderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : Colors.white.withOpacity(0.85),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'provider_${widget.provider.id}_image',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: CachedNetworkImage(
                imageUrl: widget.provider.imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey.shade100,
                  width: 80.w,
                  height: 80.w,
                  child: Icon(Icons.person, color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[700],
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            widget.provider.rating.toString(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  widget.provider.subCategory.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14.sp,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        widget.provider.location.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final locale = context.locale.languageCode;
    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final date = now.add(Duration(days: index));
          final isSelected = _selectedDateIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.backgroundDark
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                      ? Colors.grey[800]!
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM', locale).format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : isDark
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('d', locale).format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('E', locale).format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : isDark
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeSlots = _rawTimeSlots;
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        ...List.generate(timeSlots.length, (index) {
          final timeSlot = timeSlots[index];
          final now = DateTime.now();

          // Calculate if this specific slot is in the past
          // The selected date is determined by _selectedDateIndex
          final selectedDateBase = now.add(Duration(days: _selectedDateIndex));

          // Construct the full DateTime for this slot on the selected day
          final slotDateTime = DateTime(
            selectedDateBase.year,
            selectedDateBase.month,
            selectedDateBase.day,
            timeSlot.hour,
            timeSlot.minute,
          );

          final isPast = slotDateTime.isBefore(now);
          final isSelected = _selectedTimeIndex == index;

          // Format for display (localized)
          final timeStr = DateFormat.jm(
            context.locale.toString(),
          ).format(timeSlot);

          return IgnorePointer(
            ignoring: isPast,
            child: GestureDetector(
              onTap: () {
                if (!isPast) {
                  setState(() {
                    _selectedTimeIndex = index;
                    _customTime = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isPast
                      ? (isDark ? Colors.grey[900] : Colors.grey[200])
                      : (isDark
                            ? AppColors.backgroundDark
                            : Colors.white.withOpacity(0.9)),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isPast
                        ? Colors.transparent
                        : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isPast
                        ? Colors.grey
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.sp,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          );
        }),

        // Custom Time Button
        GestureDetector(
          onTap: _pickCustomTime,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _selectedTimeIndex == -999
                  ? isDark
                        ? AppColors.primary
                        : AppColors.backgroundDark
                  : isDark
                  ? AppColors.backgroundDark
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: _selectedTimeIndex == -999
                    ? isDark
                          ? AppColors.backgroundDark
                          : Colors.white.withOpacity(0.9)
                    : AppColors.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 16.sp,
                  color: _selectedTimeIndex == -999
                      ? Colors.white
                      : AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  _selectedTimeIndex == -999 && _customTime != null
                      ? DateFormat.jm(
                          context.locale.toString(),
                        ).format(_customTime!)
                      : 'booking_pick_time'.tr(),
                  style: TextStyle(
                    color: _selectedTimeIndex == -999
                        ? Colors.white
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed:
                    ((_selectedTimeIndex != -1 || _selectedTimeIndex == -999) ||
                            _locationType == 'consultation') &&
                        !bookingProvider.isLoading
                    ? () async {
                        if (_locationType == 'consultation') {
                          AppRouter.navigateTo(
                            context,
                            Routes.paymentRequired,
                            arguments: widget.provider,
                          );
                          return;
                        }
                        final userId = context
                            .read<AuthProvider>()
                            .user
                            ?.id
                            .toString();
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to book'),
                            ),
                          );
                          return;
                        }

                        // Calculate full DateTime
                        final dateBase = DateTime.now().add(
                          Duration(days: _selectedDateIndex),
                        );

                        DateTime timeDate;
                        if (_selectedTimeIndex == -999 && _customTime != null) {
                          timeDate = _customTime!;
                        } else {
                          timeDate = _rawTimeSlots[_selectedTimeIndex];
                        }

                        final finalDateTime = DateTime(
                          dateBase.year,
                          dateBase.month,
                          dateBase.day,
                          timeDate.hour,
                          timeDate.minute,
                        );

                        // Determine Location and Type
                        String bookingLocation;
                        String bookingType;

                        if (_locationType == 'bookings_tab_going_to_him') {
                          bookingLocation = widget.provider.location;
                          bookingType = 'Going to Him';
                        } else {
                          bookingLocation = 'Home Visit (Client Location)';
                          bookingType = 'Coming to Me';
                        }

                        final success = await bookingProvider.createBooking(
                          providerId: widget.provider.id,
                          userId: userId,
                          date: DateFormat(
                            'yyyy-MM-dd',
                            'en',
                          ).format(finalDateTime),
                          time: DateFormat(
                            'HH:mm:ss',
                            'en',
                          ).format(finalDateTime),
                          type: bookingType,
                          location: bookingLocation,
                          notes:
                              'Booking Type: ${_locationType == 'bookings_tab_going_to_him' ? 'Go to Provider' : 'Home Visit'}',
                        );

                        if (success) {
                          if (!mounted) return;
                          AppRouter.navigateTo(
                            context,
                            Routes.bookingSuccess,
                            arguments: widget.isChatInitiated,
                          );
                        } else {
                          if (!mounted) return;
                          ToastUtils.showError(
                            context: context,
                            message: bookingProvider.error ?? 'Booking failed',
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: _selectedTimeIndex != -1 ? 8 : 0,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  disabledBackgroundColor: isDark
                      ? Colors.grey[800]!
                      : Colors.grey[300],
                ),
                child: bookingProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'booking_confirm'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
