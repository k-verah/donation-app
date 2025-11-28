import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDatasource {
  final FirebaseFirestore db;
  BookingDatasource(this.db);

  String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String bookingDocId(String uid, DateTime d) => '${uid}_${dayKey(d)}';

  DocumentReference<Map<String, dynamic>> dayDoc(String uid, DateTime d) =>
      db.collection('user_day_bookings').doc(bookingDocId(uid, d));
}
