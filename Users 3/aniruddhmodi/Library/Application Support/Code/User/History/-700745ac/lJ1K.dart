import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOTP(String phoneNumber) async {
    // Implement OTP sending logic here, or leave empty if not needed
    throw UnimplementedError('sendOTP not implemented');
  }

  Future<void> verifyOTP(String otp) async {
    // Implement OTP verification logic here, or leave empty if not needed
    throw UnimplementedError('verifyOTP not implemented');
  }
}
