import 'package:donation_app/domain/entities/sensors/geo_point.dart';

class PickupDonation {
  final String id;
  final String uid;
  final GeoPoint location; // ajusta a tu tipo si usas GeoPoint
  final DateTime date;
  final String time;
  const PickupDonation({
    required this.id,
    required this.uid,
    required this.location,
    required this.date,
    required this.time,
  });
}
