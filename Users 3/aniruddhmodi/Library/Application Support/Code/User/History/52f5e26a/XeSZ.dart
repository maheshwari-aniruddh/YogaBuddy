import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final int mood;
  final String good;
  final String bad;
  final String gratitude;
  final String? videoUrl;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.good,
    required this.bad,
    required this.gratitude,
    this.videoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'mood': mood,
    'good': good,
    'bad': bad,
    'gratitude': gratitude,
    'videoUrl': videoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] ?? 3,
      good: data['good'] ?? '',
      bad: data['bad'] ?? '',
      gratitude: data['gratitude'] ?? '',
      videoUrl: data['videoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User user;

  FirestoreService(this.user);

  CollectionReference get _userJournals =>
      _db.collection('users').doc(user.uid).collection('entries');

  Future<void> saveEntry(JournalEntry entry) async {
    await _userJournals.doc(entry.id).set(entry.toJson());
  }

  Stream<List<JournalEntry>> streamEntries() {
    return _userJournals
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  Future<JournalEntry?> getEntryForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final snapshot = await _userJournals
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return JournalEntry.fromFirestore(snapshot.docs.first);
  }

  Future<void> deleteEntry(String entryId) async {
    await _userJournals.doc(entryId).delete();
  }
}
