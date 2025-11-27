class ScheduleDonation {
  final String id;
  final String uid;
  final String title;
  final DateTime date;
  final String? time;
  final String? notes;
  const ScheduleDonation({
    required this.id,
    required this.uid,
    required this.title,
    required this.date,
    this.time,
    this.notes,
  });
}
