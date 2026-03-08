// ignore_for_file: avoid_print

import 'package:servino_client/core/cache/cache_helper.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:dio/dio.dart';
import 'package:servino_client/core/routes/app_router.dart';
import 'package:servino_client/core/routes/routes.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // تحديد نوع المحتوى فقط إذا لم تكن FormData
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    final token = await SecureCacheHelper().getData(key: ApiKey.token);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      // print('✅ Token Added: FOODAPI $token');
    } else {
      // print('⚠️ No token found in secure storage');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 0. Handle Banned Users (403)
    if (err.response?.statusCode == 403 &&
        err.response?.data is Map &&
        err.response?.data['is_banned'] == true) {
      // Clear Token globally
      await SecureCacheHelper().removeData(key: ApiKey.token);

      // Navigate to Banned Screen
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.banned,
        (route) => false,
      );

      return super.onError(err, handler);
    }

    if (err.response?.statusCode == 401) {
      // print('⚠️ 401 Unauthorized - Logging out');

      // Clear Token
      await SecureCacheHelper().removeData(key: ApiKey.token);
    }
    super.onError(err, handler);
  }
}
