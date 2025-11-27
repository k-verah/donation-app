import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/repositories/donations/donations_repository.dart';

class StreamUserDonations {
  final DonationsRepository repo;
  StreamUserDonations(this.repo);

  Stream<List<Donation>> call(String uid) => repo.streamByUid(uid);
}
