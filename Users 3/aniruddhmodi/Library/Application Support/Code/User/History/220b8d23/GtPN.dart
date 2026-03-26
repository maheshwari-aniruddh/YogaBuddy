import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../theme/app_colors.dart';
import '../services/store.dart';
import '../services/notification_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/dark_card.dart';
import 'auth_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  final Store store;
  const SettingsScreen({required this.store, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _autoSaveEnabled = true;
  double _fontSize = 14.0;
  String _selectedTheme = 'Rose';

  @override
  void initState() {
    super.initState();
    // Load preferences here if using SharedPreferences
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _launchWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://example.com');
    if (!await launchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    }
  }

  Future<void> _updateTheme(String themeName) async {
    setState(() {
      _selectedTheme = themeName;
      // In a real app, you'd update AppColors or ThemeProvider here
    });
  }

  Future<void> _exportData() async {
    try {
      final jsonString = widget.store.exportJson();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/roze_journal_backup.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(file.path)], text: 'My Roze Journal Backup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdfService = PdfExportService();
      final file = await pdfService.generateJournalPdf(widget.store.all);
      await Share.shareXFiles([XFile(file.path)], text: 'My Roze Journal PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSectionTitle('Preferences', Icons.tune),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.roseDeep,
                  title: 'Daily Reminders',
                  subtitle: 'Get reminded at 8:00 PM',
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    if (val) {
                      _notificationService.scheduleDailyReminder(hour: 20, minute: 0);
                    } else {
                      _notificationService.cancelAll();
                    }
                  },
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.vibration,
                  iconColor: AppColors.sage,
                  title: 'Haptic Feedback',
                  subtitle: 'Feel interactions',
                  value: _hapticFeedbackEnabled,
                  onChanged: (val) => setState(() => _hapticFeedbackEnabled = val),
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSwitchTile(
                  icon: Icons.save_outlined,
                  iconColor: AppColors.accent,
                  title: 'Auto-Save',
                  subtitle: 'Save entries automatically',
                  value: _autoSaveEnabled,
                  onChanged: (val) => setState(() => _autoSaveEnabled = val),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Appearance', Icons.palette_outlined),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.color_lens_outlined, color: Colors.white, size: 20),
                  ),
                  title: Text('Theme', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(_selectedTheme, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => _showThemePicker(context),
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.dark_mode_outlined, color: Colors.white, size: 20),
                  ),
                  title: Text('Dark Mode', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: Switch(
                    value: AppColors.isDark,
                    onChanged: (val) {
                      HapticFeedback.mediumImpact();
                      // Find the MyApp state and call toggleTheme
                      final myAppState = context.findAncestorStateOfType<State<StatefulWidget>>();
                      if (myAppState != null && myAppState.mounted) {
                        (myAppState as dynamic).toggleTheme?.call();
                      }
                    },
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          _buildSectionTitle('Data & Privacy', Icons.security),
          const SizedBox(height: 8),
          
          DarkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: AppColors.sage,
                  title: 'Export Data (JSON)',
                  onTap: _exportData,
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                _buildSettingsTile(
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: AppColors.roseDeep,
                  title: 'Export as PDF',
                  onTap: _exportPdf,
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  ),
                  title: Text('Test Notification', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Send a test notification now', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () async {
                    await _notificationService.showTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        backgroundColor: AppColors.sage,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                  title: Text('Learn More', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Visit our website', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () => _launchWebsite(context),
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 20),
                  ),
                  title: Text('Rate Us', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Love Roze? Leave a review', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your support! 💖'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                Divider(color: AppColors.border, height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  title: Text('About', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
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
                      children: [
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
                    color: AppColors.roseDeep.withValues(alpha: 0.3),
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
                      children: [
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
                color: AppColors.textSecondary.withValues(alpha: 0.6),
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
            style: TextStyle(
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

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
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
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
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
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.accent,
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Choose Theme', style: TextStyle(color: AppColors.textPrimary)),
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await _updateTheme(_selectedTheme);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme changed to $_selectedTheme'),
                        backgroundColor: AppColors.sage,
                      ),
                    );
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
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
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.cream,
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
