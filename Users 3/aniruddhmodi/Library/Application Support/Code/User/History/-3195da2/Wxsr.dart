library roze;

import 'dart:math';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Service imports
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'screens/login_screen.dart';

part 'screens/today_screen.dart';

void main() async {
  print('main() started'); // <-- Add this line
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseError;
  try {
    await Firebase.initializeApp();
    // --- Firebase test: try reading a dummy Firestore collection ---
    final snapshot = await FirebaseFirestore.instance.collection('test').get();
    print('Firestore test: Success, ${snapshot.size} docs found in "test" collection.');
  } catch (e) {
    print('Firestore test: ERROR - $e');
    firebaseError = e.toString();
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
    print('Notification service initialized');
  } catch (e) {
    print('Notification service error: $e');
  }

  runApp(MyApp(firebaseError: firebaseError));
}

// -------- Models --------
class JournalEntry {
  DateTime date;
  int mood;
  String good;
  String bad;
  String gratitude;
  DateTime createdAt;
  String? videoPath;
  bool isStarred;

  JournalEntry({
    required this.date,
    required this.mood,
    required this.good,
    required this.bad,
    required this.gratitude,
    DateTime? createdAt,
    this.videoPath,
    this.isStarred = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'mood': mood,
        'good': good,
        'bad': bad,
        'gratitude': gratitude,
        'createdAt': Timestamp.fromDate(createdAt),
        'videoPath': videoPath,
        'isStarred': isStarred,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        date: (json['date'] as Timestamp).toDate(),
        mood: json['mood'],
        good: json['good'],
        bad: json['bad'],
        gratitude: json['gratitude'],
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        videoPath: json['videoPath'],
        isStarred: json['isStarred'] ?? false,
      );

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);
}

// -------- Daily Prompts --------
class DailyPrompts {
  static final List<String> prompts = [
    "What made you smile today?",
    "Describe a moment you felt proud of yourself",
    "What's something you learned recently?",
    "Write about a person who inspires you",
    "What would make tomorrow amazing?",
    "Describe your perfect morning routine",
    "What's a challenge you overcame?",
    "Write about a place that brings you peace",
    "What are you looking forward to?",
    "Describe a recent act of kindness you witnessed",
  ];

  static String getRandomPrompt() {
    return prompts[Random().nextInt(prompts.length)];
  }
}

// -------- Store with Firebase Integration --------
class Store extends ChangeNotifier {
  final Map<DateTime, JournalEntry> _entries = {};
  FirestoreService? _firestoreService;
  StorageService? _storageService;

  void initializeFirebase(User user) {
    _firestoreService = FirestoreService(user);
    _storageService = StorageService(user);
    _loadEntriesFromFirestore();
  }

  void _loadEntriesFromFirestore() {
    _firestoreService?.streamEntries().listen(
      (snapshot) {
        _entries.clear();
        for (var doc in snapshot.docs) {
          final entry = JournalEntry.fromJson(doc.data() as Map<String, dynamic>);
          _entries[DateUtils.dateOnly(entry.date)] = entry;
        }
        notifyListeners();
      },
      onError: (error) {
        // Show a SnackBar or log the error
        print('Firestore stream error: $error');
        // Optionally, notify listeners so UI can show an error
        notifyListeners();
        // You can also set a variable like _firestoreError and show it in your UI
      },
    );
  }

  List<JournalEntry> get all => _entries.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<JournalEntry> get starred => all.where((e) => e.isStarred).toList();
  
  int get entriesCount => _entries.length;

  JournalEntry? forDay(DateTime date) => _entries[DateUtils.dateOnly(date)];

  Future<void> save(JournalEntry entry) async {
    _entries[DateUtils.dateOnly(entry.date)] = entry;
    
    if (_firestoreService != null) {
      await _firestoreService!.saveEntry(entry.toJson(), entry.dateKey);
    }
    
    notifyListeners();
  }

  Future<void> saveWithVideo(JournalEntry entry, File? videoFile) async {
    if (videoFile != null && _storageService != null) {
      final videoUrl = await _storageService!.uploadVideo(videoFile);
      entry.videoPath = videoUrl;
    }
    await save(entry);
  }

