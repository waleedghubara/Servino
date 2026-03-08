import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:servino_client/core/services/chats/models/message_model.dart';
import 'package:servino_client/features/chat/data/repo/chat_repository.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ChatRepository _repository;
  final String _currentUserId;

  // State
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOtherUserOnline = false;

  // Polling
  Timer? _pollingTimer;
  final int _pollingIntervalMs = 5000;
  final int _maxPollingIntervalMs = 10000;
  DateTime? _lastUserActivity;
  late String _otherUserId;
  String? _bookingId;
  String _otherUserRole = 'provider';
  String _otherUserName = '';
  String _currentUserName = '';

  List<MessageModel> get messages {
    return _messages;
  }

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isOtherUserOnline => _isOtherUserOnline;
  MessageModel? _replyingTo;
  MessageModel? get replyingTo => _replyingTo;

  void setReplyingTo(MessageModel? message) {
    _replyingTo = message;
    notifyListeners();
  }

  ChatProvider({
    required ChatRepository repository,
    required String currentUserId,
  }) : _repository = repository,
       _currentUserId = currentUserId {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startAdaptivePolling();
      _repository.updateUserStatus(_currentUserId, true);
    } else if (state == AppLifecycleState.paused) {
      stopPolling();
      _repository.updateUserStatus(_currentUserId, false);
    }
  }

  void init(
    String otherUserId, {
    String? bookingId,
    String otherUserRole = 'provider',
    String otherUserName = '',
    String currentUserName = '',
  }) {
    _otherUserId = otherUserId;
    _bookingId = bookingId;
    _otherUserRole = otherUserRole;
    _otherUserName = otherUserName;
    _currentUserName = currentUserName;
    loadMessages(refresh: true);
    startAdaptivePolling();
    _repository.updateUserStatus(_currentUserId, true);
  }

  // --- Core Logic ---

  Future<void> loadMessages({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fetched = await _repository.getMessages(_otherUserId);
      // Sort: Newest first (for reverse list view)
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _messages = fetched;

      // Mark as read if we have new messages from other user
      _markAsReadIfNeeded();

      // Initial status check
      await _fetchUserStatus();
    } catch (e) {
      debugPrint("Error loading messages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _markAsReadIfNeeded() {
    // If we have messages from the other user that are not read/seen, mark them.
    // Check local list first to avoid redundant API calls if already marked.
    // Assuming backend handles "mark all unread from X as read".
    bool hasUnread = _messages.any(
      (m) => !m.isMe && m.status != MessageStatus.read,
    );

    if (hasUnread) {
      _repository.markMessagesAsRead(_otherUserId, role: _otherUserRole);
    }
  }

  // --- Polling ---

  void startAdaptivePolling() {
    stopPolling();
    _poll();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _poll() async {
    if (_otherUserId.isEmpty) return;

    int interval = _pollingIntervalMs;
    // Adaptive interval logic...
    if (_lastUserActivity != null &&
        DateTime.now().difference(_lastUserActivity!).inSeconds > 30) {
      interval = _maxPollingIntervalMs;
    }

    _pollingTimer = Timer(Duration(milliseconds: interval), () async {
      await Future.wait([_fetchUpdates(), _fetchUserStatus()]);
      if (_pollingTimer != null) _poll();
    });
  }

  Future<void> _fetchUserStatus() async {
    try {
      final statusData = await _repository.getUserStatus(
        _otherUserId,
        role: _otherUserRole,
      );
      if (statusData != null) {
        final isOnline =
            statusData['is_online'] == true || statusData['is_online'] == '1';
        if (_isOtherUserOnline != isOnline) {
          _isOtherUserOnline = isOnline;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user status: $e");
    }
  }

  Future<void> _fetchUpdates() async {
    try {
      final fetched = await _repository.getMessages(_otherUserId);
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (fetched.isNotEmpty) {
        debugPrint(
          'DEBUG: Latest fetched: ${fetched.first.id} - ${fetched.first.status}',
        );
        if (_messages.isNotEmpty) {
          debugPrint(
            'DEBUG: Latest local: ${_messages.first.id} - ${_messages.first.status}',
          );
        }
      }

      bool hasChanges = false;
      if (fetched.length != _messages.length) {
        hasChanges = true;
      } else {
        // Check if latest message status changed or any message status changed
        // Simply checking length and first/last might miss status updates in middle.
        // For efficiency, checking top few might be enough, but let's be safe.
        // Or deeper check:
        for (int i = 0; i < fetched.length; i++) {
          if (i >= _messages.length) break;
          if (fetched[i].id != _messages[i].id ||
              fetched[i].status != _messages[i].status) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        _messages = fetched;
        _markAsReadIfNeeded();
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  // --- Sending ---

  void userActivityDetected() {
    _lastUserActivity = DateTime.now();
  }

  Future<void> sendMessage(String text) async {
    _send(content: text, type: MessageType.text);
  }

  Future<void> sendImage(File file) async {
    _uploadAndSend(file: file, type: MessageType.image);
  }

  Future<void> sendVideo(File file) async {
    _uploadAndSend(file: file, type: MessageType.video);
  }

  Future<void> sendAudio(File file) async {
    _uploadAndSend(file: file, type: MessageType.audio);
  }

  Future<void> sendLocation(double lat, double long) async {
    _send(content: "$lat,$long", type: MessageType.location);
  }

  Future<void> _send({
    required String content,
    required MessageType type,
  }) async {
    _isSending = true;
    userActivityDetected();

    final tempId = const Uuid().v4();
    final tempMessage = MessageModel(
      id: tempId,
      senderId: _currentUserId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
    );

    // Add to list (at top)
    _messages.insert(0, tempMessage);
    notifyListeners();

    Map<String, dynamic>? replyToData;
    if (_replyingTo != null) {
      replyToData = {
        'messageId': _replyingTo!.id,
        'senderName': _replyingTo!.isMe ? _currentUserName : _otherUserName,
        'messagePreview': _getMessagePreview(_replyingTo!),
        'messageType': _replyingTo!.type.name,
      };
    }

    final success = await _repository.sendMessage(
      receiverId: _otherUserId,
      content: content,
      type: type.name,
      bookingId: _bookingId,
      replyToId: _replyingTo?.id,
      replyToData: replyToData,
    );

    if (success) {
      setReplyingTo(null);
    }

    _updateMessageStatus(
      tempId,
      success ? MessageStatus.sent : MessageStatus.error,
    );
    _isSending = false;
    notifyListeners();
    _fetchUpdates(); // Sync real ID
  }

  Future<void> _uploadAndSend({
    required File file,
    required MessageType type,
  }) async {
    _isSending = true;
    userActivityDetected();

    final tempId = const Uuid().v4();
    final tempMessage = MessageModel(
      id: tempId,
      senderId: _currentUserId,
      content: file.path, // Local path for immediate display
      type: type,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
      attachmentUrl: file.path,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final url = await _repository.uploadFile(file);
      final success = await _repository.sendMessage(
        receiverId: _otherUserId,
        content: url,
        type: type.name,
        bookingId: _bookingId,
      );

      // Update with URL? Or just status.
      // Better to keep local path for display until refresh?
      // Actually refetch will replace it.
      _updateMessageStatus(
        tempId,
        success ? MessageStatus.sent : MessageStatus.error,
      );
    } catch (e) {
      _updateMessageStatus(tempId, MessageStatus.error);
    }

    _isSending = false;
    notifyListeners();
    _fetchUpdates();
  }

  void _updateMessageStatus(String tempId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == tempId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
    }
  }

  String _getMessagePreview(MessageModel message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return 'Image 📷';
      case MessageType.video:
        return 'Video 🎥';
      case MessageType.audio:
        return 'Audio 🎤';
      case MessageType.location:
        return 'Location 📍';
    }
  }
}
