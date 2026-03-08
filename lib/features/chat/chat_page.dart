// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:servino_client/core/services/chats/models/message_model.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/core/widgets/chat_app_bar.dart';
import 'package:servino_client/core/widgets/chat_input_field.dart';
import 'package:servino_client/core/widgets/message_bubble.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/chat/data/repo/chat_repository.dart';
import 'package:servino_client/features/chat/logic/chat_provider.dart';
import 'package:servino_client/features/booking/logic/booking_provider.dart';
import 'package:servino_client/core/widgets/consultation_completion_dialog.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/injection_container.dart' as di;

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? initialArguments;

  const ChatPage({super.key, this.initialArguments});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final args = widget.initialArguments ?? {};
      final bookingId = args['bookingId']?.toString();
      if (bookingId == null) return;

      if (!mounted) return;

      // Use the booking provider to fetch latest status
      final bookingProvider = context.read<BookingProvider>();
      // We need a method to get single booking status or refresh list
      // Assuming fetchUserBookings or similar refreshes the list in provider
      // But better to have a lightweight status check.
      // For now, we reuse existing functionality, maybe fetch user bookings silently if needed
      // Or if ChatProvider has booking details.
      // Let's assume we can check the booking in the provider's list.

      final userId = context.read<AuthProvider>().user?.id.toString();
      if (userId != null) {
        await bookingProvider.silentlyRefreshBookings(userId);
      }

      if (!mounted) return;

      // Check status
      final booking = bookingProvider.bookings.firstWhere(
        (b) => b['id'].toString() == bookingId,
        orElse: () => null,
      );

      if (booking != null) {
        final status = booking['status']?.toString().toLowerCase();
        if (status == 'completionrequested') {
          _pollingTimer?.cancel(); // Stop polling while dialog is open
          _showCompletionDialog(bookingId);
        }
      }
    });
  }

  void _showCompletionDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConsultationCompletionDialog(
        onYes: () async {
          Navigator.pop(context); // Close Dialog
          // Confirm
          final success = await context.read<BookingProvider>().completeBooking(
            bookingId,
          );
          if (success && mounted) {
            Navigator.pop(context); // Close Chat
            ToastUtils.showSuccess(
              context: context,
              message: 'booking_completed_success'.tr(),
            );
          }
        },
        onNo: () async {
          Navigator.pop(context); // Close Dialog
          // Reject
          final success = await context
              .read<BookingProvider>()
              .rejectCompletion(bookingId);
          if (success && mounted) {
            _startStatusPolling(); // Restart polling
          }
        },
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording(ChatProvider provider) async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        provider.sendAudio(File(path));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  Future<void> _pickImage(ChatProvider provider, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      provider.sendImage(File(image.path));
      _scrollToBottom();
    }
  }

  Future<void> _pickVideo(ChatProvider provider, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (video != null) {
      provider.sendVideo(File(video.path));
      _scrollToBottom();
    }
  }

  Future<void> _sendLocation(ChatProvider provider) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle denied forever
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('chat_location_denied'.tr())));
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Trying legacy parameters as locationSettings caused an error
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading

      provider.sendLocation(position.latitude, position.longitude);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('chat_location_error'.tr())));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentSheet(BuildContext context, ChatProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Wrap(
          spacing: 40.w,
          runSpacing: 20.h,
          alignment: WrapAlignment.center,
          children: [
            _AttachmentIcon(
              Icons.image,
              Colors.purple,
              'chat_attachment_image'.tr(),
              () {
                Navigator.pop(context);
                _pickImage(provider, ImageSource.gallery);
              },
            ),
            _AttachmentIcon(
              Icons.camera_alt,
              Colors.blue,
              'chat_attachment_camera'.tr(),
              () {
                Navigator.pop(context);
                _pickImage(provider, ImageSource.camera);
              },
            ),
            _AttachmentIcon(
              Icons.videocam,
              Colors.pink,
              'chat_attachment_video'.tr(),
              () {
                Navigator.pop(context);
                _pickVideo(provider, ImageSource.gallery);
              },
            ),

            _AttachmentIcon(
              Icons.location_on,
              Colors.green,
              'chat_attachment_location'.tr(),
              () {
                Navigator.pop(context);
                _sendLocation(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.initialArguments ?? {};
    final otherUserId =
        args['otherUserId']?.toString() ?? args['providerId']?.toString() ?? '';
    final bookingId = args['bookingId']?.toString();
    final otherUserName =
        args['otherUserName'] ?? args['providerName'] ?? 'Chat';
    final otherUserImage = args['otherUserImage'] ?? args['providerImage'];

    final currentUser = context.read<AuthProvider>().user;
    final currentUserId = currentUser?.id.toString() ?? 'me';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          ChangeNotifierProvider(
            create: (context) =>
                ChatProvider(
                  repository: di.sl<ChatRepository>(),
                  currentUserId: currentUserId,
                )..init(
                  otherUserId,
                  bookingId: bookingId,
                  otherUserName: otherUserName,
                  currentUserName: currentUser?.name ?? 'Me',
                ),
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: ChatAppBar(
                    inviteeId: otherUserId,
                    userName: otherUserName,
                    userImage: otherUserImage ?? '',
                    isOnline: provider.isOtherUserOnline,
                    onBackTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  body: Column(
                    children: [
                      if (provider.isLoading)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            provider.setReplyingTo(null);
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 8.w,
                            ),
                            itemCount: provider.messages.length,
                            itemBuilder: (context, index) {
                              final msg = provider.messages[index];
                              return MessageBubble(
                                message: msg,
                                onSwipe: () => provider.setReplyingTo(msg),
                              );
                            },
                          ),
                        ),
                      ),
                      _buildInputArea(context, provider, isDark, otherUserName),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
    String otherUserName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.replyingTo != null)
          _ReplyPreview(
            message: provider.replyingTo!,
            otherUserName: otherUserName,
            onCancel: () => provider.setReplyingTo(null),
          ),
        ChatInputField(
          onSendMessage: (text) {
            provider.sendMessage(text);
            _scrollToBottom();
          },
          onAttachmentTap: () => _showAttachmentSheet(context, provider),
          onRecording: (isRecording) {
            if (isRecording) {
              _startRecording();
            }
          },
          onStopRecording: () => _stopRecording(provider),
          onCancelRecording: () => _cancelRecording(),
          isSending:
              false, // You might want to bind this to provider.isLoading or similar if applicable
        ),
      ],
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final String otherUserName;
  final VoidCallback onCancel;

  const _ReplyPreview({
    required this.message,
    required this.otherUserName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Container(width: 4.w, height: 40.h, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isMe ? 'me'.tr() : otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  message.type == MessageType.text
                      ? message.content
                      : message.type.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _AttachmentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentIcon(this.icon, this.color, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
