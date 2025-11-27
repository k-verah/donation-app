import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleDonationDatasource {
  final FirebaseFirestore db;
  ScheduleDonationDatasource(this.db);

  String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String scheduleDocId(String uid, DateTime d) => '${uid}_${dayKey(d)}';
  DocumentReference<Map<String, dynamic>> dayDoc(String uid, DateTime d) =>
      db.collection('user_day_schedule').doc(bookingDocId(uid, d));
}
