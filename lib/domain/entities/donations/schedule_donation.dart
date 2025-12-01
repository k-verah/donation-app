import 'package:donation_app/domain/entities/sync/sync_status.dart';

class ScheduleDonation {
  final String id;
  final String uid;
  final String? foundationPointId;
  final DateTime date;
  final String? time;
  final String? notes;
  final List<String> donationIds;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final bool isDelivered;
  final DateTime? deliveredAt;

  const ScheduleDonation({
    required this.id,
    required this.uid,
    this.foundationPointId,
    required this.date,
    this.time,
    this.notes,
    required this.donationIds,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    this.isDelivered = false,
    this.deliveredAt,
  });

  ScheduleDonation copyWith({
    String? id,
    String? foundationPointId,
    DateTime? date,
    String? time,
    String? notes,
    List<String>? donationIds,
    SyncStatus? syncStatus,
    bool? isDelivered,
    DateTime? deliveredAt,
  }) =>
      ScheduleDonation(
        id: id ?? this.id,
        uid: uid,
        foundationPointId: foundationPointId ?? this.foundationPointId,
        date: date ?? this.date,
        time: time ?? this.time,
        notes: notes ?? this.notes,
        donationIds: donationIds ?? this.donationIds,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt,
        isDelivered: isDelivered ?? this.isDelivered,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'foundationPointId': foundationPointId,
        'date': date.millisecondsSinceEpoch,
        'time': time,
        'notes': notes,
        'donationIds': donationIds,
        'syncStatus': syncStatus.toJson(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isDelivered': isDelivered,
        'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      };

  factory ScheduleDonation.fromJson(Map<String, dynamic> json) =>
      ScheduleDonation(
        id: json['id'] as String,
        uid: json['uid'] as String,
        foundationPointId: json['foundationPointId'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        time: json['time'] as String?,
        notes: json['notes'] as String?,
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
