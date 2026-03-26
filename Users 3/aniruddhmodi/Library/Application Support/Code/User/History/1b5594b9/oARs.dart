import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../theme/app_colors.dart';
import '../services/store.dart';
import '../widgets/background_wrapper.dart';
import 'today_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({required this.user, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Store store;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    store = Store();
    store.initializeFirebase(widget.user);
  }

  void _onTabTapped(int index) {
    setState(() => currentIndex = index);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.displayName?.split(' ').first ?? 'friend';
    final currentHour = DateTime.now().hour;
    final greeting = currentHour < 12 ? 'Good morning' : currentHour < 17 ? 'Good afternoon' : 'Good evening';
    
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.1),
          toolbarHeight: 75,
          titleSpacing: 20,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.rosePetal.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.user.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          widget.user.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Search Button
            IconButton(
              icon: Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(store: store),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 0.05);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: curve),
                      );
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
            ),
            // Streak indicator with animation
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: AppColors.roseDeep, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    '${store.streak}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BackgroundWrapper(
          child: SafeArea(
            child: IndexedStack(
              index: currentIndex,
              children: [
                TodayScreen(store: store),
                CalendarScreen(store: store),
                StatsScreen(store: store),
                SettingsScreen(store: store),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: currentIndex,
          height: 60,
          backgroundColor: Colors.transparent,
          color: AppColors.surface.withValues(alpha: 0.95),
          buttonBackgroundColor: AppColors.sage,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 500),
          items: <Widget>[
            Icon(Icons.edit_note, size: 26, color: AppColors.textPrimary),
            Icon(Icons.calendar_month_outlined, size: 26, color: AppColors.textPrimary),
            Icon(Icons.bar_chart_rounded, size: 26, color: AppColors.textPrimary),
            Icon(Icons.settings_outlined, size: 26, color: AppColors.textPrimary),
          ],
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
