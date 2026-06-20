import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/attachment.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  bool _isFirebaseInitialized = false;

  void markInitialized() {
    _isFirebaseInitialized = true;
  }

  // Get current user ID from Firebase Auth
  String? get currentUid {
    if (!_isFirebaseInitialized) return "offline_test_user";
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Check if user is authenticated with Firebase
  bool get isUserLoggedIn {
    if (!_isFirebaseInitialized) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  // Sync a single diary entry to Cloud Firestore (zero-knowledge encrypted payload)
  Future<void> syncEntryToFirestore(DiaryEntry entry) async {
    if (!_isFirebaseInitialized) {
      AppLogger.warning('Firebase not configured. Skipping cloud upload.');
      return;
    }

    final uid = currentUid;
    if (uid == null) throw Exception("User not authenticated with Firebase");

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary_entries')
        .doc(entry.id.toString());

    // Convert entry to map (Title, Content are already encrypted by SQLite layer before reaching here)
    final map = entry.toMap();
    
    // Convert attachments list to map list
    final attachmentsMap = entry.attachments.map((att) => att.toMap()).toList();
    map['attachments'] = attachmentsMap;
    map['SyncedAt'] = FieldValue.serverTimestamp();

    await docRef.set(map, SetOptions(merge: true));
  }

  // Fetch all diary entries from Cloud Firestore for Restore operations
  Future<List<DiaryEntry>> downloadEntriesFromFirestore() async {
    if (!_isFirebaseInitialized) {
      AppLogger.warning('Firebase not configured. Returning empty list.');
      return [];
    }

    final uid = currentUid;
    if (uid == null) throw Exception("User not authenticated with Firebase");

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary_entries')
        .orderBy('EntryDate', descending: true)
        .get();

    List<DiaryEntry> entries = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      
      // Parse attachments list
      final List<dynamic> attListRaw = data['attachments'] as List<dynamic>? ?? [];
      final List<Attachment> attachments = attListRaw.map((attMap) {
        return Attachment.fromMap(Map<String, dynamic>.from(attMap as Map));
      }).toList();

      entries.add(DiaryEntry.fromMap(data, attachments: attachments));
    }

    return entries;
  }

  // Delete diary entry from Cloud Firestore
  Future<void> deleteEntryFromFirestore(int entryId) async {
    if (!_isFirebaseInitialized) return;

    final uid = currentUid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary_entries')
        .doc(entryId.toString())
        .delete();
  }

  // Upload attachment file (image/audio) to Firebase Storage
  Future<String> uploadAttachmentToStorage(String localFilePath, String fileType) async {
    if (!_isFirebaseInitialized) {
      AppLogger.warning('Firebase not configured. Simulating storage URL.');
      return 'https://firebasestorage.googleapis.com/v0/b/ynote-mock/o/${localFilePath.split('/').last}';
    }

    final uid = currentUid;
    if (uid == null) throw Exception("User not authenticated");

    final file = File(localFilePath);
    if (!await file.exists()) throw Exception("Local file does not exist");

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${localFilePath.split('/').last}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child(fileType)
        .child(fileName);

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
