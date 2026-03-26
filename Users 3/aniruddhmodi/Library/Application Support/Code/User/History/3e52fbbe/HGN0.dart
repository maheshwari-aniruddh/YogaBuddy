import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_colors.dart';
import '../models/journal_entry.dart';
import '../services/store.dart';
import '../widgets/dark_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/video_player_widget.dart';
import 'today_screen.dart';

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
                    Text('Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMMM yyyy').format(_selectedDay), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 24),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              weekendStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              weekendTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              selectedDecoration: BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.sage.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 3))],
              ),
              todayDecoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          
          if (entry == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.edit_note, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No entry for this day', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 16)),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Add Entry',
                      icon: Icons.add,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
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
                                  color: AppColors.surface.withValues(alpha: 0.9),
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
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 0.1);
                              const end = Offset.zero;
                              const curve = Curves.easeOutCubic;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(parent: animation, curve: curve),
                              );
                              var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
                                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                              );
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: FadeTransition(
                                  opacity: fadeAnimation,
                                  child: ScaleTransition(
                                    scale: scaleAnimation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 450),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text(DateFormat('EEE, MMM d').format(entry.date), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('Mood: ${entry.mood}/5', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (entry.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: entry.tags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Text('#$tag', style: TextStyle(fontSize: 10, color: AppColors.primaryDark)),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (entry.isStarred)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
                              child: const Icon(Icons.star, color: Colors.white, size: 16),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: ModalRoute.of(context)!.animation!,
                                    curve: Curves.easeOutBack,
                                  ),
                                  child: FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: ModalRoute.of(context)!.animation!,
                                      curve: Curves.easeOut,
                                    ),
                                    child: AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('Delete Entry?', style: TextStyle(color: AppColors.textPrimary)),
                                      content: Text('This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.pop(context);
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Delete', style: TextStyle(color: AppColors.roseDeep)),
                                          onPressed: () {
                                            HapticFeedback.mediumImpact();
                                            widget.store.deleteEntry(entry.date);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Entry deleted'), backgroundColor: AppColors.textSecondary),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (entry.good.isNotEmpty) ...[
                    Text('Good:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9BB09D))),
                    const SizedBox(height: 4),
                    Text(entry.good, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                  ],
                  if (entry.bad.isNotEmpty) ...[
                    Text('Challenge:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFD88A8F))),
                    const SizedBox(height: 4),
                    Text(entry.bad, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                  ],
                  Text('Gratitude:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(entry.gratitude, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  
                  // Photo Display
                  if (entry.photoPath != null && entry.photoPath!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: entry.photoPath!.startsWith('http')
                          ? Image.network(entry.photoPath!, fit: BoxFit.cover, width: double.infinity, height: 200)
                          : Image.file(File(entry.photoPath!), fit: BoxFit.cover, width: double.infinity, height: 200),
                    ),
                  ],

                  // Video Display
                  if (entry.videoPath != null && entry.videoPath!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Video Memory:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
