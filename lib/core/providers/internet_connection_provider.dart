import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectionProvider extends ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final Connectivity _connectivity = Connectivity();

  InternetConnectionProvider() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    await _checkInternet(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_checkInternet);
  }

  Future<void> _checkInternet(List<ConnectivityResult> results) async {
    // مفيش شبكة خالص
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      _updateStatus(false);
      return;
    }

    // فيه شبكة → نتاكد من ان فيه نت حقيقي
    final hasInternet = await _hasRealInternet();
    _updateStatus(hasInternet);
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      notifyListeners();
      debugPrint("Internet status: $_isConnected");
    }
  }

  Future<void> retry() async {
    final results = await _connectivity.checkConnectivity();
    await _checkInternet(results);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
