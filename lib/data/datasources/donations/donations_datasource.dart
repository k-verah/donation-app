import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';

class DonationsDataSource {
  final FirebaseFirestore db;
  DonationsDataSource(this.db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      db.collection('donations');

  Future<String> create(Map<String, dynamic> data) async {
    // Asegurar que completionStatus esté incluido
    data['completionStatus'] ??= DonationCompletionStatus.available.toJson();
    final doc = await _collection.add(data);
    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamByUid(String uid) {
    return _collection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Actualiza el completionStatus de una donación en Firebase
  Future<void> updateCompletionStatus(
    String donationId,
    DonationCompletionStatus status,
  ) async {
    await _collection.doc(donationId).update({
      'completionStatus': status.toJson(),
    });
  }

  /// Actualiza el completionStatus de múltiples donaciones en Firebase
  /// Usa batch write para eficiencia
  Future<void> updateMultipleCompletionStatus(
    List<String> donationIds,
    DonationCompletionStatus status,
  ) async {
    if (donationIds.isEmpty) return;

    final batch = db.batch();
    for (final id in donationIds) {
      batch.update(_collection.doc(id), {
        'completionStatus': status.toJson(),
      });
    }
    await batch.commit();
  }
}