  void toggleStar(DateTime date) {
    final entry = forDay(date);
    if (entry != null) {
      entry.isStarred = !entry.isStarred;
      save(entry);
    }
  }

  int get streak {
    final dates = _entries.keys.toList()..sort();
    if (dates.isEmpty) return 0;
    int count = 1;
    for (int i = dates.length - 1; i > 0; i--) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  double get avgMood {
    if (_entries.isEmpty) return 3.0;
    return _entries.values.map((e) => e.mood).reduce((a, b) => a + b) / _entries.length;
  }

  int get totalWords {
    return _entries.values.fold(
        0,
        (sum, entry) =>
            sum +
            entry.good.split(' ').length +
            entry.bad.split(' ').length +
            entry.gratitude.split(' ').length);
  }

  double get thisWeekAvg {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = _entries.values
        .where((e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1))))
        .toList();
    if (thisWeek.isEmpty) return 3.0;
    return thisWeek.map((e) => e.mood).reduce((a, b) => a + b) / thisWeek.length;
  }

  List<FlSpot> getMoodChartData() {
    final sorted = all.reversed.take(30).toList();
    return List.generate(sorted.length, (index) {
      return FlSpot(index.toDouble(), sorted[index].mood.toDouble());
    });
  }

  Map<int, int> getMoodDistribution() {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var entry in _entries.values) {
      distribution[entry.mood] = (distribution[entry.mood] ?? 0) + 1;
    }
    return distribution;
  }

  String exportJson() {
    // This exports all journal entries as JSON, including the video URL (videoPath).
    // The actual video file is stored in Firebase Storage and can be downloaded using the URL.
    return jsonEncode(_entries.values.map((e) => e.toJson()).toList());
  }
}

// -------- Colors --------
class AppColors {
  // Rose-themed pastel colors inspired by watercolor rose
  static const background = Color(0xFFFAF7F5);
  static const surface = Color(0xFFFFF5F7);
  static const surfaceLight = Color(0xFFFFE4E8);
  static const primary = Color(0xFFE8A5A5);
  static const primaryDark = Color(0xFFD88A8F);
  static const textPrimary = Color(0xFF5C4A4F);
  static const textSecondary = Color(0xFF9B8A8E);
  static const accent = Color(0xFFF4C2C2);
  static const border = Color(0xFFE8D5D5);
  static const roseDeep = Color(0xFFC97A7E);
  static const rosePetal = Color(0xFFFAD2D3);
  static const sage = Color(0xFFB5C5B0);
  static const cream = Color(0xFFFFF9F5);
}

class MoodColors {
  static const List<Color> colors = [
    Color(0xFFD88A8F), // Terrible - deeper rose
    Color(0xFFE8A5A5), // Bad - rose
    Color(0xFFF4C2C2), // Okay - light rose
    Color(0xFFB5C5B0), // Good - sage green
    Color(0xFF9BB09D), // Great - deeper sage
  ];

  static Color getColor(int mood) => colors[mood - 1];
}

// -------- Background Wrapper Widget --------
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: child,
    );
  }
}

// -------- ROUND MOOD BUTTON WITH COLOR GRADIENTS --------
class RoundMoodButton extends StatefulWidget {
  final int mood;
  final bool selected;
  final VoidCallback onTap;

