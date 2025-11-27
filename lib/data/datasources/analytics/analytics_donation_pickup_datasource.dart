import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRemoteDatasource {
  final FirebaseFirestore db;
  AnalyticsRemoteDatasource(this.db);

  DocumentReference<Map<String, dynamic>> globalDoc() =>
      db.collection('analytics').doc('global');

  Map<String, dynamic> incSchedule() =>
      {'schedule_confirm_count': FieldValue.increment(1)};
  Map<String, dynamic> incPickup() =>
      {'pickup_confirm_count': FieldValue.increment(1)};
}
