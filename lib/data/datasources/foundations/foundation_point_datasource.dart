import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';

class FoundationPointDatasource {
  Future<List<FoundationPoint>> load() async {
    return const [
      FoundationPoint(
        id: 'donation1',
        title: 'Donation Point 1',
        cause: 'Clothing',
        access: 'Easy',
        schedule: 'Morning',
        pos: GeoPoint(4.65, -74.10),
      ),
      FoundationPoint(
        id: 'donation2',
        title: 'Donation Point 2',
        cause: 'Food',
        access: 'Medium',
        schedule: 'Afternoon',
        pos: GeoPoint(4.68, -74.05),
      ),
      FoundationPoint(
        id: 'donation3',
        title: 'Donation Point 3',
        cause: 'Books',
        access: 'Difficult',
        schedule: 'Night',
        pos: GeoPoint(4.72, -74.08),
      ),
    ];
  }
}
