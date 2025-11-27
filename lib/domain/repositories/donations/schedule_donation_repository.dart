import 'package:donation_app/domain/entities/donations/schedule_donation.dart';

abstract class ScheduleDonationRepository {
  Future<void> confirmSchedule(ScheduleDonation d);
}
