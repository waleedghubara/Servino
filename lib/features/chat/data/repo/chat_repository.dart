// ignore_for_file: use_null_aware_elements

import 'package:flutter/material.dart';
import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/core/api/end_point.dart';
import '../../../../core/services/chats/models/message_model.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final ApiConsumer _api;

  ChatRepository(this._api);

  // Fetch Messages for a specific User (Provider)
  Future<List<MessageModel>> getMessages(String otherUserId) async {
    try {
      final response = await _api.get(
        'chat/get_messages.php',
        queryParameters: {'user_id': otherUserId},
      );

      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return data.map((e) => MessageModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send Message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    String? bookingId,
    String? replyToId,
    Map<String, dynamic>? replyToData,
  }) async {
    try {
      final response = await _api.post(
        'chat/send.php',
        data: {
          'receiver_id': receiverId,
          'content': content,
          'type': type,
          if (bookingId != null) 'booking_id': bookingId,
          if (replyToId != null) 'reply_to_id': replyToId,
          if (replyToData != null) 'reply_to_data': replyToData,
        },
      );
      return response['status'] == 1;
    } catch (e) {
      return false;
    }
  }

  // Complete Booking (Consultation)
  Future<bool> completeConsultation(String bookingId) async {
    try {
      final response = await _api.post(
        'bookings/complete_booking.php',
        data: {'booking_id': bookingId},
      );
      return response['status'] == 1;
    } catch (e) {
      return false;
    }
  }

  // Reject Completion Request
  Future<bool> rejectCompletion(String bookingId) async {
    try {
      final response = await _api.post(
        'bookings/reject_completion.php',
        data: {'booking_id': bookingId},
      );
      return response['status'] == 1;
    } catch (e) {
      return false;
    }
  }

  // Get Booking Status
  Future<String?> getBookingStatus(String bookingId) async {
    try {
      final response = await _api.get(
        'bookings/read_status.php',
        queryParameters: {'booking_id': bookingId},
      );

      if (response['status'] == 1) {
        return response['data']['status'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Upload File
  Future<String> uploadFile(dynamic file) async {
    try {
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _api.post('upload/file.php', data: formData);

      if (response['status'] == 1) {
        // Try 'url' first (used by PaymentRepository), then fallback to 'file_url'
        final String? url = response['url'] ?? response['file_url'];
        if (url != null) {
          return url;
        }
      }
      throw Exception('Upload failed: Server did not return a file URL');
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Submit Review
  Future<bool> submitReview({
    required String providerId,
    required String userId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _api.post(
        EndPoint.addReview,
        data: {
          'provider_id': providerId,
          'user_id': userId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return response['status'] == 1;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserStatus(
    String userId,
    bool isOnline, {
    String? role,
  }) async {
    try {
      await _api.post(
        EndPoint.updateChatStatus,
        data: {
          'user_id': userId,
          'is_online': isOnline,
          if (role != null) 'role': role,
        },
      );
    } catch (e) {
      // Fail silently
    }
  }

  Future<Map<String, dynamic>?> getUserStatus(
    String userId, {
    String? role,
  }) async {
    try {
      final response = await _api.get(
        EndPoint.getUserChatStatus,
        queryParameters: {'user_id': userId, if (role != null) 'role': role},
      );
      if (response['status'] == 1 && response['data'] != null) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('ChatRepository: Error in getUserStatus: $e');
      return null;
    }
  }

  Future<void> markMessagesAsRead(String partnerId, {String? role}) async {
    try {
      await _api.post(
        'chat/mark_read.php',
        data: {'partner_id': partnerId, if (role != null) 'role': role},
      );
    } catch (e) {
      debugPrint('ChatRepository: markMessagesAsRead error: $e');
    }
  }

  Future<void> markMessagesAsDelivered(String partnerId, {String? role}) async {
    try {
      await _api.post(
        'chat/mark_delivered.php',
        data: {'partner_id': partnerId, if (role != null) 'role': role},
      );
    } catch (e) {
      debugPrint('ChatRepository: markMessagesAsDelivered error: $e');
    }
  }
}
