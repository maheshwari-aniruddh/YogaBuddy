part of the_30sec_journal;

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
  int _mood = 3;
  File? _videoFile;
  bool _isStarred = false;

  late PageController _pageController;
  Timer? _autoSaveTimer;
  DateTime _selectedDate = DateTime.now();
  JournalEntry? _currentEntry;
  int _currentPage = 0;

  late AnimationController _glowController;
  late AnimationController _slideController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _glowController.repeat(reverse: true);

    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _goodController.addListener(_onTextChanged);
    _badController.addListener(_onTextChanged);
    _gratitudeController.addListener(_onTextChanged);

    // Initialize with passed date or today
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadEntryFor(_selectedDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    _autoSaveTimer?.cancel();
    _goodController.dispose();
    _badController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    final entry = JournalEntry(
      date: DateUtils.dateOnly(_selectedDate),
      mood: _mood,
      good: _goodController.text.trim(),
      bad: _badController.text.trim(),
      gratitude: _gratitudeController.text.trim(),
      isStarred: _isStarred,
      createdAt: _currentEntry?.createdAt,
      videoPath: _currentEntry?.videoPath,
    );
    await widget.store.saveWithVideo(entry, _videoFile);
    _currentEntry = entry;
  }

  Future<void> _saveManually() async {
    // FIX: Ensure we save before checking mounted
    try {
      await _autoSave();
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
      return; // Don't navigate if save failed
    }
    
    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved!'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
      // FIX: Use a delay before popping to ensure Firestore write completes
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null) {
        setState(() => _videoFile = File(video.path));
        await _autoSave();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video added!'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleStar() {
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
        _isStarred = entry.isStarred;
      } else {
        _mood = 3;
        _goodController.clear();
        _badController.clear();
        _gratitudeController.clear();
        _isStarred = false;
      }
    });
  }

  void _onDateChange(int offsetDays) {
    _loadEntryFor(_selectedDate.add(Duration(days: offsetDays)));
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
                      Text(DateFormat('EEEE, MMM d').format(_selectedDate), style: const TextStyle(fontSize: 17, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$streak day streak 🔥', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                _buildFieldPage('What went well?', _goodController, Icons.thumb_up_outlined, 0),
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
                          color: MoodColors.getColor(_mood).withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 60 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withOpacity(0.3),
                        border: Border.all(color: MoodColors.getColor(_mood).withOpacity(0.5), width: 2),
                      ),
                      child: Center(child: Text(_emojiForMood(_mood), style: const TextStyle(fontSize: 72))),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('How are you feeling?', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
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
                                gradient: selected
                                    ? LinearGradient(
                                        colors: [
                                          MoodColors.getColor(mood),
                                          MoodColors.getColor(mood).withOpacity(0.7),
                                        ],
                                      )
                                    : null,
                                color: selected ? null : AppColors.surface.withOpacity(0.5),
                                border: Border.all(
                                  color: selected ? MoodColors.getColor(mood) : AppColors.border,
                                  width: selected ? 3 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _emojiForMood(mood),
                                  style: TextStyle(fontSize: selected ? 28 : 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _moodLabel(mood),
                              style: TextStyle(
                                fontSize: 10,
                                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    });
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

  // Different colors for each field
  Widget _buildFieldPage(String title, TextEditingController controller, IconData icon, int index) {
    final Color iconColor;
    final Color borderColor;
    final Color glowColor;
    
    switch (index) {
      case 0: // Good
        iconColor = const Color(0xFF9BB09D);
        borderColor = const Color(0xFFB5C5B0);
        glowColor = const Color(0xFF9BB09D);
        break;
      case 1: // Challenge
        iconColor = const Color(0xFFD88A8F);
        borderColor = const Color(0xFFE8A5A5);
        glowColor = const Color(0xFFD88A8F);
        break;
      case 2: // Gratitude
        iconColor = const Color(0xFFE8A5A5);
        borderColor = const Color(0xFFF4C2C2);
        glowColor = const Color(0xFFE8A5A5);
        break;
      default:
        iconColor = AppColors.primary;
        borderColor = AppColors.primary;
        glowColor = AppColors.primary;
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
              padding: EdgeInsets.fromLTRB(28, constraints.maxHeight * 0.15, 28, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(_glowAnimation.value * 0.2),
                            blurRadius: 30 * _glowAnimation.value,
                            spreadRadius: 3 * _glowAnimation.value,
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
                          color: AppColors.surface.withOpacity(0.88),
                          border: Border.all(color: borderColor.withOpacity(0.35), width: 2),
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
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
                              decoration: InputDecoration(
                                hintText: 'Type here...',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.55), fontSize: 14),
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(_glowAnimation.value * 0.4),
                          blurRadius: 35 * _glowAnimation.value,
                          spreadRadius: 6 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withOpacity(0.3),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                      ),
                      child: const Icon(Icons.check_circle, size: 56, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Almost done!', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                
                // Star toggle button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleStar,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isStarred ? const Color(0xFFFFD700) : AppColors.border, width: 2),
                        color: AppColors.surface.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isStarred ? Icons.star : Icons.star_border, color: _isStarred ? const Color(0xFFFFD700) : AppColors.textSecondary, size: 28),
                          const SizedBox(width: 12),
                          Text(_isStarred ? 'Starred!' : 'Star this day', style: TextStyle(fontSize: 16, color: _isStarred ? const Color(0xFFFFD700) : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Video button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _recordVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _videoFile != null ? AppColors.primary : AppColors.border, width: 2),
                        color: AppColors.surface.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_videoFile != null ? Icons.videocam : Icons.videocam_outlined, color: _videoFile != null ? AppColors.primary : AppColors.textSecondary, size: 28),
                          const SizedBox(width: 12),
                          Text(_videoFile != null ? 'Video added!' : 'Add 30s video', style: TextStyle(fontSize: 16, color: _videoFile != null ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Save button - FIX: Don't auto-pop, let _saveManually handle it
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Save Entry', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _saveManually, // FIX: This now handles navigation internally
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

  Widget _buildSwipeHint({required bool isLast}) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) => Opacity(opacity: 0.3 + (_glowAnimation.value * 0.4), child: child),
      child: Column(
        children: [
          Icon(isLast ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 4),
          Text(isLast ? 'swipe up' : 'swipe down', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
