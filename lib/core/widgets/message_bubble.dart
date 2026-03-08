// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../theme/colors.dart';
import '../services/chats/models/message_model.dart';
import '../../features/chat/pages/map_view_page.dart';
import 'full_screen_image_page.dart';
import 'voice_message_widget.dart';

// ... (existing imports and code)

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onReplyTap;
  final VoidCallback? onSwipe;
  final String? highlightedMessageId;

  const MessageBubble({
    super.key,
    required this.message,
    this.onReplyTap,
    this.onSwipe,
    this.highlightedMessageId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlighted = highlightedMessageId == message.id;

    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    final swipeDirection = _getSwipeDirection(isRtl);

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Dismissible(
        key: Key('reply_${message.id}'),
        direction: swipeDirection,
        dismissThresholds: {
          DismissDirection.startToEnd: 0.2, // Require 20% swipe
          DismissDirection.endToStart: 0.2, // Require 20% swipe
        },
        confirmDismiss: (direction) async {
          if (onSwipe != null) onSwipe!();
          return false; // Don't actually dismiss
        },
        background: _buildSwipeBackground(context, swipeDirection),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary.withOpacity(0.3) : null,
            gradient: isHighlighted
                ? null
                : message.isMe
                ? LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 73, 30, 229),
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isDark
                ? LinearGradient(
                    colors: [
                      AppColors.backgroundDark,
                      AppColors.backgroundDark.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.recipientColor,
                      AppColors.recipientColorSubtle,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: message.isMe ? Radius.circular(16.r) : Radius.zero,
              bottomRight: message.isMe ? Radius.zero : Radius.circular(16.r),
            ),
            border: Border.all(
              color: isHighlighted
                  ? Colors.amber
                  : message.isMe
                  ? AppColors.surface
                  : isDark
                  ? Colors.grey.shade800
                  : const Color(0xFFF2F2F2),
              width: isHighlighted ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              message.type == MessageType.text ? 12.0.r : 4.0.r,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (message.replyTo != null) _buildReplyQuote(context),
                _buildContent(context),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: message.isMe
                            ? Colors.white.withOpacity(0.9)
                            : isDark
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.surfaceDark,
                      ),
                    ),
                    if (message.isMe) ...[
                      SizedBox(width: 4.w),
                      _buildStatusIcon(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DismissDirection _getSwipeDirection(bool isRtl) {
    if (isRtl) {
      // In Arabic (Rtl): Me is on LEFT. Swipe from left (start) to right.
      // Other is on RIGHT. Swipe from right (end) to left.
      // Actually common behavior: Swipe person's message "inwards"
      // If other (Right) -> Swipe Left (endToStart)
      // If me (Left) -> Swipe Right (startToEnd)
      return message.isMe
          ? DismissDirection.startToEnd
          : DismissDirection.endToStart;
    } else {
      // In English (Ltr): Me is on RIGHT. Swipe from right (end) to left.
      // Other is on LEFT. Swipe from left (start) to right.
      return message.isMe
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd;
    }
  }

  Widget _buildSwipeBackground(
    BuildContext context,
    DismissDirection direction,
  ) {
    bool isLeftToRight = direction == DismissDirection.startToEnd;
    return Container(
      alignment: isLeftToRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.reply, color: AppColors.primary, size: 22.sp),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time, // Clock icon for sending
          size: 11.sp,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check, // Single check
          size: 15.sp,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all, // Double check
          size: 15.sp,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all, // Double check
          size: 15.sp,
          color: const Color.fromARGB(255, 247, 181, 1), // WhatsApp blue
        );
      case MessageStatus.error:
        return Icon(Icons.error_outline, size: 13.sp, color: Colors.red);
    }
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isMe
                ? Colors.white
                : isDark
                ? Colors.white
                : AppColors.surfaceDark,
            fontSize: 14.sp,
          ),
        );
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return VideoMessageBubble(message: message);
      case MessageType.audio:
        return VoiceMessageWidget(url: message.content, isMe: message.isMe);

      case MessageType.location:
        return _buildLocationMessage(context);
    }
  }

  Widget _buildReplyQuote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onReplyTap,
      child: Container(
        width: 200.w,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: message.isMe
              ? Colors.white.withOpacity(0.3)
              : isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyTo!.senderName,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      message.replyTo!.messagePreview,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: message.isMe
                            ? AppColors.primary22
                            : isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapViewPage(url: message.content),
          ),
        );
      },
      child: Container(
        width: 220.w,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: message.isMe
              ? const Color.fromARGB(255, 26, 3, 68)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: message.isMe ? Colors.white : AppColors.primary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'chat_location_shared'.tr(),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildMapPreview(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final latLng = _getLatLngFromUrl(message.content);
    if (latLng == null) {
      return Center(
        child: Icon(Icons.map, color: Colors.grey[400], size: 50.sp),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: latLng,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.servino.client',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: latLng,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  LatLng? _getLatLngFromUrl(String url) {
    try {
      // First try to parse as "lat,long"
      final parts = url.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final long = double.tryParse(parts[1].trim());
        if (lat != null && long != null) {
          return LatLng(lat, long);
        }
      }

      // If not, try to parse as URI with query parameter
      final uri = Uri.parse(url);
      final query = uri.queryParameters['q'];
      if (query != null) {
        final queryParts = query.split(',');
        if (queryParts.length == 2) {
          return LatLng(
            double.parse(queryParts[0]),
            double.parse(queryParts[1]),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing location URL: $e');
    }
    return null;
  }

  Widget _buildImageMessage(BuildContext context) {
    bool isNetwork = message.content.startsWith('http');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImagePage(imageUrl: message.content),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: isNetwork
            ? CachedNetworkImage(
                imageUrl: message.content,
                width: 200.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200.w,
                  height: 200.w,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 200.w,
                  height: 150.h,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : Image.file(
                File(message.content),
                width: 200.w,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 200.w,
                  height: 150.h,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
  }
}

class VideoMessageBubble extends StatefulWidget {
  final MessageModel message;
  const VideoMessageBubble({super.key, required this.message});

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.message.content.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.message.content),
        );
      } else {
        final file = File(widget.message.content);
        if (!await file.exists()) {
          debugPrint('Video file not found: ${widget.message.content}');
          if (mounted) {
            setState(() {
              _initialized = false;
            });
          }
          return;
        }
        _videoPlayerController = VideoPlayerController.file(file);
      }

      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _initialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: _initialized && _chewieController != null
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
