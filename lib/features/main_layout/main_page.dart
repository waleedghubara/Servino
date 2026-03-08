// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/typography.dart';
import '../home/home_page.dart';
import '../favorites/favorites_page.dart';
import '../booking/my_bookings_page.dart';
import '../profile/profile_page.dart';
import '../../core/ads/widgets/banner_ad_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = const [
    HomePage(),
    MyBookingsPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String activeIcon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.primaryColor.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.primaryColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: SvgPicture.asset(
                    selected ? activeIcon : icon,
                    height: 25,
                    color: selected
                        ? theme.primaryColor
                        : isDarkMode
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: AppTypography.labelMedium.copyWith(
                  color: selected
                      ? theme.primaryColor
                      : isDarkMode
                      ? Colors.white
                      : Colors.grey[600],
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(
                  label.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A subtle gradient background + elevated rounded navigation bar
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.secondary.withOpacity(0.03),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                children: _pages,
              ),
            ),
          ),

          // Custom bottom navigation bar + Banner Ad
          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BannerAdWidget(),

                  Material(
                    color: Theme.of(context).cardColor,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).cardColor,
                            Theme.of(context).cardColor.withOpacity(0.98),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Assets.home,
                            activeIcon: Assets.homeAt,
                            label: 'nav_home',
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Assets.booking,
                            activeIcon: Assets.bookingAt,
                            label: 'nav_bookings',
                          ),
                          _buildNavItem(
                            index: 2,
                            icon: Assets.favorite,
                            activeIcon: Assets.favoriteAt,
                            label: 'nav_favorites',
                          ),
                          _buildNavItem(
                            index: 3,
                            icon: Assets.person,
                            activeIcon: Assets.personAt,
                            label: 'nav_profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
