// ignore_for_file: use_null_aware_elements

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/api/end_point.dart';

class BookingRepository {
  final ApiConsumer api;

  BookingRepository({required this.api});

  Future<Either<String, bool>> createBooking({
    required String providerId,
    required String userId,
    required String date,
    required String time,
    String type = 'service',
    double price = 0.0,
    String location = '',
    String notes = '',
  }) async {
    try {
      final response = await api.post(
        EndPoint.createBooking,
        data: {
          'provider_id': providerId,
          'user_id': userId,
          'type': type,
          'date': date,
          'time': time,
          'price': price,
          'location': location,
          'notes': notes,
        },
      );
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<dynamic>>> getUserBookings(String userId) async {
    try {
      final response = await api.get(
        EndPoint.getUserBookings,
        queryParameters: {'user_id': userId},
      );
      if (response['data'] != null) {
        return Right(response['data']);
      } else {
        return const Right([]);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> cancelBooking({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final response = await api.post(
        EndPoint.cancelBooking,
        data: {'id': bookingId, 'user_id': userId},
      );
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? userId,
  }) async {
    try {
      final data = {
        'id': bookingId,
        'booking_id': int.tryParse(bookingId) ?? bookingId,
        'status': status,
        if (userId != null) 'user_id': userId,
      };
      debugPrint('Updating status: $data');
      final response = await api.post(EndPoint.updateBookingStatus, data: data);
      debugPrint('Status update response: $response');
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message'] ?? 'Failed to update status');
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> completeBooking(String bookingId) async {
    try {
      final response = await api.post(
        EndPoint.completeBooking,
        data: {'booking_id': bookingId},
      );
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message'] ?? 'Failed to complete booking');
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> rejectCompletion(String bookingId) async {
    try {
      final response = await api.post(
        EndPoint.rejectCompletion,
        data: {'booking_id': bookingId},
      );
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message'] ?? 'Failed to reject completion');
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> submitReview({
    required String providerId,
    required String userId,
    required double rating,
    String comment = '',
  }) async {
    try {
      final response = await api.post(
        EndPoint.addReview,
        data: {
          'provider_id': providerId,
          'user_id': userId,
          'rating': rating,
          'comment': comment,
        },
      );
      if (response['status'] == 1) {
        return const Right(true);
      } else {
        return Left(response['message'] ?? 'Failed to submit review');
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
