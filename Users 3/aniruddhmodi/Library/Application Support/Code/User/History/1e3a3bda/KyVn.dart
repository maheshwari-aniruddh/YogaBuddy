import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

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
  late Animation<double> _pulseAnimation;

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(RoundMoodButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _playSelectionAnimation();
    }
  }

  Future<void> _playSelectionAnimation() async {
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = widget.selected ? _pulseAnimation.value : _scaleAnimation.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected ? moodColor : AppColors.surface.withValues(alpha: 0.9),
                border: Border.all(
                  color: widget.selected ? moodColor : AppColors.border,
                  width: widget.selected ? 3 : 2,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.4),
                          blurRadius: 12 + (_controller.value * 8),
                          offset: const Offset(0, 4),
                          spreadRadius: _controller.value * 2,
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
          );
        },
      ),
    );
  }
}
