import 'package:donation_app/domain/repositories/donations/donations_repository.dart';

class CreateDonation {
  final DonationsRepository repo;
  CreateDonation(this.repo);

  Future<void> call({required String uid, required DonationInput input}) =>
      repo.createDonation(uid: uid, input: input);
}
