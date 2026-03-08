import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';
import '../cache/cache_helper.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/features/auth/data/repositories/auth_repository.dart';
import '../services/call/zego_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final SecureCacheHelper _cacheHelper = SecureCacheHelper();
  final ZegoService _zegoService = ZegoService();
  // final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  static const String _userKey = 'user_data';

  UserModel? get user => _user;

  // Client specific fields if any, otherwise standard:
  // bool get isSubscribed => _user?.isSubscribed ?? false; // Client might not have subscription logic the same way

  String get userId => _user?.id.toString() ?? '';

  Future<void> loadUser() async {
    final userJson = await _cacheHelper.getDataString(key: _userKey);
    if (userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson));
        if (_user != null) {
          // await _messagingService.saveTokenToFirestore(_user!.id);
          await _zegoService.onUserLogin(_user!.id.toString(), _user!.name);
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }
  }

  Future<void> saveUser(UserModel user) async {
    _user = user;
    await _cacheHelper.saveData(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
    // _messagingService.saveTokenToFirestore(user.id);
    await _zegoService.onUserLogin(user.id.toString(), user.name);
    notifyListeners();
  }

  Future<void> logout() async {
    await _zegoService.onUserLogout();
    _user = null;
    await _cacheHelper.removeData(key: _userKey);
    await _cacheHelper.removeData(key: ApiKey.token);
    notifyListeners();
  }

  Future<void> refreshUser(AuthRepository authRepo) async {
    try {
      final result = await authRepo.getUserProfile();
      result.fold((error) => debugPrint('Error refreshing user: $error'), (
        userModel,
      ) async {
        await saveUser(userModel);
      });
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}
