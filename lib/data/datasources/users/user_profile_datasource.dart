import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileDataSource {
  final FirebaseFirestore _db;
  UserProfileDataSource(this._db);

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
    required String city,
    required List<String> interests,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'city': city,
      'interests': interests,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
