// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class SecurityBlockerApp extends StatefulWidget {
  const SecurityBlockerApp({super.key});

  @override
  State<SecurityBlockerApp> createState() => _SecurityBlockerAppState();
}

class _SecurityBlockerAppState extends State<SecurityBlockerApp>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _rotationController;
  int _secondsLeft = 15;
  final int _totalSeconds = 15;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    // 🚀 تشغيل التايمر تلقائياً عند فتح التطبيق
    _startCountdown();
  }

  void _startCountdown() {
    _rotationController.repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsLeft--;
        });

        if (_secondsLeft <= 0) {
          _closeApp();
        }
      }
    });
  }

  void _closeApp() {
    _timer?.cancel();
    _rotationController.stop();
    SystemNavigator.pop();
  }

  Future<void> _openDeveloperOptions() async {
    try {
      const platform = MethodChannel('com.example.app/intent');
      await platform.invokeMethod('openDeveloperOptions');
    } catch (e) {
      // إذا فشل، حاول الطريقة التقليدية
      final intent = AndroidIntent(
        action: 'android.settings.DEVELOPMENT_SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        body: WillPopScope(
          onWillPop: () async => false, // منع الرجوع للخلف
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 110, 7, 0),
                  Color.fromARGB(255, 0, 34, 109),
                  Color.fromARGB(255, 38, 0, 126),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/json/security.json'),
                  const SizedBox(height: 40),
                  Text(
                    'security_alert'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color.fromARGB(255, 255, 17, 0),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'security_alert_message'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 🎯 التايمر الدائري مثل الساعة
                  _buildCircularTimer(),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGradientButton(
                        label: 'تحقق'.tr(),
                        onPressed: _openDeveloperOptions,
                        colors: const [
                          Colors.green,
                          Color.fromARGB(255, 0, 60, 255),
                        ],
                      ),
                      _buildGradientButton(
                        label: 'موافق'.tr(),
                        onPressed: _closeApp,
                        colors: const [
                          Colors.purpleAccent,
                          Color.fromARGB(255, 0, 60, 255),
                          Color.fromARGB(255, 255, 0, 0),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          gradient: LinearGradient(
            colors: colors,
            end: Alignment.bottomLeft,
            begin: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer() {
    final progress = 1 - (_secondsLeft / _totalSeconds);

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الخلفية الدائرية الثابتة
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getTimerColor().withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // شريط التقدم الدائري مع الأنيميشن
          RotatedBox(
            quarterTurns: -1,
            child: SizedBox(
              width: 170,
              height: 170,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          // المركز مع النص
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_secondsLeft',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: _getTimerColor(),
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: _getTimerColor().withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'ثانية'.tr(),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (_secondsLeft > 10) {
      return const Color.fromARGB(255, 4, 252, 45); // أخضر
    } else if (_secondsLeft > 5) {
      return Colors.yellowAccent; // أصفر
    } else {
      return const Color.fromARGB(255, 252, 1, 1); // أحمر
    }
  }
}
