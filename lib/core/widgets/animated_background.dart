// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:servino_client/core/theme/colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background color
        Container(color: Theme.of(context).scaffoldBackgroundColor),

        // Animated Orb 1 (Primary/Blue)
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) {
            return Positioned(
              top: -100 + (100 * _animation1.value),
              left: -50 + (50 * _animation1.value),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isDark
                              ? const Color.fromARGB(255, 82, 13, 161)
                              : AppColors.primary)
                          .withOpacity(isDark ? 0.15 : 0.3),
                ),
              ),
            );
          },
        ),

        // Animated Orb 2 (Secondary/Green -> Teal/Green)
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) {
            return Positioned(
              top: 200 - (100 * _animation2.value),
              right: -100 + (50 * _animation2.value),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.teal[800]! : AppColors.secondary)
                      .withOpacity(isDark ? 0.1 : 0.2),
                ),
              ),
            );
          },
        ),

        // Animated Orb 3 (Accent/Pink -> Purple)
        AnimatedBuilder(
          animation: _animation3,
          builder: (context, child) {
            return Positioned(
              bottom: -50 + (100 * _animation3.value),
              left: 50 + (100 * _animation3.value),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.purple[900]! : AppColors.accent)
                      .withOpacity(isDark ? 0.1 : 0.15),
                ),
              ),
            );
          },
        ),

        // Glassmorphism Blur Effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
