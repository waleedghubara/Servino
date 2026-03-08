// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../features/auth/logic/auth_provider.dart';

import '../theme/colors.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userImage;
  final bool isOnline;
  final String inviteeId;
  final VoidCallback onBackTap;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.userImage,
    required this.isOnline,
    required this.inviteeId,
    required this.onBackTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.backgroundDark : AppColors.surface)
                .withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    .withOpacity(0.5),
                width: 1.w,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
            child: Row(
              children: [
                InkWell(
                  onTap: onBackTap,
                  child: Padding(
                    padding: EdgeInsets.all(8.0.r),
                    child: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      size: 24.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundImage: CachedNetworkImageProvider(userImage),
                      backgroundColor: const Color.fromARGB(255, 51, 255, 0),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 51, 255, 0),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isOnline ? 'chat_online'.tr() : 'chat_offline'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isOnline
                              ? const Color.fromARGB(255, 51, 255, 0)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      actions ??
                      [
                        ZegoSendCallInvitationButton(
                          invitees: [
                            ZegoUIKitUser(id: inviteeId, name: userName),
                          ],
                          isVideoCall: true,
                          resourceID: "zego_uikit_call",
                          iconSize: Size(40.r, 40.r),
                          buttonSize: Size(40.r, 40.r),
                          text: '',
                          customData: jsonEncode({
                            'avatars': {
                              context.read<AuthProvider>().user?.id.toString():
                                  context.read<AuthProvider>().user?.fullImage,
                              inviteeId: userImage,
                            },
                          }),
                        ),
                        SizedBox(width: 8.w),
                        ZegoSendCallInvitationButton(
                          invitees: [
                            ZegoUIKitUser(id: inviteeId, name: userName),
                          ],
                          isVideoCall: false,
                          resourceID: "zego_uikit_call",
                          iconSize: Size(40.r, 40.r),
                          buttonSize: Size(40.r, 40.r),
                          text: '',
                          customData: jsonEncode({
                            'avatars': {
                              context.read<AuthProvider>().user?.id.toString():
                                  context.read<AuthProvider>().user?.fullImage,
                              inviteeId: userImage,
                            },
                          }),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}
