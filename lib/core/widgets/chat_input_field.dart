// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import '../theme/colors.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onAttachmentTap;
  final Function(bool isRecording) onRecording;
  final VoidCallback onStopRecording;
  final VoidCallback? onCancelRecording;
  final bool isSending;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    required this.onAttachmentTap,
    required this.onRecording,
    required this.onStopRecording,
    this.onCancelRecording,
    this.isSending = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  bool _isComposing = false;
  bool _isRecording = false;
  bool _isLocked = false;
  bool _sendOnRelease = false; // لو سبت فورًا يبعت الصوت

  Timer? _entryTimer;
  int _recordDuration = 0;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isLocked = false;
      _sendOnRelease = true;
      _recordDuration = 0;
    });

    widget.onRecording(true);
    _startTimer();
  }

  void _stopRecording({bool cancel = false}) {
    _entryTimer?.cancel();

    if (!cancel) {
      widget.onStopRecording();
    } else {
      widget.onCancelRecording?.call();
    }

    setState(() {
      _isRecording = false;
      _isLocked = false;
      _sendOnRelease = false;
      _recordDuration = 0;
    });

    widget.onRecording(false);
  }

  void _startTimer() {
    _entryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.backgroundDark : AppColors.surface)
                .withOpacity(0.5),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    .withOpacity(0.5),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (!_isRecording)
                  InkWell(
                    onTap: widget.onAttachmentTap,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.all(8.0.r),
                      child: Icon(
                        Icons.attachment,
                        color: AppColors.primary,
                        size: 28.sp,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 44.w),

                SizedBox(width: 8.w),

                Expanded(
                  child: _isRecording
                      ? _buildRecordingDisplay(isDark)
                      : _buildInputContainer(),
                ),

                SizedBox(width: 8.w),

                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isComposing) {
      return InkWell(
        onTap: widget.isSending
            ? null
            : () {
                widget.onSendMessage(_controller.text);
                _controller.clear();
                setState(() => _isComposing = false);
              },
        child: CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.primary,
          child: widget.isSending
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: widget.isSending ? null : (_) => _startRecording(),
      onLongPressMoveUpdate: (details) {
        if (widget.isSending) return;
        if (details.localOffsetFromOrigin.dy < -50) {
          setState(() {
            _isLocked = true;
            _sendOnRelease = false;
          });
        }
      },
      onLongPressEnd: (_) {
        if (widget.isSending) return;
        if (!_isLocked && _sendOnRelease) {
          _stopRecording();
        }
      },
      onTap: () {
        if (widget.isSending) return;
        if (_isRecording && _isLocked) {
          _stopRecording();
        } else if (!_isRecording) {
          ToastUtils.showInfo(
            context: context,
            message: 'chat_hold_to_record'.tr(),
          );
        }
      },
      child: _isRecording
          ? CircleAvatar(
              radius: 25.r,
              backgroundColor: Colors.red,
              child: Icon(
                _isLocked ? Icons.send : Icons.mic,
                color: Colors.white,
                size: 26.sp,
              ),
            )
          : CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primary,
              child: widget.isSending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.mic_rounded, color: Colors.white, size: 20.sp),
            ),
    );
  }

  Widget _buildInputContainer() {
    return TextField(
      controller: _controller,
      onChanged: (text) =>
          setState(() => _isComposing = text.trim().isNotEmpty),
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'chat_hint'.tr(),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
      ),
    );
  }

  Widget _buildRecordingDisplay(bool isDark) {
    return Row(
      children: [
        FadeTransition(
          opacity: _animationController,
          child: const Icon(Icons.fiber_manual_record, color: Colors.red),
        ),
        SizedBox(width: 8.w),
        Text(
          _formatDuration(_recordDuration),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),

        // Lock hint (سحب للأعلى للتثبيت)
        if (_isRecording && !_isLocked)
          Row(
            children: [
              Icon(Icons.lock_open, color: Colors.grey, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'pull_up_to_secure'.tr(),
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ],
          ),

        // Cancel button (بعد Lock)
        if (_isLocked)
          InkWell(
            onTap: () => _stopRecording(cancel: true),
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 6.w),
                Text(
                  'cancel_recording'.tr(),
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
