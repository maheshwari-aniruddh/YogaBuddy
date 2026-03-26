import 'package:cloud_firestore/cloud_firestore.dart';

// -------- Firestore Service --------
class FirestoreService {
  final User user;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService(this.user);

  // Stream for listening to journal entries
  Stream<QuerySnapshot> streamEntries() {
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('journalEntries')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Save journal entry
  Future<void> saveEntry(Map<String, dynamic> data, String dateKey) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('journalEntries')
        .doc(dateKey)
        .set(data);
  }

  // Other Firestore methods (if any)...
}