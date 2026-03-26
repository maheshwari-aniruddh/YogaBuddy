import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _error = 'Google sign-in cancelled');
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _error = 'Google sign-in failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF9F5),
              const Color(0xFFFFF5F7),
              const Color(0xFFFFE4E8).withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE8A5A5), Color(0xFFD88A8F)]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: const Color(0xFFE8A5A5).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Welcome to Roze', style: TextStyle(fontSize: 28, color: Color(0xFF5C4A4F), fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('Quick reflections. Simple tracking. Private to you.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9B8A8E), fontSize: 14)),
                const SizedBox(height: 20),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFD88A8F))),
                  ),

                if (_loading)
                  const CircularProgressIndicator(color: Color(0xFFE8A5A5))
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8A5A5).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5C4A4F),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Image.asset('assets/images/google_logo.png', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 18)),
                      label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: _signInWithGoogle,
                    ),
                  ),

                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => HapticFeedback.lightImpact(),
                  child: const Text('Learn more', style: TextStyle(color: Color(0xFF9B8A8E))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
