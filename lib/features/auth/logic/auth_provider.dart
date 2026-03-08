import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/cache/cache_helper.dart';
import 'package:servino_client/features/auth/data/models/user_model.dart';
import 'package:servino_client/features/auth/data/repositories/auth_repository.dart';
import '../../../core/services/call/zego_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;
  final ZegoService zegoService;
  Timer? _statusTimer;

  bool isLoading = false;
  String? errorMessage;
  UserModel? user;

  AuthProvider({required this.authRepository, required this.zegoService}) {
    // Check if user is already logged in
    loadUser();
  }

  Future<void> loadUser() async {
    final token = await SecureCacheHelper().getDataString(key: ApiKey.token);
    if (token != null) {
      isLoading = true;
      notifyListeners();

      final result = await authRepository.getUserProfile();
      result.fold(
        (failure) {
          user = null;
          errorMessage = failure;
        },
        (userModel) async {
          user = userModel;
          errorMessage = null;
          zegoService.onUserLogin(user!.id.toString(), user!.name, user!.image);
          await SecureCacheHelper().saveData(
            key: 'user_data',
            value: jsonEncode(user!.toJson()),
          );
          _startStatusUpdates();
        },
      );

      isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get FCM Token
  Future<String?> _getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // debugPrint('Error fetching FCM token: $e');
      return null;
    }
  }

  void _startStatusUpdates() {
    _statusTimer?.cancel();
    if (user?.role == 'provider') {
      _statusTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (user != null) {
          await authRepository.updateProviderStatus(user!.id.toString());
        } else {
          timer.cancel();
        }
      });
      // Initial call
      authRepository.updateProviderStatus(user!.id.toString());
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<bool> register({
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
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Auto-fetch token if not provided
    final token = fcmToken ?? await _getFcmToken();

    final result = await authRepository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      dob: dob,
      gender: gender,
      fcmToken: token,
      image: image,
    );

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (message) {
        // success message
        errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _getFcmToken();

    final result = await authRepository.verifyOtp(
      email: email,
      otp: otp,
      fcmToken: token,
    );

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (userModel) {
        user = userModel;
        errorMessage = null;
        zegoService.onUserLogin(
          user!.id.toString(),
          user!.name,
          user!.fullImage,
        );
        _startStatusUpdates();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> login({
    required String email,
    required String password,
    String? locale, // New
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _getFcmToken();

    final result = await authRepository.login(
      email: email,
      password: password,
      fcmToken: token,
      locale: locale,
    );

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (userModel) {
        user = userModel;
        errorMessage = null;
        zegoService.onUserLogin(
          user!.id.toString(),
          user!.name,
          user!.fullImage,
        );
        _startStatusUpdates();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> resendOtp({required String email}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await authRepository.resendOtp(email: email);

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (success) {
        errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> forgotPassword({required String email}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await authRepository.forgotPassword(email: email);

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (success) {
        errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await authRepository.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (success) {
        errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? dob,
    String? gender,
    File? image,
  }) async {
    if (user == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await authRepository.updateProfile(
      id: user!.id,
      name: name,
      phone: phone,
      dob: dob,
      gender: gender,
      image: image,
    );

    isLoading = false;

    return result.fold(
      (failure) {
        errorMessage = failure;
        notifyListeners();
        return false;
      },
      (updatedUser) async {
        user = updatedUser;
        // Update local cache if needed, though usually just re-fetching profile on next load is enough.
        // But for immediate UI update, we update the user object in memory.
        await SecureCacheHelper().saveData(
          key: 'user_data',
          value: jsonEncode(user!.toJson()),
        );
        errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<int> signInWithGoogle(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled
        isLoading = false;
        notifyListeners();
        return 0; // Cancelled
      }

      final token = await _getFcmToken();

      final result = await authRepository.googleLogin(
        email: googleUser.email,
        googleId: googleUser.id,
        name: googleUser.displayName ?? 'User',
        image: googleUser.photoUrl,
        fcmToken: token,
      );

      isLoading = false;

      return result.fold(
        (failure) {
          errorMessage = failure;
          notifyListeners();
          return -1; // Error
        },
        (data) async {
          final userModel = data['user'] as UserModel;
          final isNew = data['is_new'] as bool? ?? false;

          user = userModel;
          errorMessage = null;
          zegoService.onUserLogin(
            user!.id.toString(),
            user!.name,
            user!.fullImage,
          );
          await SecureCacheHelper().saveData(
            key: 'user_data',
            value: jsonEncode(user!.toJson()),
          );
          _startStatusUpdates();
          notifyListeners();

          return isNew ? 2 : 1; // 2: NewUser, 1: ExistingUser
        },
      );
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return -1; // Error
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    _statusTimer?.cancel();
    _statusTimer = null;

    // Clear Cache
    await SecureCacheHelper().removeData(key: ApiKey.token);
    await SecureCacheHelper().removeData(key: 'user_data');

    // Zego Logout
    zegoService.onUserLogout();

    // Google Sign Out (to allow account switching next time)
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore if not signed in or error
    }

    user = null;
    isLoading = false;
    notifyListeners();
  }
}
