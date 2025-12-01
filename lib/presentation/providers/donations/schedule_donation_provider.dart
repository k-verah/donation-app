import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/use_cases/donations/confirm_schedule_donation.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ScheduleDonationProvider extends ChangeNotifier {
  final ConfirmScheduleDonation confirmSchedule;
  ScheduleDonationProvider(this.confirmSchedule);

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
    String? foundationPointId,
    required DateTime date,
    String? time,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in first.';

    if (_selectedDonationIds.isEmpty) {
      return 'Please select at least one donation.';
    }

    try {
      final donation = ScheduleDonation(
        id: const Uuid().v4(),
        uid: uid,
        foundationPointId: foundationPointId,
        date: date,
        time: time,
        notes: notes,
        donationIds: _selectedDonationIds.toList(),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
      );
      await confirmSchedule(donation);
      _selectedDonationIds.clear();
      debugPrint('✅ Schedule creado: ${donation.id}');
      notifyListeners();
      return null; // éxito (funciona offline, se sincroniza después)
    } on FirebaseException catch (e) {
      debugPrint('⚠️ Firebase error en schedule: ${e.message}');
      return e.message ?? 'Could not schedule.';
    } catch (e) {
      debugPrint('⚠️ Error en schedule: $e');
      // Si es error de red, el schedule ya se guardó localmente
      if (e.toString().contains('network') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        _selectedDonationIds.clear();
        notifyListeners();
        return null; // Guardado localmente, se sincronizará después
      }
      return 'Unexpected error: $e';
    }
  }
}
