import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOTP(String phoneNumber, {void Function()? onCodeSent, BuildContext? context}) async {
    print('sendOTP called for $phoneNumber');
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('verificationCompleted: auto-verifying...');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('verificationFailed: ${e.message}');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OTP Error: ${e.message ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('codeSent: verificationId=$verificationId');
          _verificationId = verificationId;
          if (onCodeSent != null) onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('codeAutoRetrievalTimeout: verificationId=$verificationId');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fatal OTP error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<UserCredential> verifyOTP(String smsCode) async {
    print('verifyOTP called with code: $smsCode');
    if (_verificationId == null) {
      print('No verificationId. Call sendOTP first.');
      throw Exception('No verificationId. Call sendOTP first.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
