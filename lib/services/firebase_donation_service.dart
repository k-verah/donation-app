import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDonationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<int?> getDaysSinceLastDonation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('⚠️ UID nulo, no hay usuario autenticado');
      return null;
    }

    print('📡 Consultando donaciones para UID: $uid');
    try {
      final snap = await _db
          .collection('donations')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      print('📦 Documentos encontrados: ${snap.docs.length}');
      if (snap.docs.isEmpty) {
        print('❌ No se encontraron donaciones para este UID');
        return null;
      }

      final data = snap.docs.first.data();
      print('🧾 Data encontrada: $data');

      final createdAt = data['createdAt'];
      if (createdAt == null) {
        print('⚠️ Campo createdAt nulo');
        return null;
      }

      final lastDonation = (createdAt as Timestamp).toDate();
      final diff = DateTime.now().difference(lastDonation).inDays;
      print('📆 Última donación: $lastDonation → Han pasado $diff días');
      return diff;
    } catch (e, st) {
      print('🔥 Error al consultar donaciones: $e');
      print(st);
      return null;
    }
  }
}