  const RoundMoodButton({
    required this.mood,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  State<RoundMoodButton> createState() => _RoundMoodButtonState();
}

class _RoundMoodButtonState extends State<RoundMoodButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Use solid colors instead of gradients
  final List<Color> _moodColors = [
    Color(0xFFD88A8F), // Terrible - deeper rose
    Color(0xFFE8A5A5), // Bad - rose
    Color(0xFFF4C2C2), // Okay - light rose
    Color(0xFFB5C5B0), // Good - sage green
    Color(0xFF9BB09D), // Great - deeper sage
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  String _getEmoji(int mood) {
    const emojis = ['😢', '🙁', '😐', '😊', '😁'];
    return emojis[mood - 1];
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColors[widget.mood - 1];
    
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selected ? moodColor : AppColors.surface.withOpacity(0.9),
            border: Border.all(
              color: widget.selected ? moodColor : AppColors.border,
              width: widget.selected ? 3 : 2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: moodColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _getEmoji(widget.mood),
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// -------- Gradient Button --------
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color> gradientColors;
  final double height;

  const GradientButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradientColors = const [Color(0xFFE8A5A5), Color(0xFFD88A8F)],
    this.height = 50,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Fix: VideoPlayerWidget that supports both local file and network URL ---
class VideoPlayerWidget extends StatefulWidget {
  final File? videoFile;
  final String? networkUrl;
  const VideoPlayerWidget({this.videoFile, this.networkUrl, super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    if (widget.networkUrl != null && widget.networkUrl!.isNotEmpty) {
      _controller = VideoPlayerController.network(widget.networkUrl!);
    } else if (widget.videoFile != null) {
      _controller = VideoPlayerController.file(widget.videoFile!);
    } else {
      throw Exception('No video source provided');
    }
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sage.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
      },
    );
  }
}

// -------- Text Field --------
class DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final int? maxLength;
  final VoidCallback? onSubmitted;

  const DarkTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.maxLength,
    this.onSubmitted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface.withOpacity(0.85),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          if (onSubmitted != null) onSubmitted!();
        },
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          counterText: '',
        ),
      ),
    );
  }
}

// -------- Card --------
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const DarkCard({
    required this.child,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface.withOpacity(0.85),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// -------- Auth Wrapper --------
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _showTransition = false;
  User? _user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // FIX: Remove 'const' from SplashScreen()
          return SplashScreen();
        }
        if (snapshot.hasData) {
          if (_showTransition) {
            return JournalTransitionScreen(
              onDone: () => setState(() => _showTransition = false),
            );
          }
          if (_user == null || _user?.uid != snapshot.data?.uid) {
            _user = snapshot.data;
            _showTransition = true;
            Future.delayed(const Duration(milliseconds: 100), () => setState(() {}));
            return JournalTransitionScreen(
              onDone: () => setState(() => _showTransition = false),
            );
          }
          // FIX: Make sure MainScreen is defined above
          return MainScreen(user: snapshot.data!);
        }
        // Show the new LoginScreen (moved Google sign-in logic into screens/login_screen.dart)
        return const LoginScreen();
      },
    );
  }
}

