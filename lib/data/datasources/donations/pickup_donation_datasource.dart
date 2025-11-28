import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';

class PickupDonationDatasource {
  final FirebaseFirestore db;
  PickupDonationDatasource(this.db);

  DocumentReference<Map<String, dynamic>> newDoc(String id) =>
      db.collection('pickups').doc(id);

  Map<String, dynamic> toMap(PickupDonation p) => {
        'uid': p.uid,
        'location': GeoPoint(p.location.lat, p.location.lng),
        'date': Timestamp.fromDate(p.date),
        'time': p.time,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
