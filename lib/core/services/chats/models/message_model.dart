enum MessageType { text, image, video, audio, location }

enum MessageStatus { sending, sent, delivered, read, error }

class MessageModel {
  final String id;
  final String senderId;
  final String content; // Text message or URL for media
  final MessageType type;
  final DateTime timestamp;
  final bool isMe;
  final String? duration; // For audio/video duration
  final String? videoThumbnail; // For video thumbnail
  final String? senderImage;
  final String? senderName;
  final MessageStatus status;
  final String? attachmentUrl;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToId;
  final ReplyModel? replyTo;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.duration,
    this.videoThumbnail,
    this.senderImage,
    this.senderName,
    this.status = MessageStatus.sent,
    this.attachmentUrl,
    this.deliveredAt,
    this.readAt,
    this.replyToId,
    this.replyTo,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content'] ?? '',
      type: _parseType(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      isMe: json['is_me'] == true,
      duration: json['duration'],
      videoThumbnail: json['video_thumbnail'],
      senderImage: json['sender_image'],
      senderName: json['sender_name'],
      status: _parseStatus(json['status']?.toString()),
      attachmentUrl: json['attachment_url'],
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      replyToId: json['reply_to_id']?.toString(),
      replyTo: json['reply_to_data'] != null
          ? ReplyModel.fromJson(
              Map<String, dynamic>.from(json['reply_to_data']),
            )
          : null,
    );
  }

  static MessageStatus _parseStatus(String? status) {
    if (status == null) return MessageStatus.sent;

    switch (status.toLowerCase()) {
      case 'read':
      case 'seen':
      case '2': // Assuming 2 is read
        return MessageStatus.read;
      case 'delivered':
      case '1': // Assuming 1 is delivered
        return MessageStatus.delivered;
      case 'sent':
      case '0': // Assuming 0 is sent
        return MessageStatus.sent;
      case 'sending':
        return MessageStatus.sending;
      case 'error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isMe,
    String? duration,
    String? videoThumbnail,
    MessageStatus? status,
    String? attachmentUrl,
    String? senderImage,
    String? senderName,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? replyToId,
    ReplyModel? replyTo,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      duration: duration ?? this.duration,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      senderImage: senderImage ?? this.senderImage,
      senderName: senderName ?? this.senderName,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'is_me': isMe,
      'duration': duration,
      'video_thumbnail': videoThumbnail,
      'status': status.name,
      'attachment_url': attachmentUrl,
      'sender_image': senderImage,
      'sender_name': senderName,
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'reply_to_id': replyToId,
      'reply_to_data': replyTo?.toJson(),
    };
  }
}

class ReplyModel {
  final String messageId;
  final String senderName;
  final String messagePreview;
  final MessageType messageType;

  ReplyModel({
    required this.messageId,
    required this.senderName,
    required this.messagePreview,
    required this.messageType,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      messageId: json['messageId'].toString(),
      senderName: json['senderName'] ?? '',
      messagePreview: json['messagePreview'] ?? '',
      messageType: _parseType(json['messageType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderName': senderName,
      'messagePreview': messagePreview,
      'messageType': messageType.name,
    };
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }
}
