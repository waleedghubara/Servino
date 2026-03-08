import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/errors/exceptions.dart';
import 'package:dartz/dartz.dart';
import 'package:servino_client/features/notifications/data/models/notification_model.dart';

class NotificationRepository {
  final ApiConsumer api;
  NotificationRepository({required this.api});

  Future<Either<String, List<NotificationModel>>> getNotifications(
    String userId,
  ) async {
    try {
      final response = await api.get(
        EndPoint.getNotifications,
        queryParameters: {'user_id': userId},
      );

      final List<dynamic> data = response['data'] ?? [];
      final notifications = data
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      return Right(notifications);
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> markRead(String notificationId) async {
    try {
      final response = await api.post(
        EndPoint.markNotificationRead,
        data: {'id': notificationId},
      );
      return Right(response['message']);
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> markAllRead(String userId) async {
    try {
      final response = await api.post(
        EndPoint.markNotificationRead,
        data: {'user_id': userId, 'mark_all': true},
      );
      return Right(response['message']);
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> deleteNotification(
    String notificationId,
  ) async {
    try {
      final response = await api.post(
        EndPoint
            .deleteNotification, // Ensure this endpoint exists in EndPoint class or use string literal temporarily if not defined
        data: {'id': notificationId},
      );
      return Right(response['message']);
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
