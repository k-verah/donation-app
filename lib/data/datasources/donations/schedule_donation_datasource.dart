import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';

class ScheduleDonationDatasource {
  final FirebaseFirestore db;
  ScheduleDonationDatasource(this.db);

  DocumentReference<Map<String, dynamic>> newDoc(String id) =>
      db.collection('schedule_donations').doc(id);

  Map<String, dynamic> toMap(ScheduleDonation d) => {
        'uid': d.uid,
        'title': d.title,
        'date': Timestamp.fromDate(d.date),
        'time': d.time,
        'notes': d.notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
