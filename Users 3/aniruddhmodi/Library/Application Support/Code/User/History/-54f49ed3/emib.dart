import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

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
        onCodeSent: () {
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
        context: context, // pass context for error handling
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
      if (cred.user != null) {
        // Success: user is signed in, navigation handled by AuthWrapper
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Login with Phone', style: TextStyle(fontSize: 22, color: Colors.white)),
              const SizedBox(height: 24),
              // Remove phone input field
              const Text(
                'OTP will be sent to +1 669-977-8614',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              if (_otpSent)
                OTPInputField(
                  controller: _otpController,
                  length: 6,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else if (!_otpSent)
                ElevatedButton(
                  onPressed: _sendOTP,
                  child: const Text('Send OTP'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    if (_otpController.text.trim().length != 6) {
                      setState(() => _error = 'Enter 6-digit OTP');
                      return;
                    }
                    _verifyOTP();
                  },
                  child: const Text('Verify OTP'),
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
