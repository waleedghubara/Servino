// ignore_for_file: prefer_null_aware_operators
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:servino_client/core/services/security_service.dart';
import 'package:servino_client/core/widgets/security.dart';
import 'package:servino_client/core/providers/internet_connection_provider.dart';
import 'package:servino_client/core/errors/pages/no_internet_page.dart';
import 'package:upgrader/upgrader.dart';
import 'package:toastification/toastification.dart';
import 'core/routes/app_router.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'core/localization/localization_manager.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';
import 'injection_container.dart' as di;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/features/home/logic/home_provider.dart';
import 'package:servino_client/features/booking/logic/booking_provider.dart';
import 'package:servino_client/features/notifications/logic/notification_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:servino_client/core/services/notification_service.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:servino_client/core/utils/lifecycle_manager.dart'; // Added import
import 'package:hive_flutter/hive_flutter.dart';
import 'package:servino_client/core/services/firestore_config_service.dart';
import 'package:servino_client/core/ads/ads_manager.dart';
import 'package:servino_client/core/services/call/zego_service.dart';
import 'package:servino_client/features/auth/data/models/user_model.dart';
import 'dart:convert';
import 'package:servino_client/core/cache/cache_helper.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:servino_client/core/ads/app_lifecycle_reactor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // AdsMode.production
  AdsManager.instance.setAdsMode(AdsMode.production);

  await AdsManager.instance.initialize();
  await FirestoreConfigService().initialize();

  await di.init();
  await ThemeManager().init();

  // Initialize Ads
  AppLifecycleReactor(
    adsManager: AdsManager.instance,
  ).listenToAppStateChanges();

  // Init Notifications and Call Services (Mobile only)
  bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  if (isMobile) {
    // Setup Zego Navigator Key
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(
      AppRouter.navigatorKey,
    );

    // Init Notifications
    await NotificationService().initialize();

    // Init Zego Synchronously if logged in
    final userJson = await SecureCacheHelper().getDataString(key: 'user_data');
    if (userJson != null) {
      try {
        final cachedUser = UserModel.fromJson(jsonDecode(userJson));
        await ZegoService().onUserLogin(
          cachedUser.id.toString(),
          cachedUser.name,
          cachedUser.fullImage,
        );
      } catch (e) {
        // Handle decode error
      }
    }

    // Enable Offline Calling (CallKit/SystemUI)
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
      ZegoUIKitSignalingPlugin(),
    ]);
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Security Checks
  final securityService = SecurityService();
  try {
    // Enable SSL Pinning immediately
    // await securityService.pinSSL(); // Uncomment when certificates are ready

    final isSafe = await securityService.runSecurityChecks();
    if (!isSafe) {
      runApp(
        EasyLocalization(
          supportedLocales: LocalizationManager.supportedLocales,
          path: LocalizationManager.translationsPath,
          fallbackLocale: LocalizationManager.fallbackLocale,
          startLocale: LocalizationManager.fallbackLocale,
          child: const SecurityBlockerApp(),
        ),
      );
      return;
    }
  } catch (e) {
    // debugPrint('Security check failed with error: $e');
    // // Decide whether to block or allow based on error policy.
    // // For now, allow but log.
  }

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      startLocale: LocalizationManager.fallbackLocale,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
          ChangeNotifierProvider(
            create: (_) => di.sl<HomeProvider>()..getCategories(),
          ),
          ChangeNotifierProvider(create: (_) => di.sl<BookingProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<NotificationProvider>()),
          ChangeNotifierProvider(create: (_) => InternetConnectionProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeManager().themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'Servino',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              navigatorKey: AppRouter.navigatorKey,
              initialRoute: Routes.splash,
              onGenerateRoute: AppRouter.generateRoute,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: (context, child) {
                return Consumer2<AuthProvider, InternetConnectionProvider>(
                  builder: (context, authProvider, internetProvider, _) {
                    if (!internetProvider.isConnected) {
                      return NoInternetPage(
                        onRetry: () => internetProvider.retry(),
                      );
                    }

                    debugPrint(
                      'MyApp: AuthProvider user: ${authProvider.user?.id}',
                    );

                    return UpgradeAlert(
                      child: LifecycleManager(
                        userId: authProvider.user?.id.toString(),
                        role: authProvider.user?.role ?? 'user',
                        child: Stack(
                          children: [
                            ToastificationWrapper(child: child!),

                            /// support minimizing
                            ZegoUIKitPrebuiltCallMiniOverlayPage(
                              contextQuery: () {
                                return AppRouter
                                    .navigatorKey
                                    .currentState!
                                    .context;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
