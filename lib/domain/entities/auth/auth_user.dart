class AuthUser {
  final String uid;
  final String? email;
  final String? name;
  final String? city;
  final List<String>? interests;
  const AuthUser({
    required this.uid,
    this.email,
    this.name,
    this.city,
    this.interests,
  });
}
