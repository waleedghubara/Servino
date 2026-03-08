import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:app_device_integrity/app_device_integrity.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:servino_client/core/api/api_consumer.dart';
import 'package:servino_client/injection_container.dart';
import 'package:dio/dio.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const _channel = MethodChannel('com.example.app/intent');

  static const bool enableStrictSecurity = true;

  // ===============================
  // Emulator Detection (Improved)
  // ===============================
  Future<bool> isEmulator() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        return !info.isPhysicalDevice ||
            info.fingerprint.contains("generic") ||
            info.model.toLowerCase().contains("sdk") ||
            info.manufacturer.toLowerCase().contains("genymotion");
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        return !info.isPhysicalDevice;
      }
    } catch (_) {}
    return false;
  }

  // ===============================
  // Debug Detection (Stronger)
  // ===============================
  bool isDebuggerConnected() {
    if (kDebugMode) return true;

    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  // ===============================
  // Root / Jailbreak Detection
  // ===============================
  Future<bool> isRooted() async {
    try {
      final jailbroken = await JailbreakRootDetection.instance.isJailBroken;
      return jailbroken;
    } catch (_) {
      return false;
    }
  }

  // ===============================
  // Developer Mode Detection
  // ===============================
  Future<bool> isDeveloperModeEnabled() async {
    try {
      if (Platform.isAndroid) {
        // First check via jailbreak_root_detection (package)
        final bool packageResult =
            await JailbreakRootDetection.instance.isDevMode;
        if (packageResult) return true;

        // Second check via our native platform channel (more reliable)
        final bool nativeResult = await _channel.invokeMethod(
          'checkDeveloperOptions',
        );
        return nativeResult;
      }
    } catch (_) {}
    return false;
  }

  // ===============================
  // USB Debugging Detection
  // ===============================
  Future<bool> isUsbDebuggingEnabled() async {
    try {
      if (Platform.isAndroid) {
        final bool nativeResult = await _channel.invokeMethod(
          'checkAdbEnabled',
        );
        return nativeResult;
      }
    } catch (_) {}
    return false;
  }

  // ===============================
  // Play Integrity (Fail Closed)
  // ===============================
  Future<bool> verifyPlayIntegrity(String nonce) async {
    if (!Platform.isAndroid) return true;

    const int cloudProjectNumber = 696352642194;

    try {
      final token = await AppDeviceIntegrity().getAttestationServiceSupport(
        challengeString: nonce,
        gcp: cloudProjectNumber,
      );

      if (token == null) {
        await _logSecurityEvent("Integrity Token Null");
        return false;
      }

      final response = await sl<ApiConsumer>().post(
        EndPoint.validateIntegrity,
        data: {'integrityToken': token, 'nonce': nonce},
      );

      if (response['status'] == 'success') {
        return true;
      } else {
        await _logSecurityEvent("Integrity Backend Failed");
        return false; // ✅ FIXED
      }
    } catch (e) {
      await _logSecurityEvent("Integrity Exception: $e");
      return false; // Fail closed
    }
  }

  // ===============================
  // SSL Pinning (Strict)
  // ===============================
  Future<void> pinSSL() async {
    if (!enableStrictSecurity) return;

    if (!EndPoint.baseUrl.startsWith("https")) {
      throw Exception("SSL Required. HTTP Not Allowed.");
    }

    List<String> allowedShas = [
      '03:5C:EE:AF:01:6B:46:7A:9A:67:9E:B3:76:DC:3C:5A:9F:A1:FE:A1:A7:4B:A6:C9:5A:B8:CA:EA:03:07:8E:2A',
    ];

    try {
      await HttpCertificatePinning.check(
        serverURL: EndPoint.baseUrl,
        headerHttp: {},
        sha: SHA.SHA256,
        allowedSHAFingerprints: allowedShas,
        timeout: 30,
      );
    } catch (e) {
      await _logSecurityEvent("SSL Pinning Failed: $e");
      throw Exception("Security Violation: SSL Pinning Failed");
    }
  }

  // ===============================
  // Payment Validation (Strict)
  // ===============================
  Future<bool> validatePayment({
    required String receipt,
    required String provider,
    required String transactionId,
  }) async {
    if (await isDeveloperModeEnabled()) {
      await _logSecurityEvent("Payment Blocked - Dev Mode");
      return false;
    }

    try {
      final response = await sl<ApiConsumer>().post(
        EndPoint.validatePayment,
        data: {
          'receipt': receipt,
          'provider': provider,
          'transactionId': transactionId,
        },
      );

      return response['status'] == 'success';
    } catch (e) {
      await _logSecurityEvent("Payment Validation Failed: $e");
      return false;
    }
  }

  // ===============================
  // Master Runtime Check
  // ===============================
  Future<bool> runSecurityChecks() async {
    if (!enableStrictSecurity) return true;

    if (await isEmulator()) {
      await _logSecurityEvent("Emulator Detected");
      return false;
    }

    if (isDebuggerConnected()) {
      await _logSecurityEvent("Debugger Detected");
      return false;
    }

    if (await isRooted()) {
      await _logSecurityEvent("Root Detected");
      return false;
    }

    if (await isDeveloperModeEnabled()) {
      await _logSecurityEvent("Developer Mode Detected");
      return false;
    }

    if (await isUsbDebuggingEnabled()) {
      await _logSecurityEvent("USB Debugging Detected");
      return false;
    }

    // Optional: enforce integrity on startup
    final nonce = DateTime.now().millisecondsSinceEpoch.toString();
    if (!await verifyPlayIntegrity(nonce)) {
      return false;
    }

    return true;
  }

  // ===============================
  // Backend Logging
  // ===============================
  // ===============================
  // Backend Logging
  // ===============================
  Future<void> _logSecurityEvent(String event) async {
    try {
      // Use Dio directly to send custom headers (X-API-KEY)
      await sl<Dio>().post(
        EndPoint.baseUrl +
            EndPoint.securityLog, // Ensure full URL if using Dio directly
        data: {"event": event, "timestamp": DateTime.now().toIso8601String()},
        options: Options(
          headers: {
            'X-API-KEY': 'SERVINO_SECURE_LOG_KEY_2024', // Must match backend
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint("Failed to log security event: $e");
    }
  }
}
