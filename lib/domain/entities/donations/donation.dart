import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';

class Donation {
  final String? id;
  final String uid;
  final String description;
  final String type;
  final String size;
  final String brand;
  final List<String> tags;
  final DateTime createdAt;
  final String? localImagePath;
  final SyncStatus syncStatus;
  final DonationCompletionStatus completionStatus;

  Donation({
    this.id,
    required this.uid,
    required this.description,
    required this.type,
    required this.size,
    required this.brand,
    required this.tags,
    required this.createdAt,
    this.localImagePath,
    this.syncStatus = SyncStatus.synced,
    this.completionStatus = DonationCompletionStatus.available,
  });

  Donation copyWith({
    String? id,
    SyncStatus? syncStatus,
    DonationCompletionStatus? completionStatus,
  }) =>
      Donation(
        id: id ?? this.id,
        uid: uid,
        description: description,
        type: type,
        size: size,
        brand: brand,
        tags: tags,
        createdAt: createdAt,
        localImagePath: localImagePath,
        syncStatus: syncStatus ?? this.syncStatus,
        completionStatus: completionStatus ?? this.completionStatus,
      );

  /// Serializa a JSON para SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'description': description,
        'type': type,
        'size': size,
        'brand': brand,
        'tags': tags,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'localImagePath': localImagePath,
        'syncStatus': syncStatus.toJson(),
        'completionStatus': completionStatus.toJson(),
      };

  /// Deserializa desde JSON de SharedPreferences
  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        id: json['id'] as String?,
        uid: json['uid'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        size: json['size'] as String,
        brand: json['brand'] as String,
        tags: List<String>.from(json['tags'] as List),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        localImagePath: json['localImagePath'] as String?,
        syncStatus: SyncStatusExtension.fromJson(
            json['syncStatus'] as String? ?? 'synced'),
        completionStatus: DonationCompletionStatusExtension.fromJson(
            json['completionStatus'] as String?),
      );
}
