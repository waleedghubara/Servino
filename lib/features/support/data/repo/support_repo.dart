import 'dart:io';

import 'package:dio/dio.dart';
import 'package:servino_client/core/api/dio_consumer.dart';
import 'package:servino_client/core/api/end_point.dart';

class SupportRepository {
  final DioConsumer api;
  static const String adminDelimiter = "\n\n<<<<ADMIN_DATA>>>>\n";

  SupportRepository({required this.api});

  /// Create a new ticket
  Future<String?> createTicket({
    required String category,
    required String description,
    List<File>? images,
    String? userInfo,
  }) async {
    try {
      // 1. Upload Images First if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final url = await _uploadFile(image);
          if (url != null) imageUrls.add(url);
        }
      }

      // Appending User Info to Description
      String finalDescription = description;
      if (userInfo != null && userInfo.isNotEmpty) {
        finalDescription += "$adminDelimiter$userInfo";
      }

      // 2. Create Ticket
      final response = await api.post(
        EndPoint.createTicket,
        data: {
          'category': category,
          'description': finalDescription,
          'images': imageUrls,
        },
      );

      if (response['status'] == 1) {
        return response['ticket_id']?.toString();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get My Tickets
  Future<List<Map<String, dynamic>>> getTickets() async {
    try {
      final response = await api.get(EndPoint.getTickets);
      if (response['status'] == 1 && response['data'] != null) {
        final list = List<Map<String, dynamic>>.from(response['data']);
        for (var ticket in list) {
          if (ticket['description'] != null) {
            ticket['description'] = _stripAdminData(ticket['description']);
          }
        }
        return list;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get Messages for a Ticket
  Future<Map<String, dynamic>> getMessages(
    String ticketId, {
    String? lastId,
  }) async {
    try {
      final queryParams = {'ticket_id': ticketId};
      if (lastId != null) {
        queryParams['last_id'] = lastId;
      }

      final response = await api.get(
        EndPoint.getMessages,
        queryParameters: queryParams,
      );

      List<Map<String, dynamic>> messagesList = [];
      bool isTyping = false;

      if (response['status'] == 1) {
        if (response['data'] != null) {
          final list = List<Map<String, dynamic>>.from(response['data']);
          // Fix image URLs & Strip Admin Data
          for (var msg in list) {
            if (msg['type'] == 'image' && msg['attachment_url'] != null) {
              msg['attachment_url'] = _fixUrl(msg['attachment_url']);
            }
            if (msg['content'] != null) {
              msg['content'] = _stripAdminData(msg['content']);
            }
            if (msg['sender_image'] != null &&
                msg['sender_image'].toString().isNotEmpty) {
              msg['sender_image'] = _fixUrl(msg['sender_image']);
            }
          }
          messagesList = list;
        }
        if (response['admin_typing'] != null) {
          isTyping = response['admin_typing'] == true;
        }
      }
      return {'messages': messagesList, 'typing': isTyping};
    } catch (e) {
      // In case of error, return empty list and false typing
      return {'messages': <Map<String, dynamic>>[], 'typing': false};
    }
  }

  /// Send a Message
  Future<bool> sendMessage({
    required String ticketId,
    String? content,
    File? image, // Allow sending image directly
  }) async {
    try {
      String? attachmentUrl;
      if (image != null) {
        attachmentUrl = await _uploadFile(image);
      }

      final response = await api.post(
        EndPoint.sendSupportMessage,
        data: {
          'ticket_id': ticketId,
          'content': content,
          'attachment_url': attachmentUrl,
        },
      );

      return response['status'] == 1;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper to upload file (using existing Chat/Upload API logic)
  Future<String?> _uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await api.post(
        EndPoint.uploadFile,
        data: formData,
        isFromData: false,
      );

      if (response['status'] == 1) {
        return _fixUrl(response['url']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _fixUrl(String url) {
    if (url.contains('10.24.132.59')) {
      // Replace partial IP with current configured IP
      // We parse EndPoint.baseUrl to get the host
      try {
        final currentHost = Uri.parse(EndPoint.baseUrl).host;
        return url.replaceAll('10.24.132.59', currentHost);
      } catch (e) {
        return url;
      }
    }
    return url;
  }

  String _stripAdminData(String content) {
    if (content.contains(adminDelimiter)) {
      return content.split(adminDelimiter).first.trim();
    }
    return content;
  }

  /// Set User Typing Status
  Future<void> setTyping({
    required String ticketId,
    required bool isTyping,
  }) async {
    try {
      await api.post(
        EndPoint.setSupportTyping,
        data: {'ticket_id': ticketId, 'is_typing': isTyping},
      );
    } catch (e) {
      // Ignore errors for typing updates
    }
  }

  /// Mark messages as read
  Future<void> markMessagesRead(String ticketId) async {
    try {
      await api.post(
        'support/mark_messages_read.php',
        data: {'ticket_id': ticketId},
      );
    } catch (e) {
      // Ignore errors
    }
  }
}
