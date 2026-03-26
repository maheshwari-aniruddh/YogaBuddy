import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
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
    _otpController.dispose();
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
        setState(() {
          _error = 'Google sign-in cancelled';
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Auth state stream will handle navigation to MainScreen.
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final phone = '+16699778614'; // hardcoded

    bool codeSent = false;
    try {
      await _authService.sendOTP(
        phone,
        onCodeSent: (msg) {
          codeSent = true;
          setState(() {
            _otpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to +1 669-977-8614'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (err) {
          setState(() {
            _error = err;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        },
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('OTP request timed out. Please check your network and try again.');
      });

      if (!codeSent) {
        setState(() {
          _error = 'OTP could not be sent. Try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP could not be sent. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to send OTP: ${e is Exception ? e.toString() : e}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e is Exception ? e.toString() : e}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await _authService.verifyOTP(_otpController.text.trim());
      if (cred?.user != null) {
        // success: auth stream will navigate
      } else {
        setState(() {
          _error = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Invalid OTP. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
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
                    gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF2E5C8A)]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Welcome to 30-Sec Journal', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Quick reflections. Simple tracking. Private to you.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              // Google Sign-In
              if (_loading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Image.asset('assets/images/google_logo.png', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 18)),
                  label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: _signInWithGoogle,
                ),

              const SizedBox(height: 14),
              const Text('or sign in with phone', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              const Text('OTP will be sent to +1 669-977-8614', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 10),
              if (_otpSent)
                OTPInputField(controller: _otpController, length: 6),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44), backgroundColor: Colors.transparent, side: const BorderSide(color: Colors.white24)),
                      onPressed: _otpSent ? _verifyOTP : _sendOTP,
                      child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPInputField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  const OTPInputField({required this.controller, this.length = 6, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        return Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: TextEditingController(
              text: controller.text.length > i ? controller.text[i] : '',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              counterText: '',
            ),
            onChanged: (val) {
              String text = controller.text;
              if (val.isNotEmpty) {
                if (text.length > i) {
                  text = text.substring(0, i) + val + text.substring(i + 1);
                } else if (text.length == i) {
                  text += val;
                }
                controller.text = text;
                if (i < length - 1) {
                  FocusScope.of(context).nextFocus();
                }
              } else {
                if (text.length > i) {
                  text = text.substring(0, i) + text.substring(i + 1);
                  controller.text = text;
                }
              }
            },
          ),
        );
      }),
    );
  }
}
