import 'package:cloud_firestore/cloud_firestore.dart';

class DonationItem {
  final String? imagePath;
  final String description;
  final String type;
  final String size;
  final String brand;
  final List<String> tags;
  final DateTime createdAt;

  DonationItem({
    this.imagePath,
    required this.description,
    required this.type,
    required this.size,
    required this.brand,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'description': description,
        'type': type,
        'size': size,
        'brand': brand,
        'tags': tags,
        'createdAt': createdAt,
      };

  factory DonationItem.fromMap(Map<String, dynamic> m) => DonationItem(
        imagePath: null,
        description: (m['description'] ?? '') as String,
        type: (m['type'] ?? '') as String,
        size: (m['size'] ?? '') as String,
        brand: (m['brand'] ?? '') as String,
        tags:
            (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        createdAt: (m['createdAt'] is Timestamp)
            ? (m['createdAt'] as Timestamp).toDate()
            : (m['createdAt'] is DateTime)
                ? m['createdAt'] as DateTime
                : DateTime.now(),
      );

  factory DonationItem.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DonationItem.fromMap(data);
  }
}
