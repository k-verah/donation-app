import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/use_cases/donations/confirm_pickup_donation.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class PickupDonationProvider extends ChangeNotifier {
  final ConfirmPickupDonation confirmPickup;
  PickupDonationProvider(this.confirmPickup);

  /// IDs de donaciones seleccionadas por el usuario
  final Set<String> _selectedDonationIds = {};

  Set<String> get selectedDonationIds => Set.unmodifiable(_selectedDonationIds);

  void toggleDonation(String donationId) {
    if (_selectedDonationIds.contains(donationId)) {
      _selectedDonationIds.remove(donationId);
    } else {
      _selectedDonationIds.add(donationId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedDonationIds.clear();
    notifyListeners();
  }

  bool isSelected(String donationId) =>
      _selectedDonationIds.contains(donationId);

  Future<String?> onConfirm({
    required GeoPoint location,
    required DateTime date,
    required String time,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in first.';

    if (_selectedDonationIds.isEmpty) {
      return 'Please select at least one donation.';
    }

    try {
      final pickup = PickupDonation(
        id: const Uuid().v4(),
        uid: uid,
        location: location,
        date: date,
        time: time,
        donationIds: _selectedDonationIds.toList(),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
      );
      await confirmPickup(pickup);
      _selectedDonationIds.clear();
      notifyListeners();
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not book pickup.';
    } catch (_) {
      return 'Unexpected error.';
    }
  }
}
