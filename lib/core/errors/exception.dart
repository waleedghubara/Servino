import 'package:servino_client/core/errors/error_model.dart';
import 'package:dio/dio.dart';

class ServerException implements Exception {
  ServerException({required this.errorModel});
  final ErrorModel errorModel;

  @override
  String toString() {
    return errorModel.errorMessage;
  }
}

void handleDioExceptions(DioException e) {
  final responseData = e.response?.data;
  final errorModel =
      (responseData != null && responseData is Map<String, dynamic>)
      ? ErrorModel.fromJson(responseData)
      : ErrorModel(
          status: 0,
          errorMessage: e.message ?? 'An unknown error occurred',
        );

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      throw ServerException(errorModel: errorModel);
    case DioExceptionType.badResponse:
      throw ServerException(errorModel: errorModel);
  }
}
