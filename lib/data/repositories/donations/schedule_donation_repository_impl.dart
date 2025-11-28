import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/datasources/analytics/analytics_donation_pickup_datasource.dart';
import 'package:donation_app/data/datasources/donations/booking_datasource.dart';
import 'package:donation_app/data/datasources/donations/schedule_donation_datasource.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/repositories/donations/schedule_donation_repository.dart';

class ScheduleDonationRepositoryImpl implements ScheduleDonationRepository {
  final FirebaseFirestore db;
  final BookingDatasource bookingDS;
  final ScheduleDonationDatasource donationDS;
  final AnalyticsRemoteDatasource analyticsDS;

  ScheduleDonationRepositoryImpl(
      this.db, this.bookingDS, this.donationDS, this.analyticsDS);

  @override
  Future<void> confirmSchedule(ScheduleDonation d) async {
    final docDonation = donationDS.newDoc(d.id);
    final docDay = bookingDS.dayDoc(d.uid, d.date);
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

      tx.set(docDonation, donationDS.toMap(d));

      tx.set(
          docDay,
          {
            'uid': d.uid,
            'dayKey': bookingDS.dayKey(d.date),
            'scheduleId': d.id,
            'pickupId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      tx.set(docAnalytics, analyticsDS.incSchedule(), SetOptions(merge: true));
    });
  }
}
