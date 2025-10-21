import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/repositories/donations/donations_repository.dart';
import 'package:donation_app/domain/use_cases/create_donation.dart';
import 'package:donation_app/domain/use_cases/stream_user_donations.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationProvider extends ChangeNotifier {
  final CreateDonation _createDonation;
  final StreamUserDonations _streamUserDonations;
  final FirebaseAuth _auth;

  DonationProvider({
    required CreateDonation createDonation,
    required StreamUserDonations streamUserDonations,
    FirebaseAuth? auth,
  })  : _createDonation = createDonation,
        _streamUserDonations = streamUserDonations,
        _auth = auth ?? FirebaseAuth.instance;

  bool _saving = false;
  bool get saving => _saving;

  Stream<List<Donation>>? donationsStream;

  void startUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      donationsStream = null;
      notifyListeners();
      return;
    }
    donationsStream = _streamUserDonations(uid);
    notifyListeners();
  }

  /// Calcula racha (streak) con base en la lista recibida del stream
  int streakFrom(List<Donation> list) {
    if (list.isEmpty) return 0;
    final days = <DateTime>{};
    for (final d in list) {
      final local = d.createdAt.toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    // permitir racha si fue ayer
    if (streak == 0 &&
        days.contains(DateTime(now.year, now.month, now.day - 1))) {
      streak = 1;
      cursor = DateTime(
        now.year,
        now.month,
        now.day - 1,
      ).subtract(const Duration(days: 1));
      while (days.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  Future<void> create({
    required String description,
    required String type,
    required String size,
    required String brand,
    required List<String> tags,
    String? localImagePath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _saving = true;
    notifyListeners();
    try {
      final input = DonationInput(
        description: description,
        type: type,
        size: size,
        brand: brand,
        tags: tags,
        localImagePath: localImagePath,
      );
      await _createDonation(uid: uid, input: input);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
