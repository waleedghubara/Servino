import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/core/api/dio_consumer.dart';
import 'package:servino_client/features/auth/data/repositories/auth_repository.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'package:servino_client/features/home/data/repositories/home_repository.dart';
import 'package:servino_client/features/home/logic/home_provider.dart';
import 'package:servino_client/features/booking/data/repositories/booking_repository.dart';
import 'package:servino_client/features/booking/logic/booking_provider.dart';
import 'package:servino_client/features/chat/data/repo/chat_repository.dart';
import 'package:servino_client/core/services/call/zego_service.dart';
import 'package:servino_client/features/notifications/data/repositories/notification_repository.dart';
import 'package:servino_client/features/notifications/logic/notification_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Provider
  sl.registerLazySingleton(
    () => AuthProvider(authRepository: sl(), zegoService: sl()),
  );

  // Repository
  sl.registerLazySingleton(() => AuthRepository(api: sl()));

  //! Features - Home
  // Provider
  sl.registerFactory(() => HomeProvider(homeRepository: sl()));

  // Repository
  sl.registerLazySingleton(() => HomeRepository(api: sl()));

  //! Features - Booking
  // Provider
  sl.registerFactory(() => BookingProvider(repository: sl()));

  // Repository
  sl.registerLazySingleton(() => BookingRepository(api: sl()));

  //! Features - Chat
  // Repository
  sl.registerLazySingleton(() => ChatRepository(sl()));

  //! Features - Notifications
  // Provider
  sl.registerFactory(() => NotificationProvider(repository: sl()));

  // Repository
  sl.registerLazySingleton(() => NotificationRepository(api: sl()));

  //! Core
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer(dio: sl()));
  sl.registerLazySingleton(() => ZegoService());

  //! External
  sl.registerLazySingleton(() => Dio());
}
