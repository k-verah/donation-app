import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/repositories/donations/pickup_donation_repository.dart';

class ConfirmPickupDonation {
  final PickupDonationRepository repo;
  ConfirmPickupDonation(this.repo);
  Future<void> call(PickupDonation p) => repo.confirmPickup(p);
}
