import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../models/journal_entry.dart';
import '../models/daily_prompts.dart';
import '../services/store.dart';

class TodayScreen extends StatefulWidget {
  final Store store;
  final DateTime? initialDate;
  const TodayScreen({required this.store, this.initialDate, super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with TickerProviderStateMixin {
  final _goodController = TextEditingController();
  final _badController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  int _mood = 3;
  File? _videoFile;
  File? _photoFile;
  bool _isStarred = false;
  String _currentPrompt = "";

  late PageController _pageController;
  Timer? _autoSaveTimer;
  DateTime _selectedDate = DateTime.now();
  JournalEntry? _currentEntry;
  int _currentPage = 0;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _glowController.repeat(reverse: true);

    _goodController.addListener(_onTextChanged);
    _badController.addListener(_onTextChanged);
    _gratitudeController.addListener(_onTextChanged);
    _tagsController.addListener(_onTextChanged);

    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentPrompt = DailyPrompts.getRandomPrompt();
    _loadEntryFor(_selectedDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    _autoSaveTimer?.cancel();
    _goodController.dispose();
    _badController.dispose();
    _gratitudeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    final entry = JournalEntry(
      date: DateUtils.dateOnly(_selectedDate),
      mood: _mood,
      good: _goodController.text.trim(),
      bad: _badController.text.trim(),
      gratitude: _gratitudeController.text.trim(),
      isStarred: _isStarred,
      createdAt: _currentEntry?.createdAt,
      videoPath: _currentEntry?.videoPath,
      photoPath: _currentEntry?.photoPath,
      tags: tagsList,
    );
    
    await widget.store.saveEntryWithMedia(entry, _videoFile, _photoFile);
    _currentEntry = entry;
  }

  Future<void> _saveManually() async {
    try {
      await _autoSave();
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry saved successfully! ✨'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.sage,
          ),
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.roseDeep,
          ),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null) {
        HapticFeedback.lightImpact();
        setState(() => _videoFile = File(video.path));
        await _autoSave();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video added! 🎥'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        HapticFeedback.lightImpact();
        setState(() => _photoFile = File(photo.path));
        await _autoSave();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added! 📸'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  void _toggleStar() {
    HapticFeedback.mediumImpact();
    setState(() => _isStarred = !_isStarred);
    _autoSave();
    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    final next = _currentPage + 1;
    if (next <= 4) {
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      HapticFeedback.mediumImpact();
    }
  }

  void _prevPage() {
    final prev = _currentPage - 1;
    if (prev >= 0) {
      _pageController.animateToPage(prev, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      HapticFeedback.lightImpact();
    }
  }

  void _loadEntryFor(DateTime date) {
    final entry = widget.store.forDay(DateUtils.dateOnly(date));
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _currentEntry = entry;
      if (entry != null) {
        _mood = entry.mood;
        _goodController.text = entry.good;
        _badController.text = entry.bad;
        _gratitudeController.text = entry.gratitude;
        _tagsController.text = entry.tags.join(', ');
        _isStarred = entry.isStarred;
      } else {
        _mood = 3;
        _goodController.clear();
        _badController.clear();
        _gratitudeController.clear();
        _tagsController.clear();
        _isStarred = false;
        _videoFile = null;
        _photoFile = null;
      }
    });
  }

  String _emojiForMood(int mood) => ['😢', '🙁', '😐', '😊', '😁'][mood - 1];
  String _moodLabel(int mood) => ['Terrible', 'Bad', 'Okay', 'Good', 'Great'][mood - 1];

  @override
  Widget build(BuildContext context) {
    final streak = widget.store.streak;
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(DateFormat('EEEE, MMM d').format(_selectedDate), style: TextStyle(fontSize: 17, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$streak day streak 🔥', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                HapticFeedback.lightImpact();
              },
              children: [
                _buildMoodPage(),
                _buildFieldPage('What went well?', _goodController, Icons.thumb_up_outlined, 0, showPrompt: true),
                _buildFieldPage('What was challenging?', _badController, Icons.psychology_outlined, 1),
                _buildFieldPage('What are you grateful for?', _gratitudeController, Icons.favorite_border, 2),
                _buildActionsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPage() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          _nextPage();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) => Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MoodColors.getColor(_mood)
                              .withValues(alpha: _glowAnimation.value * 0.4),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 8 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.5),
                        border: Border.all(
                          color: MoodColors.getColor(_mood).withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _emojiForMood(_mood),
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'How are you feeling?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final mood = index + 1;
                    final selected = _mood == mood;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _mood = mood);
                        HapticFeedback.mediumImpact();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Container(
                              width: selected ? 64 : 50,
                              height: selected ? 64 : 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? MoodColors.getColor(mood)
                                    : AppColors.surface.withValues(alpha: 0.5),
                                border: Border.all(
                                  color: selected
                                      ? MoodColors.getColor(mood)
                                      : AppColors.border,
                                  width: selected ? 3 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _emojiForMood(mood),
                                  style: TextStyle(
                                    fontSize: selected ? 28 : 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _moodLabel(mood),
                              style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                _buildSwipeHint(isLast: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldPage(String title, TextEditingController controller, IconData icon, int index, {bool showPrompt = false}) {
    final Color iconColor;
    final Color backgroundColor;
    
    switch (index) {
      case 0: // Good
        iconColor = const Color(0xFF9BB09D);
        backgroundColor = const Color(0xFFF5F9F4);
        break;
      case 1: // Challenge
        iconColor = const Color(0xFFD88A8F);
        backgroundColor = const Color(0xFFFFF5F6);
        break;
      case 2: // Gratitude
        iconColor = const Color(0xFFE8A5A5);
        backgroundColor = const Color(0xFFFFF9F9);
        break;
      default:
        iconColor = AppColors.primary;
        backgroundColor = AppColors.surface;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -300) {
                _nextPage();
              } else if (details.primaryVelocity! > 300) {
                _prevPage();
              }
            }
          },
          child: Container(
            color: Colors.transparent,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, constraints.maxHeight * 0.1, 28, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPrompt) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Daily Prompt', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _currentPrompt = DailyPrompts.getRandomPrompt());
                                  HapticFeedback.selectionClick();
                                },
                                child: Icon(Icons.refresh, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentPrompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: _glowAnimation.value * 0.15),
                            blurRadius: 20 * _glowAnimation.value,
                            spreadRadius: 2 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: backgroundColor,
                          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: iconColor, size: 28),
                            const SizedBox(height: 12),
                            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: iconColor, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              maxLines: 4,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
                              decoration: InputDecoration(
                                hintText: 'Type here...',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.55), fontSize: 14),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                                HapticFeedback.lightImpact();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage == index + 1) _buildSwipeHint(isLast: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsPage() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          _prevPage();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sage.withValues(alpha: _glowAnimation.value * 0.3),
                          blurRadius: 30 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.5),
                        border: Border.all(color: AppColors.sage.withValues(alpha: 0.6), width: 2),
                      ),
                      child: Icon(Icons.check_circle, size: 48, color: AppColors.sage),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Wrap Up', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        icon: Icon(Icons.tag, color: AppColors.textSecondary, size: 18),
                        hintText: 'Tags (comma separated)',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMediaButton(
                      icon: _photoFile != null || (_currentEntry?.photoPath != null) ? Icons.image : Icons.image_outlined,
                      label: 'Photo',
                      isActive: _photoFile != null || (_currentEntry?.photoPath != null),
                      onTap: _pickPhoto,
                    ),
                    const SizedBox(width: 16),
                    _buildMediaButton(
                      icon: _videoFile != null || (_currentEntry?.videoPath != null) ? Icons.videocam : Icons.videocam_outlined,
                      label: 'Video',
                      isActive: _videoFile != null || (_currentEntry?.videoPath != null),
                      onTap: _recordVideo,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleStar,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isStarred ? Color(0xFFFFD700) : AppColors.border, width: 2),
                        color: _isStarred ? Color(0xFFFFD700).withValues(alpha: 0.1) : AppColors.cream.withValues(alpha: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isStarred ? Icons.star : Icons.star_border, color: _isStarred ? Color(0xFFFFD700) : AppColors.textSecondary, size: 24),
                          const SizedBox(width: 8),
                          Text(_isStarred ? 'Starred' : 'Star Day', style: TextStyle(fontSize: 14, color: _isStarred ? Color(0xFFFFD700) : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.sage,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sage.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveManually,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Save Entry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSwipeHint(isLast: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? AppColors.sage : AppColors.border, width: 2),
            color: isActive ? AppColors.sage.withValues(alpha: 0.1) : AppColors.cream.withValues(alpha: 0.8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? AppColors.sage : AppColors.textSecondary, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: isActive ? AppColors.sage : AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHint({required bool isLast}) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) => Opacity(opacity: 0.3 + (_glowAnimation.value * 0.4), child: child),
      child: Column(
        children: [
          Icon(isLast ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 4),
          Text(isLast ? 'swipe up' : 'swipe down', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
