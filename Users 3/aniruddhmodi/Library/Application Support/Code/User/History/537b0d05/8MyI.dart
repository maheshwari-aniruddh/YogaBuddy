part of the_30sec_journal;

class TodayScreen extends StatefulWidget {
  final Store store;
  const TodayScreen({required this.store, super.key});

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

  void _nextPage() {
    final next = _currentPage + 1;
    if (next <= 3) {
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28), onPressed: () => _onDateChange(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text(DateFormat('EEEE, MMM d').format(_selectedDate), style: const TextStyle(fontSize: 17, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text('$streak day streak 🔥', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 28), onPressed: () => _onDateChange(1)),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              HapticFeedback.lightImpact();
            },
            children: [
              _buildMoodPage(),
              _buildFieldPage('What went well?', _goodController, Icons.thumb_up_outlined, 0),
              _buildFieldPage('What was challenging?', _badController, Icons.psychology_outlined, 1),
              _buildFieldPage('What are you grateful for?', _gratitudeController, Icons.favorite_border, 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodPage() {
    return Center(
      child: SingleChildScrollView(
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
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            _buildSwipeHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldPage(String title, TextEditingController controller, IconData icon, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -400) {
              _prevPage();
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                          color: AppColors.primary.withOpacity(_glowAnimation.value * 0.3),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppColors.surface.withOpacity(0.88),
                      border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: AppColors.primary, size: 28),
                        const SizedBox(height: 12),
                        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                const SizedBox(height: 24),
                if (_currentPage == index + 1) _buildSwipeHint(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeHint() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) => Opacity(opacity: 0.3 + (_glowAnimation.value * 0.4), child: child),
      child: Column(
        children: const [
          Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 32),
          SizedBox(height: 4),
          Text('swipe up', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
