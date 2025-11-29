import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';

class DonationInput {
  final String description;
  final String type;
  final String size;
  final String brand;
  final List<String> tags;
  final String? localImagePath;

  DonationInput({
    required this.description,
    required this.type,
    required this.size,
    required this.brand,
    required this.tags,
    this.localImagePath,
  });
}

abstract class DonationsRepository {
  Future<void> createDonation({
    required String uid,
    required DonationInput input,
  });

  Stream<List<Donation>> streamByUid(String uid);

  /// Actualiza el completionStatus de una donación en Firebase
  Future<void> updateCompletionStatus(
    String donationId,
    DonationCompletionStatus status,
  );

  /// Actualiza el completionStatus de múltiples donaciones en Firebase
  Future<void> updateMultipleCompletionStatus(
    List<String> donationIds,
    DonationCompletionStatus status,
  );
}
