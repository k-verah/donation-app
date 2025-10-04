class DonationItem {
  final String imagePath;
  final String description;
  final String type;
  final String size;
  final String brand;
  final List<String> tags;
  final DateTime createdAt;

  DonationItem({
    required this.imagePath,
    required this.description,
    required this.type,
    required this.size,
    required this.brand,
    required this.tags,
    required this.createdAt,
  });
}
