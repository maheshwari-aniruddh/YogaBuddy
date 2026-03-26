import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// -------- Firestore Service --------
class FirestoreService {
  final User user;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService(this.user);

  // Stream for listening to journal entries
  Stream<QuerySnapshot> streamEntries() {
    return _db.collection('journals').doc(user.uid).collection('entries').snapshots();
  }

  // Save journal entry with merge to prevent data loss
  Future<void> saveEntry(Map<String, dynamic> data, String dateKey) async {
    await _db
        .collection('journals')
        .doc(user.uid)
        .collection('entries')
        .doc(dateKey)
        .set(data, SetOptions(merge: true));
  }
}