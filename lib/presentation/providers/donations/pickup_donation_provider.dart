import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/use_cases/donations/confirm_pickup.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class PickupProvider extends ChangeNotifier {
  final ConfirmPickup confirmPickup;
  PickupProvider(this.confirmPickup);

  Future<String?> onConfirm({
    required GeoPoint location,
    required DateTime date,
    required String time,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in first.';
    try {
      final pickup = PickupDonation(
        id: const Uuid().v4(),
        uid: uid,
        location: location,
        date: date,
        time: time,
      );
      await confirmPickup(pickup);
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not book pickup.';
    } catch (_) {
      return 'Unexpected error.';
    }
  }
}
