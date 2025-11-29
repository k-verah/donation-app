import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';

class ScheduleDonationDatasource {
  final FirebaseFirestore db;
  ScheduleDonationDatasource(this.db);

  DocumentReference<Map<String, dynamic>> newDoc(String id) =>
      db.collection('schedule_donations').doc(id);

  Map<String, dynamic> toMap(ScheduleDonation d) => {
        'uid': d.uid,
        'foundationPointId': d.foundationPointId,
        'date': Timestamp.fromDate(d.date),
        'time': d.time,
        'notes': d.notes,
        'donationIds': d.donationIds,
        'createdAt': FieldValue.serverTimestamp(),
        'isDelivered': d.isDelivered,
        'deliveredAt':
            d.deliveredAt != null ? Timestamp.fromDate(d.deliveredAt!) : null,
      };
}
