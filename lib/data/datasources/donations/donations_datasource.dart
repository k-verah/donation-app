import 'package:cloud_firestore/cloud_firestore.dart';

class DonationsDataSource {
  final FirebaseFirestore db;
  DonationsDataSource(this.db);

  Future<String> create(Map<String, dynamic> data) async {
    final doc = await db.collection('donations').add(data);
    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamByUid(String uid) {
    return db
        .collection('donations')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
