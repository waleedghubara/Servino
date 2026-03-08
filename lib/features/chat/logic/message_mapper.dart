import 'package:servino_client/core/services/chats/models/message_model.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageMapper {
  static types.Message mapToType(MessageModel model, {required String userId}) {
    final author = types.User(id: model.senderId);
    final status = _mapStatus(model.status);

    switch (model.type) {
      case MessageType.image:
        return types.ImageMessage(
          author: author,
          createdAt: model.timestamp.millisecondsSinceEpoch,
          id: model.id,
          name: 'Image',
          size: 0,
          uri: model.content,
          status: status,
        );
      // Add more if legacy UI used
      case MessageType.text:
      default:
        return types.TextMessage(
          author: author,
          createdAt: model.timestamp.millisecondsSinceEpoch,
          id: model.id,
          text: model.content,
          status: status,
        );
    }
  }

  static types.Status _mapStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return types.Status.sending;
      case MessageStatus.sent:
        return types.Status.sent;
      case MessageStatus.delivered:
        return types.Status.delivered;
      case MessageStatus.read:
        return types.Status.seen;
      case MessageStatus.error:
        return types.Status.error;
    }
  }
}
