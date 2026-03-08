// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:servino_client/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';
import 'package:servino_client/core/services/chats/models/message_model.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/support/data/repo/support_repo.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SupportChatPage extends StatefulWidget {
  final String category;
  final String description;
  final List<String> imagePaths;
  final String? ticketId;
  final Map<String, String>? userInfo;

  const SupportChatPage({
    super.key,
    required this.category,
    required this.description,
    required this.imagePaths,
    this.ticketId,
    this.userInfo,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late SupportRepository _repository;
  Timer? _pollingTimer;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isTyping = false;
  String? _typingAdminName;
  String? _typingAdminImage;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _repository = SupportRepository(api: DioConsumer(dio: Dio()));
    _initHiveAndLoad();
    // Poll every 1.5 seconds for typing updates and messages
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (widget.ticketId != null) {
        _loadMessages(isPolling: true);
      }
    });
  }

  Future<void> _initHiveAndLoad() async {
    final cleanId = widget.ticketId?.replaceAll('#', '') ?? 'unknown';
    await Hive.openBox('support_cache_$cleanId');
    await _loadMessagesFromCache();
    await _loadMessages();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Box _getBox() {
    final cleanId = widget.ticketId?.replaceAll('#', '') ?? 'unknown';
    return Hive.box('support_cache_$cleanId');
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final box = _getBox();
      final data = _messages.map((m) => m.toJson()).toList();
      await box.put('messages', data);
    } catch (e) {
      debugPrint('Error saving messages to Hive: $e');
    }
  }

  Future<void> _loadMessagesFromCache() async {
    try {
      final box = _getBox();
      final List<dynamic>? data = box.get('messages');
      if (data != null && data.isNotEmpty) {
        final cachedMsgs = data
            .map(
              (json) => MessageModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(cachedMsgs);
            _isLoading = false;
          });
          _scrollToBottom(force: true);
        }
      }
    } catch (e) {
      debugPrint('Error loading messages from Hive: $e');
    }
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    if (widget.ticketId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Load from cache on first load
    if (!isPolling && _messages.isEmpty) {
      await _loadMessagesFromCache();
    }

    try {
      final cleanId = widget.ticketId!.replaceAll('#', '');

      // Use last_id for optimized fetching (only if it's a real numeric ID)
      String? lastId;
      if (_messages.isNotEmpty) {
        // Find the last real DB message
        try {
          final lastRealMsg = _messages.lastWhere(
            (m) => int.tryParse(m.id) != null,
          );
          lastId = lastRealMsg.id;
        } catch (_) {
          // No numeric ID found yet
        }
      }

      final response = await _repository.getMessages(cleanId, lastId: lastId);
      final List<Map<String, dynamic>> msgs = response['messages'];
      final bool isAdminTyping = response['typing'] == true;
      final String? typingName = response['typing_admin_name'];
      final String? typingImage = response['typing_admin_image'];

      if (msgs.isEmpty &&
          isAdminTyping == _isTyping &&
          typingName == _typingAdminName &&
          typingImage == _typingAdminImage &&
          isPolling)
        return;

      final newMessagesFromNet = msgs.map((m) {
        return MessageModel(
          id: m['id'].toString(),
          senderId: m['is_me'] == true ? 'me' : 'agent',
          content: m['type'] == 'image'
              ? (m['attachment_url'] ?? '')
              : (m['content'] ?? ''),
          type: m['type'] == 'image' ? MessageType.image : MessageType.text,
          attachmentUrl: m['type'] == 'image' ? m['attachment_url'] : null,
          timestamp:
              DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now(),
          isMe: m['is_me'] == true,
          status: MessageStatus.sent,
          senderName: m['sender_name'],
          senderImage: m['sender_image'],
        );
      }).toList();

      if (mounted) {
        bool shouldScroll = false;

        // Smart scrolling: scroll only if already at the bottom or if it's a new incoming message
        if (isPolling) {
          if (_scrollController.hasClients) {
            final pos = _scrollController.position;
            if (pos.maxScrollExtent - pos.pixels < 150) {
              shouldScroll = true;
            }
          }
        } else {
          shouldScroll = true;
        }

        // New incoming message implies we should see it
        if (isPolling && newMessagesFromNet.isNotEmpty) {
          final lastMsg = newMessagesFromNet.last;
          if (!lastMsg.isMe) {
            _playMessageSound();
            shouldScroll = true;
          }
        }

        setState(() {
          if (lastId != null) {
            for (var newMsg in newMessagesFromNet) {
              // Deduplicate: Remove any local message with same content if it's not a real DB ID
              _messages.removeWhere(
                (m) =>
                    int.tryParse(m.id) == null &&
                    m.content == newMsg.content &&
                    m.type == newMsg.type,
              );
              if (!_messages.any((m) => m.id == newMsg.id)) {
                _messages.add(newMsg);
              }
            }
          } else if (newMessagesFromNet.isNotEmpty || !isPolling) {
            _messages.clear();
            _messages.addAll(newMessagesFromNet);
          }

          _isTyping = isAdminTyping; // Update typing status
          _typingAdminName = typingName;
          _typingAdminImage = typingImage;
          _isLoading = false;
        });

        if (newMessagesFromNet.isNotEmpty) {
          _saveMessagesToCache();
          // Mark as read if there are new messages not from me
          if (newMessagesFromNet.any((m) => !m.isMe)) {
            _repository.markMessagesRead(cleanId);
          }
        }

        if (shouldScroll) {
          _scrollToBottom(force: !isPolling);
        } else if (isPolling && _isTyping) {
          _scrollToBottom(force: false);
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _scrollToBottom({bool force = false}) {
    if (!mounted) return;

    // Use postFrameCallback to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;

        // If force is true, we jump. Otherwise, we only animate if necessary.
        if (force) {
          _scrollController.jumpTo(target);
        } else {
          // Only animate if the difference is significant to avoid "stuttering"
          final current = _scrollController.position.pixels;
          if ((target - current).abs() > 10) {
            _scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  Future<void> _onSendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || widget.ticketId == null) return;

    _inputController.clear();
    setState(() => _isComposing = false);

    // Optimistic UI
    final tempId = DateTime.now().toString();
    final tempMsg = MessageModel(
      id: tempId,
      senderId: 'me',
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(tempMsg);
    });
    _saveMessagesToCache();
    _scrollToBottom();

    try {
      final cleanId = widget.ticketId!.replaceAll('#', '');
      await _repository.sendMessage(ticketId: cleanId, content: text);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = tempMsg.copyWith(status: MessageStatus.sent);
        }
      });
      _loadMessages(isPolling: true);
    } catch (e) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = tempMsg.copyWith(status: MessageStatus.error);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (!mounted) return;

      if (image != null && widget.ticketId != null) {
        Navigator.pop(context); // Close sheet

        // Optimistic
        final tempId = DateTime.now().toString();
        setState(() {
          _messages.add(
            MessageModel(
              id: tempId,
              senderId: 'me',
              content: image.path,
              type: MessageType.image,
              timestamp: DateTime.now(),
              isMe: true,
              attachmentUrl: image.path,
              status: MessageStatus.sending,
            ),
          );
        });
        _saveMessagesToCache();
        _scrollToBottom();

        try {
          final cleanId = widget.ticketId!.replaceAll('#', '');
          await _repository.sendMessage(
            ticketId: cleanId,
            image: File(image.path),
          );
          setState(() {
            _loadMessages(isPolling: true);
          });
        } catch (e) {
          // Handle error
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _playMessageSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/message_received.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_isTyping) return const SizedBox.shrink();

    // Get info from last agent message
    final lastAgentMsg = _messages.lastWhere(
      (m) => !m.isMe,
      orElse: () => MessageModel(
        id: '0',
        senderId: 'agent',
        content: '',
        type: MessageType.text,
        timestamp: DateTime.now(),
        isMe: false,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.backgroundDark, AppColors.primary]
                    : [AppColors.secondary, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'admin_typing'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.surface : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          CircleAvatar(
            radius: 12.r,
            backgroundImage:
                (lastAgentMsg.senderImage != null &&
                    lastAgentMsg.senderImage!.isNotEmpty)
                ? NetworkImage(lastAgentMsg.senderImage!)
                : const AssetImage(Assets.logoApp) as ImageProvider,
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.image, color: Colors.purple, size: 24.sp),
              ),
              title: Text(
                'chat_attachment_image'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue, size: 24.sp),
              ),
              title: Text(
                'chat_attachment_camera'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Background (Unchanged)
        const Positioned.fill(child: AnimatedBackground()),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.8),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
                size: 20.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Builder(
                  builder: (context) {
                    final lastAgentMsg = _messages.lastWhere(
                      (m) => !m.isMe,
                      orElse: () => MessageModel(
                        id: '0',
                        senderId: 'agent',
                        content: '',
                        type: MessageType.text,
                        timestamp: DateTime.now(),
                        isMe: false,
                      ),
                    );
                    final hasAgentInfo =
                        lastAgentMsg.senderImage != null &&
                        lastAgentMsg.senderImage!.isNotEmpty;

                    return Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.backgroundDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 18.r,
                        backgroundColor: hasAgentInfo
                            ? Colors.grey[200]
                            : Colors.transparent,
                        backgroundImage: hasAgentInfo
                            ? NetworkImage(lastAgentMsg.senderImage!)
                            : null,
                        child: !hasAgentInfo
                            ? Padding(
                                padding: EdgeInsets.all(4.w),
                                child: SvgPicture.asset(Assets.supportSvg2),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final lastAgentMsg = _messages.lastWhere(
                            (m) => !m.isMe,
                            orElse: () => MessageModel(
                              id: '0',
                              senderId: 'agent',
                              content: '',
                              type: MessageType.text,
                              timestamp: DateTime.now(),
                              isMe: false,
                            ),
                          );
                          return Text(
                            lastAgentMsg.senderName ?? 'support_team'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      Text(
                        '${'support_ticket_id'.tr()} ${widget.ticketId ?? ''}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  widget.category,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isFirst = index == 0;
                          final isLast = index == _messages.length - 1;
                          final prevMsg = !isFirst
                              ? _messages[index - 1]
                              : null;
                          final nextMsg = !isLast ? _messages[index + 1] : null;

                          // Group logic for rounded corners
                          final isMe = msg.isMe;
                          final isPrevSame =
                              prevMsg != null && prevMsg.isMe == isMe;
                          final isNextSame =
                              nextMsg != null && nextMsg.isMe == isMe;

                          return _SupportMessageBubble(
                            message: msg,
                            isFirstInGroup: !isPrevSame,
                            isLastInGroup: !isNextSame,
                          );
                        },
                      ),
              ),
              _buildTypingIndicator(),
              _buildInputArea(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        10.h + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.transparent,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAttachmentSheet,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _inputController,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.sp,
                ),
                maxLines: null,
                minLines: null,
                expands: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSendMessage(),
                onChanged: (val) {
                  setState(() {
                    _isComposing = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'chat_hint'.tr(),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  filled: false,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isComposing ? _onSendMessage : null,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _isComposing
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.grey[200]),
                shape: BoxShape.circle,
                boxShadow: _isComposing
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isComposing ? Colors.white : Colors.grey,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _SupportMessageBubble({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = message.isMe;
    final appTextDirection = Directionality.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              if (isLastInGroup)
                SizedBox(
                  height: 28.r,
                  width: 28.r,
                  child: CircleAvatar(
                    radius: 14.r,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (message.senderImage != null &&
                            message.senderImage!.isNotEmpty)
                        ? NetworkImage(message.senderImage!)
                        : null,
                    child:
                        (message.senderImage == null ||
                            message.senderImage!.isEmpty)
                        ? Icon(Icons.person, size: 18.sp, color: Colors.grey)
                        : null,
                  ),
                )
              else
                SizedBox(width: 28.r),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: 0,
                  right: 0,
                  top: isFirstInGroup ? 8.h : 0,
                ),
                padding: message.type == MessageType.image
                    ? EdgeInsets.all(4.w)
                    : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  gradient: isMe
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary22],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                    bottomLeft: Radius.circular(
                      isMe ? 20.r : (isLastInGroup ? 4.r : 20.r),
                    ),
                    bottomRight: Radius.circular(
                      !isMe ? 20.r : (isLastInGroup ? 4.r : 20.r),
                    ),
                  ),
                  boxShadow: [
                    if (!isMe && isDark == false)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Directionality(
                  textDirection: appTextDirection,
                  child: _buildContent(context, isMe),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMe) {
    if (message.type == MessageType.image) {
      return Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                (message.attachmentUrl != null &&
                        message.attachmentUrl!.startsWith('http'))
                    ? Image.network(
                        message.attachmentUrl!,
                        fit: BoxFit.cover,
                        width: 200.w,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150.h,
                          width: 200.w,
                          color: Colors.grey,
                        ),
                      )
                    : Image.file(
                        File(message.attachmentUrl ?? ''),
                        fit: BoxFit.cover,
                        width: 200.w,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150.h,
                          width: 200.w,
                          color: Colors.grey,
                        ),
                      ),
              ],
            ),
          ),
          if (isMe) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9.sp,
                  ),
                ),
                SizedBox(width: 4.w),
                _buildStatusIcon(),
              ],
            ),
          ],
        ],
      );
    }

    // Text Message
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF2D3748)),
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                fontSize: 10.sp,
              ),
            ),
            if (isMe) ...[SizedBox(width: 4.w), _buildStatusIcon()],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = Colors.white.withOpacity(0.7);

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time_rounded;
        break;
      case MessageStatus.sent:
        icon = Icons.done_all_rounded; // Double check for sent
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
        break;
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
        color = Colors.blueAccent; // Double blue for read
        break;
      case MessageStatus.error:
        icon = Icons.error_outline_rounded;
        color = Colors.redAccent;
        break;
    }

    return Icon(icon, size: 14.sp, color: color);
  }
}