// -------- Main Screen --------
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
          shadowColor: AppColors.primary.withOpacity(0.1),
          toolbarHeight: 75,
          titleSpacing: 20,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.rosePetal.withOpacity(0.3),
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
                      color: AppColors.primary.withOpacity(0.3),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
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
            // Streak indicator with animation
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.accent.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: AppColors.roseDeep, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    '${store.streak}',
                    style: const TextStyle(
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
          color: AppColors.surface.withOpacity(0.95),
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

// -------- Splash Screen --------
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Roze',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Reflect • Record • Remember',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------- Journal Transition Screen --------
class JournalTransitionScreen extends StatefulWidget {
  final VoidCallback onDone;
  const JournalTransitionScreen({required this.onDone, super.key});
  @override
  State<JournalTransitionScreen> createState() => _JournalTransitionScreenState();
}

class _JournalTransitionScreenState extends State<JournalTransitionScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Roze',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Loading your journal...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------- Today Screen --------
// Moved to screens/today_screen.dart (part file).

// -------- Calendar Screen --------
class CalendarScreen extends StatefulWidget {
  final Store store;
  const CalendarScreen({required this.store, super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.store.forDay(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMMM yyyy').format(_selectedDay), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TableCalendar<JournalEntry>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 24),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              weekendStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              weekendTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              selectedDecoration: BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.sage.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          
          if (entry == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.edit_note, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No entry for this day', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 16)),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Add Entry',
                      icon: Icons.add,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              backgroundColor: Colors.transparent,
                              extendBody: true,
                              body: BackgroundWrapper(  
                                child: SafeArea(
                                  child: TodayScreen(store: widget.store, initialDate: _selectedDay),
                                ),
                              ),
                              bottomNavigationBar: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.9),
                                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                                    const SizedBox(width: 8),
                                    Text('New Entry', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            DarkCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MoodColors.getColor(entry.mood),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mood, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('EEE, MMM d').format(entry.date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('Mood: ${entry.mood}/5', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (entry.isStarred)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
                          child: const Icon(Icons.star, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (entry.good.isNotEmpty) ...[
                    const Text('Good:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9BB09D))),
                    const SizedBox(height: 4),
                    Text(entry.good, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                  ],
                  if (entry.bad.isNotEmpty) ...[
                    const Text('Challenge:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD88A8F))),
                    const SizedBox(height: 4),
                    Text(entry.bad, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                  ],
                  const Text('Gratitude:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(entry.gratitude, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  if (entry.videoPath != null && entry.videoPath!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Video:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    if (entry.videoPath!.startsWith('http'))
                      SizedBox(height: 200, child: VideoPlayerWidget(networkUrl: entry.videoPath))
                    else
                      VideoPlayerWidget(videoFile: File(entry.videoPath!)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -------- Stats Screen --------
class StatsScreen extends StatelessWidget {
  final Store store;
  const StatsScreen({required this.store, super.key});

  @override
  Widget build(BuildContext context) {
    final moodData = store.getMoodChartData();
    final distribution = store.getMoodDistribution();
    final entries = store.all;
    final now = DateTime.now();
    
    // Calculate advanced statistics
    final thisWeekEntries = entries.where((e) => 
      now.difference(e.date).inDays < 7
    ).length;
    
    final thisMonthEntries = entries.where((e) => 
      e.date.year == now.year && e.date.month == now.month
    ).length;
    
    final bestMoodDay = entries.isEmpty ? null : entries.reduce((a, b) => a.mood > b.mood ? a : b);
    final worstMoodDay = entries.isEmpty ? null : entries.reduce((a, b) => a.mood < b.mood ? a : b);
    
    final avgWordsPerEntry = entries.isEmpty ? 0 : store.totalWords / entries.length;
    
    final lastWeekMoods = entries.where((e) => now.difference(e.date).inDays < 7).map((e) => e.mood).toList();
    final lastWeekAvg = lastWeekMoods.isEmpty ? 0.0 : lastWeekMoods.reduce((a, b) => a + b) / lastWeekMoods.length;
    
    final prevWeekMoods = entries.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 7 && diff < 14;
    }).map((e) => e.mood).toList();
    final prevWeekAvg = prevWeekMoods.isEmpty ? 0.0 : prevWeekMoods.reduce((a, b) => a + b) / prevWeekMoods.length;
    
    final moodTrend = lastWeekAvg - prevWeekAvg;
    final moodTrendIcon = moodTrend > 0 ? Icons.trending_up : (moodTrend < 0 ? Icons.trending_down : Icons.trending_flat);
    final moodTrendColor = moodTrend > 0 ? AppColors.sage : (moodTrend < 0 ? AppColors.roseDeep : AppColors.textSecondary);

    final starredCount = store.starred.length;
    final videoCount = entries.where((e) => e.videoPath != null && e.videoPath!.isNotEmpty).length;
    
    final longestStreak = _calculateLongestStreak(entries);
    final daysJournaled = entries.length;
    final totalDaysSinceFirst = entries.isEmpty ? 0 : now.difference(entries.last.date).inDays + 1;
    final consistencyRate = totalDaysSinceFirst == 0 ? 0.0 : (daysJournaled / totalDaysSinceFirst) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 80),
      child: Column(
        children: [
          // Header with trend
          DarkCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Journey', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: moodTrendColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: moodTrendColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(moodTrendIcon, size: 16, color: moodTrendColor),
                          const SizedBox(width: 4),
                          Text(
                            moodTrend > 0 ? '+${moodTrend.toStringAsFixed(1)}' : moodTrend.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: moodTrendColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  moodTrend > 0 
                    ? "You're on an upward trend! Keep it up! 🌟" 
                    : moodTrend < 0 
                      ? "Things seem tough. Remember, tomorrow is a new day 💪"
                      : "You're maintaining steady wellness 🌸",
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          
          // Main stats grid
          DarkCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _DetailedStatCard(
                      icon: Icons.local_fire_department_outlined, 
                      label: 'Current Streak', 
                      value: '${store.streak}',
                      subtitle: 'Longest: $longestStreak days',
                      color: AppColors.primary,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _DetailedStatCard(
                      icon: Icons.mood_outlined, 
                      label: 'Average Mood', 
                      value: store.avgMood.toStringAsFixed(1),
                      subtitle: 'Last 7 days: ${lastWeekAvg.toStringAsFixed(1)}',
                      color: AppColors.sage,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _DetailedStatCard(
                      icon: Icons.edit_note_outlined, 
                      label: 'Total Entries', 
                      value: '${entries.length}',
                      subtitle: 'This month: $thisMonthEntries',
                      color: AppColors.accent,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _DetailedStatCard(
                      icon: Icons.percent_outlined, 
                      label: 'Consistency', 
                      value: '${consistencyRate.toStringAsFixed(0)}%',
                      subtitle: '$daysJournaled of $totalDaysSinceFirst days',
                      color: AppColors.roseDeep,
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Mood Distribution Pie Chart
          if (distribution.values.any((v) => v > 0))
            DarkCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.pie_chart, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Mood Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...distribution.entries.map((entry) {
                    final mood = entry.key;
                    final count = entry.value;
                    final percentage = entries.isEmpty ? 0.0 : (count / entries.length) * 100;
                    final moodLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Great'];
                    final moodEmojis = ['😢', '🙁', '😐', '😊', '😁'];
                    
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(moodEmojis[mood - 1], style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(moodLabels[mood - 1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text('${percentage.toStringAsFixed(0)}% ($count)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: AppColors.border,
                                        valueColor: AlwaysStoppedAnimation(MoodColors.getColor(mood)),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Mood Over Time Chart
          if (moodData.isNotEmpty)
            DarkCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.show_chart, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Mood Trend (Last 30 Days)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1)),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)), reservedSize: 25)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: moodData.length.toDouble() - 1,
                        minY: 0,
                        maxY: 6,
                        lineBarsData: [
                          LineChartBarData(
                            spots: moodData,
                            isCurved: true,
                            color: AppColors.sage,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: AppColors.sage, strokeWidth: 2, strokeColor: AppColors.surface)),
                            belowBarData: BarAreaData(show: true, color: AppColors.sage.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Insights & Highlights
          DarkCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Insights & Highlights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 14),
                
                _InsightRow(icon: Icons.star, label: 'Starred Entries', value: '$starredCount', color: const Color(0xFFFFD700)),
                _InsightRow(icon: Icons.videocam, label: 'Video Memories', value: '$videoCount', color: AppColors.sage),
                _InsightRow(icon: Icons.text_fields, label: 'Avg Words/Entry', value: avgWordsPerEntry.toStringAsFixed(0), color: AppColors.primary),
                _InsightRow(icon: Icons.calendar_today, label: 'This Week', value: '$thisWeekEntries entries', color: AppColors.accent),
                
                if (bestMoodDay != null) ...[
                  const Divider(height: 24, color: AppColors.border),
                  _HighlightRow(
                    icon: Icons.emoji_emotions,
                    label: 'Best Day',
                    date: bestMoodDay.date,
                    mood: bestMoodDay.mood,
                    color: AppColors.sage,
                  ),
                ],
                
                if (worstMoodDay != null && worstMoodDay.date != bestMoodDay?.date) ...[
                  const SizedBox(height: 8),
                  _HighlightRow(
                    icon: Icons.sentiment_dissatisfied,
                    label: 'Tough Day',
                    date: worstMoodDay.date,
                    mood: worstMoodDay.mood,
                    color: AppColors.roseDeep,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateLongestStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    
    final dates = entries.map((e) => DateUtils.dateOnly(e.date)).toSet().toList()..sort();
    int longest = 1;
    int current = 1;
    
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i-1]).inDays == 1) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 1;
      }
    }
    
    return longest;
  }
}

class _DetailedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _DetailedStatCard({
    required this.icon, 
    required this.label, 
    required this.value, 
    required this.subtitle,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final int mood;
  final Color color;

  const _HighlightRow({required this.icon, required this.label, required this.date, required this.mood, required this.color});

  String _getMoodEmoji(int mood) => ['😢', '🙁', '😐', '😊', '😁'][mood - 1];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        Text(_getMoodEmoji(mood), style: const TextStyle(fontSize: 24)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// -------- Settings Screen --------
class SettingsScreen extends StatefulWidget {
  final Store store;
  const SettingsScreen({required this.store, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _weeklyReview = false;
  bool _darkModeEnabled = false;
  bool _hapticFeedback = true;
  bool _autoSave = true;
  double _fontSize = 16.0;
  String _selectedTheme = 'Rose';

  Future<void> _launchWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://roze-blooms-journal.lovable.app/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open website')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening website: $e')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppColors.sage,
        ),
      );
    }
  }

  void _showExportDialog(BuildContext context) {
    final json = widget.store.exportJson();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.download_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Export Data', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your journal data has been exported as JSON.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entries exported:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.store.entriesCount} total entries',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.sage)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data copied to clipboard'),
                  backgroundColor: AppColors.sage,
                ),
              );
            },
            child: const Text('Copy JSON'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user profile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.15), AppColors.accent.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preferences Section
          _buildSectionTitle('Preferences', Icons.tune),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.primary,
                  title: 'Push Notifications',
                  subtitle: 'Receive reminders and updates',
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.alarm,
                  iconColor: AppColors.accent,
                  title: 'Daily Reminder',
                  subtitle: 'Get reminded to journal daily',
                  value: _dailyReminder,
                  onChanged: (val) => setState(() => _dailyReminder = val),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.calendar_today,
                  iconColor: AppColors.sage,
                  title: 'Weekly Review',
                  subtitle: 'Summary of your week',
                  value: _weeklyReview,
                  onChanged: (val) => setState(() => _weeklyReview = val),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.vibration,
                  iconColor: AppColors.roseDeep,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrations for interactions',
                  value: _hapticFeedback,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.save_outlined,
                  iconColor: AppColors.primaryDark,
                  title: 'Auto-Save',
                  subtitle: 'Automatically save entries',
                  value: _autoSave,
                  onChanged: (val) => setState(() => _autoSave = val),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionTitle('Appearance', Icons.palette_outlined),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.color_lens_outlined, color: Colors.white, size: 20),
                  ),
                  title: const Text('Theme', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(_selectedTheme, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _showThemePicker(context),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.text_fields, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Text Size',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('A', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 12.0,
                              max: 24.0,
                              divisions: 6,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.border,
                              onChanged: (val) => setState(() => _fontSize = val),
                            ),
                          ),
                          const Text('A', style: TextStyle(fontSize: 20, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data & Privacy Section
          _buildSectionTitle('Data & Privacy', Icons.security_outlined),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.download_outlined, color: Colors.white, size: 20),
                  ),
                  title: const Text('Export Data', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Save your journal as JSON', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.backup_outlined, color: Colors.white, size: 20),
                  ),
                  title: const Text('Backup & Sync', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Cloud backup with Firebase', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active', style: TextStyle(color: AppColors.sage, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                  title: const Text('Clear Cache', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Free up storage space', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared successfully'),
                        backgroundColor: AppColors.sage,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Support & Info Section
          _buildSectionTitle('Support & Info', Icons.help_outline),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  ),
                  title: const Text('Learn More', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Visit our website', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _launchWebsite(context),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 20),
                  ),
                  title: const Text('Rate Us', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Love Roze? Leave a review', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your support! 💖'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  title: const Text('About', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Roze',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      children: const [
                        Text(
                          'A beautiful journal app for daily reflections, mood tracking, and gratitude practice.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [AppColors.roseDeep, AppColors.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.roseDeep.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _logout(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Text(
              'Made with 💖 by the Roze team',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.accent,
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Theme', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Rose', AppColors.primary, Icons.local_florist),
            _buildThemeOption('Lavender', const Color(0xFFB5A5E8), Icons.spa),
            _buildThemeOption('Ocean', const Color(0xFFA5C9E8), Icons.water),
            _buildThemeOption('Forest', const Color(0xFFA5E8B0), Icons.park),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Theme changed successfully'),
                  backgroundColor: AppColors.sage,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String name, Color color, IconData icon) {
    final isSelected = _selectedTheme == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = name),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// ----- Add MyApp so runApp(MyApp(...)) is defined -----
class MyApp extends StatelessWidget {
  final String? firebaseError;
  const MyApp({this.firebaseError, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: false,
        primaryColor: AppColors.primary,
      ),
      home: const AuthWrapper(),
    );
  }
}
