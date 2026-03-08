// ignore_for_file: use_null_aware_elements, use_build_context_synchronously, deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/config/app_config.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/theme/typography.dart';

import '../../core/routes/routes.dart';
import 'package:servino_client/core/cache/cache_helper.dart';
import 'package:servino_client/core/api/end_point.dart';
import 'package:provider/provider.dart';
import '../auth/logic/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final AnimationController _dropController;
  late final Animation<Offset> _dropAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _logoScale = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _logoFade = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _titleFade = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _dropAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _dropController, curve: Curves.elasticOut),
        );

    _dropController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final token = await SecureCacheHelper().getDataString(key: ApiKey.token);
    final onboardingSeen = await SecureCacheHelper().getDataString(
      key: 'onboarding_seen',
    );

    if (token != null) {
      if (!mounted) return;
      await context.read<AuthProvider>().loadUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.main);
    } else {
      if (onboardingSeen == 'true') {
        if (mounted) Navigator.of(context).pushReplacementNamed(Routes.login);
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Widget _buildDotsLoader() {
    final double dotBase = 8.w;
    final double spacing = 10.w;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (value + i * 0.18) % 1.0;
            final pulse =
                0.55 + 0.45 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
            final opacity =
                (0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)))
                    .clamp(0.25, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              width: dotBase * pulse,
              height: dotBase * pulse,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Stack(
              children: [
                if (child != null) child,
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _dropAnimation,
                    child: Lottie.asset(
                      Assets.ramadanSplash,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const Spacer(),

                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      Assets.logoApp,
                      width: 160.w,
                      height: 160.h,
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    'Servino',
                    style: AppTypography.h2.copyWith(
                      fontSize: 28.sp,
                      fontFamily: 'XBFontEng2',
                      fontWeight: FontWeight.normal,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                _buildDotsLoader(),

                const Spacer(),

                Text(
                  AppConfig.appVersion,
                  style: AppTypography.h3.copyWith(
                    fontFamily: 'MAXIGO',
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
