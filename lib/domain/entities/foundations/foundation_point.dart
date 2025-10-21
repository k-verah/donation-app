import 'package:donation_app/domain/entities/sensors/geo_point.dart';

class FoundationPoint {
  final String id, title, cause, access, schedule;
  final GeoPoint pos;
  const FoundationPoint({
    required this.id,
    required this.title,
    required this.cause,
    required this.access,
    required this.schedule,
    required this.pos,
  });
}
