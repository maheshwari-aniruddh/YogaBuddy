library the_30sec_journal;

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
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Service imports
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
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
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF242424);
  static const primary = Color(0xFF4A90E2);
  static const primaryDark = Color(0xFF2E5C8A);
  static const textPrimary = Color(0xFFE0E0E0);
  static const textSecondary = Color(0xFF888888);
  static const accent = Color(0xFF5B9FD8);
  static const border = Color(0xFF2A2A2A);
}

class MoodColors {
  static const List<Color> colors = [
    Color(0xFF8B4545),
    Color(0xFFB87333),
    Color(0xFF9B9B6B),
    Color(0xFF6B8E6B),
    Color(0xFF4A8B6B),
  ];

  static Color getColor(int mood) => colors[mood - 1];
}

// -------- Background Wrapper Widget --------
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/wallpaper.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.background, // fallback color
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
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

  final List<List<Color>> _moodGradients = [
    [Color(0xFFEF5350), Color(0xFFE53935)],
    [Color(0xFFFF7043), Color(0xFFFF5722)],
    [Color(0xFFFFCA28), Color(0xFFFFA726)],
    [Color(0xFF66BB6A), Color(0xFF4CAF50)],
    [Color(0xFF26A69A), Color(0xFF00897B)],
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
    final gradientColors = _moodGradients[widget.mood - 1];
    
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.selected
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: widget.selected ? Colors.transparent : AppColors.border,
              width: widget.selected ? 3 : 2,
            ),
            color: widget.selected ? null : AppColors.surface.withOpacity(0.9),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Container(
            margin: widget.selected ? const EdgeInsets.all(3) : EdgeInsets.zero,
            decoration: widget.selected
                ? BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Center(
              child: Text(
                _getEmoji(widget.mood),
                style: const TextStyle(fontSize: 28),
              ),
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
    this.gradientColors = const [Color(0xFF4A90E2), Color(0xFF2E5C8A)],
    this.height = 50,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
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
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
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
            color: Colors.black.withOpacity(0.3),
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Add friendly greeting using the user's displayName
          title: Text(
            'Hello, ${widget.user.displayName ?? 'friend'}',
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
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
          color: AppColors.surface.withOpacity(0.9),
          buttonBackgroundColor: AppColors.primary,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 500),
          items: const <Widget>[
            Icon(Icons.edit_note, size: 26, color: Colors.white),
            Icon(Icons.calendar_month_outlined, size: 26, color: Colors.white),
            Icon(Icons.bar_chart_rounded, size: 26, color: Colors.white),
            Icon(Icons.settings_outlined, size: 26, color: Colors.white),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '30-Sec Journal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '30-Sec Journal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
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
                gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
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
                          gradient: LinearGradient(colors: [MoodColors.getColor(entry.mood), MoodColors.getColor(entry.mood).withOpacity(0.6)]),
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
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), shape: BoxShape.circle),
                          child: const Icon(Icons.star, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (entry.good.isNotEmpty) ...[
                    const Text('Good:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B8E6B))),
                    const SizedBox(height: 4),
                    Text(entry.good, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                  ],
                  if (entry.bad.isNotEmpty) ...[
                    const Text('Challenge:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB87333))),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 80),
      child: Column(
        children: [
          DarkCard(
            padding: const EdgeInsets.all(12),
            child: const Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ),
          DarkCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(icon: Icons.local_fire_department_outlined, label: 'Streak', value: '${store.streak}', gradientColors: const [Color(0xFFB87333), Color(0xFF8B5A2B)]),
                _StatCard(icon: Icons.mood_outlined, label: 'Avg', value: store.avgMood.toStringAsFixed(1), gradientColors: const [Color(0xFF4A90E2), Color(0xFF2E5C8A)]),
                _StatCard(icon: Icons.edit_note_outlined, label: 'Entries', value: '${store.all.length}', gradientColors: const [Color(0xFF6B8E6B), Color(0xFF4A6E4A)]),
              ],
            ),
          ),
          if (moodData.isNotEmpty)
            DarkCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.show_chart, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Mood Over Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 160,
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
                            gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]),
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppColors.primary, strokeWidth: 1.5, strokeColor: AppColors.surface)),
                            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradientColors;

  const _StatCard({required this.icon, required this.label, required this.value, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))]),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: gradientColors[0])),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// -------- Settings Screen --------
class SettingsScreen extends StatelessWidget {
  final Store store;
  const SettingsScreen({required this.store, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 80),
      child: Column(
        children: [
          DarkCard(
            padding: const EdgeInsets.all(12),
            child: const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ),
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.download_outlined, color: Colors.white, size: 18),
                  ),
                  title: const Text('Export Data', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: const Text('Save as JSON', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                  onTap: () {
                    final json = store.exportJson();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data exported'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.primary));
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B8E6B), Color(0xFF4A6E4A)]), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  ),
                  title: const Text('About', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: const Text('Version 1.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '30-Sec Journal',
                      applicationVersion: '1.0',
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
      title: '30-Sec Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),
      home: const AuthWrapper(),
    );
  }
}
