import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/use_cases/donations/confirm_schedule_donation.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ScheduleDonationProvider extends ChangeNotifier {
  final ConfirmScheduleDonation confirmSchedule;
  ScheduleDonationProvider(this.confirmSchedule);

  Future<String?> onConfirm({
    required String title,
    required DateTime date,
    String? time,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in first.';
    try {
      final donation = ScheduleDonation(
        id: const Uuid().v4(),
        uid: uid,
        title: title,
        date: date,
        time: time,
        notes: notes,
      );
      await confirmSchedule(donation);
      return null; // éxito
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not schedule.';
    } catch (_) {
      return 'Unexpected error.';
    }
  }
}
