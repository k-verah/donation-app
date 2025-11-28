import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/repositories/donations/schedule_donation_repository.dart';

class ConfirmScheduleDonation {
  final ScheduleDonationRepository repo;
  ConfirmScheduleDonation(this.repo);
  Future<void> call(ScheduleDonation d) => repo.confirmSchedule(d);
}
