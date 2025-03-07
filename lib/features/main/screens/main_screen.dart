import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';
import '../../character_pool/screens/character_pool_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CharacterPoolScreen(),
    const ProfileScreen(),
  ];

  int _getPageIndex(int navIndex) {
    if (navIndex == 3) return 2;
    return navIndex;
  }

  int _getNavIndex(int pageIndex) {
    if (pageIndex == 2) return 3;
    return pageIndex;
  }

  void _openImmersiveMode() {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, animation, secondaryAnimation) {
        return const OnboardingScreen();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final size = MediaQuery.of(context).size;

        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: scaleAnimation.value,
                  child: SizedBox(
                    height: size.height,
                    width: size.width,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getNavIndex(_currentIndex),
        onDestinationSelected: (index) {
          if (index == 2) {
            _openImmersiveMode();
          } else {
            setState(() {
              _currentIndex = _getPageIndex(index);
            });
          }
        },
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '角色池',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                Icon(
                  Icons.view_in_ar_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            selectedIcon: Icon(
              Icons.view_in_ar_outlined,
              color: theme.colorScheme.primary,
            ),
            label: '沉浸',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
