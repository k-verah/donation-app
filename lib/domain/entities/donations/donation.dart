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
  });

  Donation copyWith({String? id}) => Donation(
    id: id ?? this.id,
    uid: uid,
    description: description,
    type: type,
    size: size,
    brand: brand,
    tags: tags,
    createdAt: createdAt,
    localImagePath: localImagePath,
  );
}
