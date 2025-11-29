import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';

class PickupDonation {
  final String id;
  final String uid;
  final GeoPoint location;
  final DateTime date;
  final String time;
  final List<String> donationIds;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final bool isDelivered;
  final DateTime? deliveredAt;

  const PickupDonation({
    required this.id,
    required this.uid,
    required this.location,
    required this.date,
    required this.time,
    required this.donationIds,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    this.isDelivered = false,
    this.deliveredAt,
  });

  PickupDonation copyWith({
    String? id,
    GeoPoint? location,
    DateTime? date,
    String? time,
    List<String>? donationIds,
    SyncStatus? syncStatus,
    bool? isDelivered,
    DateTime? deliveredAt,
  }) =>
      PickupDonation(
        id: id ?? this.id,
        uid: uid,
        location: location ?? this.location,
        date: date ?? this.date,
        time: time ?? this.time,
        donationIds: donationIds ?? this.donationIds,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt,
        isDelivered: isDelivered ?? this.isDelivered,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );

  /// Serializa a JSON para SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'lat': location.lat,
        'lng': location.lng,
        'date': date.millisecondsSinceEpoch,
        'time': time,
        'donationIds': donationIds,
        'syncStatus': syncStatus.toJson(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isDelivered': isDelivered,
        'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      };

  /// Deserializa desde JSON de SharedPreferences
  factory PickupDonation.fromJson(Map<String, dynamic> json) => PickupDonation(
        id: json['id'] as String,
        uid: json['uid'] as String,
        location: GeoPoint(
          json['lat'] as double,
          json['lng'] as double,
        ),
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        time: json['time'] as String,
        donationIds: List<String>.from(json['donationIds'] as List? ?? []),
        syncStatus: SyncStatusExtension.fromJson(
            json['syncStatus'] as String? ?? 'synced'),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        isDelivered: json['isDelivered'] as bool? ?? false,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'] as int)
            : null,
      );
}
