// ignore_for_file: avoid_print, use_null_aware_elements

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/errors/exception.dart';
import 'package:servino_client/features/auth/data/models/user_model.dart';
import 'package:servino_client/core/cache/cache_helper.dart';

class AuthRepository {
  final ApiConsumer api;

  AuthRepository({required this.api});

  Future<Either<String, String>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? dob,
    String? gender,
    String? fcmToken,
    File? image,
  }) async {
    try {
      final Map<String, dynamic> uploadData = {
        ApiKey.name: name,
        ApiKey.email: email,
        ApiKey.phone: phone,
        ApiKey.password: password,
        ApiKey.confirmPassword: confirmPassword,
        'dob': dob,
        'gender': gender,
        'fcm_token': fcmToken,
      };

      if (image != null) {
        String fileName = image.path.split('/').last;
        uploadData['image'] = await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        );
      }

      final response = await api.post(
        EndPoint.register,
        data: uploadData,
        isFromData: true, // Use FormData
      );

      // Backend returns {status: 1, message: "...", data: {...}, token: "..."}
      // Or {status: 1, message: "...", token: "..." ...}
      // Let's assume standard response structure

      // Check logical status if your API wraps success in {status: 1} even for 200 OK
      if (response['status'] == 1) {
        // Backend returns {status: 1, message: "...", email: "..."}
        // No token yet.
        return Right(response['message'] ?? 'OTP Sent');
      } else {
        return Left(response['message'] ?? 'Registration failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel>> login({
    required String email,
    required String password,
    String? fcmToken,
    String? locale, // New
  }) async {
    try {
      final Map<String, dynamic> data = {
        ApiKey.email: email,
        ApiKey.password: password,
      };
      if (fcmToken != null) {
        data['fcm_token'] = fcmToken;
      }
      if (locale != null) {
        data['locale'] = locale;
      }

      final response = await api.post(EndPoint.login, data: data);

      if (response['status'] == 1) {
        final user = UserModel.fromJson(response['data']);
        final token = response[ApiKey.token];

        if (token != null) {
          await SecureCacheHelper().saveData(key: ApiKey.token, value: token);
          await SecureCacheHelper().saveData(key: ApiKey.id, value: user.id);
        }
        return Right(user);
      } else if (response['status'] == 2) {
        return const Left('Unverified');
      } else {
        return Left(response['message'] ?? 'Login failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Map<String, dynamic>>> googleLogin({
    required String email,
    required String googleId,
    required String name,
    String? image,
    String? fcmToken,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'email': email,
        'google_id': googleId,
        'name': name,
        if (image != null) 'image': image,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };

      final response = await api.post(EndPoint.googleLogin, data: data);

      if (response['status'] == 1) {
        final user = UserModel.fromJson(response['data']);
        final token = response[ApiKey.token];
        final isNew = response['is_new'] ?? false;

        if (token != null) {
          await SecureCacheHelper().saveData(key: ApiKey.token, value: token);
          await SecureCacheHelper().saveData(key: ApiKey.id, value: user.id);
        }
        return Right({'user': user, 'is_new': isNew});
      } else {
        return Left(response['message'] ?? 'Google Login failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel>> verifyOtp({
    required String email,
    required String otp,
    String? fcmToken,
  }) async {
    try {
      final Map<String, dynamic> data = {ApiKey.email: email, 'otp': otp};
      if (fcmToken != null) {
        data['fcm_token'] = fcmToken;
      }

      final response = await api.post(EndPoint.verifyOtp, data: data);

      if (response['status'] == 1) {
        final user = UserModel.fromJson(response['data']);
        final token = response[ApiKey.token];

        if (token != null) {
          await SecureCacheHelper().saveData(key: ApiKey.token, value: token);
          await SecureCacheHelper().saveData(key: ApiKey.id, value: user.id);
        }
        return Right(user);
      } else {
        return Left(response['message'] ?? 'Verification failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> resendOtp({required String email}) async {
    try {
      final response = await api.post(
        EndPoint.resendOtp,
        data: {ApiKey.email: email},
      );

      if (response['status'] == 1) {
        return Right(response['message'] ?? 'OTP Resent');
      } else {
        return Left(response['message'] ?? 'Resend failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> forgotPassword({required String email}) async {
    try {
      final response = await api.post(
        EndPoint.forgotPassword,
        data: {ApiKey.email: email},
      );
      if (response['status'] == 1) {
        return Right(response['message'] ?? 'OTP Sent');
      } else {
        return Left(response['message'] ?? 'Failed to send OTP');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await api.post(
        EndPoint.resetPassword,
        data: {ApiKey.email: email, 'otp': otp, 'new_password': newPassword},
      );
      if (response['status'] == 1) {
        return Right(response['message'] ?? 'Password Reset Successful');
      } else {
        return Left(response['message'] ?? 'Reset Failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel>> getUserProfile() async {
    try {
      final response = await api.get(EndPoint.getUserProfile);
      if (response['status'] == 1) {
        return Right(UserModel.fromJson(response['data']));
      } else {
        return Left(response['message'] ?? 'Failed to get profile');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel>> updateProfile({
    required int id,
    String? name,
    String? phone,
    String? dob,
    String? gender,
    File? image,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'id': id,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
      };

      if (image != null) {
        String fileName = image.path.split('/').last;
        data['image'] = await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        );
      }

      final response = await api.post(
        EndPoint.updateUserProfile,
        data: data,
        isFromData: true,
      );

      if (response['status'] == 1) {
        return Right(UserModel.fromJson(response['data']));
      } else {
        return Left(response['message'] ?? 'Update failed');
      }
    } on ServerException catch (e) {
      return Left(e.errorModel.errorMessage);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> updateProviderStatus(String providerId) async {
    try {
      await api.post(EndPoint.updateStatus, data: {'provider_id': providerId});
    } catch (e) {
      // print('Error updating status: $e');
    }
  }
}
