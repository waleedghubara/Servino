import 'package:flutter/material.dart';
import 'package:servino_client/features/notifications/data/models/notification_model.dart';
import 'package:servino_client/features/notifications/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;

  NotificationProvider({required this.repository});

  List<NotificationModel> notifications = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> getNotifications(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await repository.getNotifications(userId);

    result.fold(
      (error) {
        errorMessage = error;
        // Optionally keep old data or clear it.
        // notifications = [];
      },
      (data) {
        notifications = data;
      },
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> markRead(String notificationId) async {
    // Optimistic update
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final oldItem = notifications[index];
      if (!oldItem.isRead) {
        // Create new item with isRead = true
        notifications[index] = NotificationModel(
          id: oldItem.id,
          userId: oldItem.userId,
          title: oldItem.title,
          body: oldItem.body,
          type: oldItem.type,
          isRead: true,
          date: oldItem.date,
        );
        notifyListeners();
      }
    }

    final result = await repository.markRead(notificationId);
    result.fold((error) => debugPrint(error), (success) {
      // Success
    });
  }

  Future<void> markAllRead(String userId) async {
    final result = await repository.markAllRead(userId);
    result.fold((error) => debugPrint(error), (success) {
      // Refresh list
      getNotifications(userId);
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    // Optimistic update: Remove from list immediately
    final existingIndex = notifications.indexWhere(
      (n) => n.id == notificationId,
    );
    NotificationModel? removedItem;
    if (existingIndex != -1) {
      removedItem = notifications[existingIndex];
      notifications.removeAt(existingIndex);
      notifyListeners();
    }

    final result = await repository.deleteNotification(notificationId);
    result.fold(
      (error) {
        debugPrint("Failed to delete notification: $error");
        // Rollback if failed
        if (removedItem != null && existingIndex != -1) {
          notifications.insert(existingIndex, removedItem);
          notifyListeners();
        }
      },
      (success) {
        // Success, do nothing as it's already removed
      },
    );
  }
}
