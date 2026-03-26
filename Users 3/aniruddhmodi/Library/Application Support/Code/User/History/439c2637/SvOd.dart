import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Service to handle storage operations with Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  StorageService(User user) {
    // Initialize with user-specific data if needed
  }

  // Upload video to Firebase Storage
  Future<String> uploadVideo(File videoFile) async {
    try {
      // Create a unique file name based on timestamp
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Upload the file to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(videoFile);
      
      // Get the download URL of the uploaded file
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  // Other storage-related methods can be added here
}