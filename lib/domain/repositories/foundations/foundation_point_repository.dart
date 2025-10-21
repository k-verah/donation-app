import 'package:donation_app/domain/entities/foundations/foundation_point.dart';

abstract class FoundationPointRepository {
  Future<List<FoundationPoint>> fetchAll();
}
