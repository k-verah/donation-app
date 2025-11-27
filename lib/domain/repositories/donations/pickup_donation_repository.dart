import 'package:donation_app/domain/entities/donations/pickup_donation.dart';

abstract class PickupDonationRepository {
  Future<void> confirmPickup(PickupDonation p);
}
