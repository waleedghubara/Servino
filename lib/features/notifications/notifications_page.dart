// ignore_for_file: deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/notifications/data/models/notification_model.dart';
import 'package:servino_client/features/notifications/logic/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().getNotifications(
          user.id.toString(),
        );
      }
    });
  }

  Future<void> _refresh() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<NotificationProvider>().getNotifications(
        user.id.toString(),
      );
    }
  }

  void _markAllAsRead() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<NotificationProvider>().markAllRead(user.id.toString());
    }
  }

  void _deleteNotification(String id) {
    context.read<NotificationProvider>().deleteNotification(id);
  }

  Map<String, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> notifications,
  ) {
    final Map<String, List<NotificationModel>> grouped = {
      'notif_group_today': [],
      'notif_group_yesterday': [],
      'notif_group_older': [],
    };

    final now = DateTime.now();
    for (var notif in notifications) {
      final date = notif.date;
      final diff = now.difference(date);

      if (diff.inDays == 0 && date.day == now.day) {
        grouped['notif_group_today']!.add(notif);
      } else if (diff.inDays <= 1 && date.day == now.day - 1) {
        grouped['notif_group_yesterday']!.add(notif);
      } else {
        grouped['notif_group_older']!.add(notif);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final notifications = provider.notifications;
              final groupedNotifs = _groupNotifications(notifications);
              final hasNotifications = notifications.isNotEmpty;

              return Column(
                children: [
                  AppBar(
                    title: Text(
                      'notifications_title'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    centerTitle: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      if (hasNotifications)
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: Text(
                            'notif_mark_all_read'.tr(),
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      SizedBox(width: 8.w),
                    ],
                  ),

                  Expanded(
                    child: provider.isLoading
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: !hasNotifications
                                ? _buildEmptyState()
                                : ListView(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    children: [
                                      if (groupedNotifs['notif_group_today']!
                                          .isNotEmpty)
                                        _buildGroupSection(
                                          'notif_group_today',
                                          groupedNotifs['notif_group_today']!,
                                        ),
                                      if (groupedNotifs['notif_group_yesterday']!
                                          .isNotEmpty)
                                        _buildGroupSection(
                                          'notif_group_yesterday',
                                          groupedNotifs['notif_group_yesterday']!,
                                        ),
                                      if (groupedNotifs['notif_group_older']!
                                          .isNotEmpty)
                                        _buildGroupSection(
                                          'notif_group_older',
                                          groupedNotifs['notif_group_older']!,
                                        ),
                                    ],
                                  ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(Assets.notifications, width: 150.w, height: 150.h),
            SizedBox(height: 24.h),
            Text(
              'notifications_no_notifications'.tr(),
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection(String titleKey, List<NotificationModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            titleKey.tr(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((notif) => _buildNotificationItem(notif)),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = notif.isRead;
    final type = notif.type;

    String icon;

    switch (type) {
      case 'booking':
        icon = Assets.bookingchats;

        break;
      case 'system':
        icon = Assets.settings;

        break;
      default:
        icon = Assets.notifications;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notif.id),
      background: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.red,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 28.sp),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? AppColors.backgroundDark : Colors.white)
              : AppColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                : AppColors.primary.withOpacity(0.1),
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ListTile(
          onTap: () {
            context.read<NotificationProvider>().markRead(notif.id);
          },
          contentPadding: EdgeInsets.all(16.w),
          leading: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SvgPicture.asset(icon, width: 24.w, height: 24.h),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notif.title
                      .tr(), // Use tr() to translate DB keys like 'notif_confirmed_title'
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                    fontSize: 15.sp,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6.h),
              Text(
                notif.body.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                DateFormat.jm().format(notif.date),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
