import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';

class ChatRequestWaitingPage extends StatefulWidget {
  const ChatRequestWaitingPage({super.key});

  @override
  State<ChatRequestWaitingPage> createState() => _ChatRequestWaitingPageState();
}

class _ChatRequestWaitingPageState extends State<ChatRequestWaitingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation
            Lottie.asset(
              Assets.success, // Using existing success Lottie as "Request Sent"
              height: 200.h,
              repeat: false,
            ),
            SizedBox(height: 32.h),

            // Title
            Text(
              'chat_request_sent'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),

            // Description
            Text(
              'chat_request_wait_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 48.h),

            // Action Button (Cancel)
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'cancel_request'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Dev Helper: Simulate Approval
            // In production, this would be pushing a backend loop or waiting for a push notification
            GestureDetector(
              onTap: () {
                // Determine if we need to replace or push.
                // Replacing so the user can't "back" into this waiting screen easily from chat.
                AppRouter.navigateAndReplace(context, Routes.chat);
              },
              child: Text(
                "[DEV: Simulate Provider Approval]",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
