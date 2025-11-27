import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/datasources/analytics/analytics_donation_pickup_datasource.dart';
import 'package:donation_app/data/datasources/donations/booking_remote_datasource.dart';
import 'package:donation_app/data/datasources/donations/pickup_remote_datasource.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/repositories/donations/pickup_donation_repository.dart';

class PickupRepositoryImpl implements PickupDonationRepository {
  final FirebaseFirestore db;
  final BookingRemoteDatasource bookingDS;
  final PickupRemoteDatasource pickupDS;
  final AnalyticsRemoteDatasource analyticsDS;

  PickupRepositoryImpl(
      this.db, this.bookingDS, this.pickupDS, this.analyticsDS);

  @override
  Future<void> confirmPickup(PickupDonation p) async {
    final docPickup = pickupDS.newDoc(p.id);
    final docDay = bookingDS.dayDoc(p.uid, p.date);
    final docAnalytics = analyticsDS.globalDoc();

    await db.runTransaction((tx) async {
      final daySnap = await tx.get(docDay);
      if (daySnap.exists) {
        final data = daySnap.data()!;
        final hasSchedule = (data['scheduleId'] ?? '') is String &&
            (data['scheduleId'] ?? '') != '';
        final hasPickup = (data['pickupId'] ?? '') is String &&
            (data['pickupId'] ?? '') != '';
        if (hasSchedule || hasPickup) {
          throw FirebaseException(
              plugin: 'firestore', message: 'Already booked for this day.');
        }
      }

      tx.set(docPickup, pickupDS.toMap(p));

      tx.set(
          docDay,
          {
            'uid': p.uid,
            'dayKey': bookingDS.dayKey(p.date),
            'scheduleId': null,
            'pickupId': p.id,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      tx.set(docAnalytics, analyticsDS.incPickup(), SetOptions(merge: true));
    });
  }
}
