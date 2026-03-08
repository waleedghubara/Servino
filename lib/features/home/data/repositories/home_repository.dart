// ignore_for_file: unused_local_variable, empty_catches, use_null_aware_elements

import 'package:dartz/dartz.dart';
import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/errors/exceptions.dart';
import 'package:servino_client/core/services/data/models/category_model.dart';
import 'package:servino_client/core/services/data/models/review_model.dart';
import 'package:servino_client/core/services/data/models/service_provider_model.dart';
import 'package:servino_client/features/home/data/models/banner_model.dart';

class HomeRepository {
  final ApiConsumer api;

  HomeRepository({required this.api});

  Future<Either<String, List<CategoryModel>>> getCategories() async {
    try {
      final response = await api.get(EndPoint.getCategories);
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return Right(data.map((e) => CategoryModel.fromJson(e)).toList());
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<BannerModel>>> getBanners() async {
    try {
      final response = await api.get(EndPoint.getBanners);
      if (response['status'] == 1 || response['status'] == true) {
        final List<dynamic> data = response['data'];
        return Right(data.map((e) => BannerModel.fromJson(e)).toList());
      } else {
        return Left(response['message'] ?? 'Unknown error');
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, ServiceProviderModel>> getProviderById(
    String providerId, {
    String? userId,
  }) async {
    try {
      final response = await api.get(
        EndPoint.getProviders,
        queryParameters: {
          'id': providerId,
          if (userId != null) 'user_id': userId,
        },
      );
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        if (data.isNotEmpty) {
          return Right(ServiceProviderModel.fromJson(data[0]));
        } else {
          return const Left('Provider not found');
        }
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<ServiceProviderModel>>> getProviders({
    String? categoryId,
    String? serviceId,
    String? userId,
  }) async {
    try {
      final response = await api.get(
        EndPoint.getProviders,
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId,
          if (serviceId != null) 'service_id': serviceId,
          if (userId != null) 'user_id': userId,
        },
      );
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return Right(
          data.map((e) => ServiceProviderModel.fromJson(e)).toList(),
        );
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, bool>> toggleFavorite({
    required String userId,
    required String providerId,
  }) async {
    try {
      final response = await api.post(
        EndPoint.toggleFavorite,
        data: {'user_id': userId, 'provider_id': providerId},
      );
      if (response['status'] == 1) {
        return Right(response['is_favorited'] == true);
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<ReviewModel>>> getReviews(
    String providerId,
  ) async {
    try {
      final response = await api.get(
        EndPoint.getReviews,
        queryParameters: {'provider_id': providerId},
      );
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return Right(data.map((e) => ReviewModel.fromJson(e)).toList());
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> addReview({
    required String userId,
    required String providerId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await api.post(
        EndPoint.addReview,
        data: {
          'user_id': userId,
          'provider_id': providerId,
          'rating': rating,
          'comment': comment,
        },
      );
      if (response['status'] == 1) {
        return Right(response['message']);
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> incrementViews({
    required String providerId,
    required String viewerId,
  }) async {
    try {
      // print(
      //   'DEBUG: incrementViews (GET) called for provider $providerId from viewer $viewerId',
      // );
      // Using query parameters for a simple direct GET request
      final response = await api.get(
        EndPoint.incrementViews,
        queryParameters: {'provider_id': providerId, 'viewer_id': viewerId},
      );
      // print('DEBUG: incrementViews response: $response');
    } catch (e) {
      // print('DEBUG: Error in incrementViews: $e');
    }
  }

  Future<Either<String, List<ServiceProviderModel>>> getFavorites(
    String userId,
  ) async {
    try {
      final response = await api.get(
        EndPoint.getFavorites,
        queryParameters: {'user_id': userId},
      );
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return Right(
          data.map((e) => ServiceProviderModel.fromJson(e)).toList(),
        );
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<Map<String, dynamic>>>> getProviderStatus({
    String? categoryId,
    String? serviceId,
  }) async {
    try {
      final response = await api.get(
        EndPoint.getProviderStatus,
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId,
          if (serviceId != null) 'service_id': serviceId,
        },
      );
      if (response['status'] == 1) {
        final List<dynamic> data = response['data'];
        return Right(List<Map<String, dynamic>>.from(data));
      } else {
        return Left(response['message']);
      }
    } on ServerException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
