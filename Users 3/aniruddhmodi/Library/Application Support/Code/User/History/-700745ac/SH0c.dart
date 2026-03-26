import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // <-- Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sends an OTP to the given phone number.
  /// Returns when the code is sent.
  Future<void> sendOTP(String phoneNumber) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification (Android only)
        await _auth.signInWithCredential(credential);
        completer.complete();
      },
      verificationFailed: (FirebaseAuthException e) {
        completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  /// Verifies the OTP code entered by the user.
  /// Returns the UserCredential on success.
  Future<UserCredential> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('No verificationId. Call sendOTP first.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Optionally, sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
