import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/datasources/donations/donations_datasource.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/repositories/donations/donations_repository.dart';

class DonationsRepositoryImpl implements DonationsRepository {
  final DonationsDataSource _ds;
  DonationsRepositoryImpl(this._ds);

  @override
  Future<void> createDonation({
    required String uid,
    required DonationInput input,
  }) async {
    final map = {
      'uid': uid,
      'description': input.description,
      'type': input.type,
      'size': input.size,
      'brand': input.brand,
      'tags': input.tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _ds.create(map);
  }

  @override
  Stream<List<Donation>> streamByUid(String uid) {
    return _ds.streamByUid(uid).map((snap) {
      return snap.docs.map((d) {
        final m = d.data();
        final ts = m['createdAt'];
        final createdAt = (ts is Timestamp) ? ts.toDate() : DateTime.now();
        return Donation(
          id: d.id,
          uid: m['uid'] ?? '',
          description: m['description'] ?? '',
          type: m['type'] ?? '',
          size: m['size'] ?? '',
          brand: m['brand'] ?? '',
          tags: List<String>.from(m['tags'] ?? const []),
          createdAt: createdAt,
          localImagePath: m['localImagePath'],
        );
      }).toList();
    });
  }
}
