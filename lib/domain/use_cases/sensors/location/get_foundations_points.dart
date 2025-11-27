import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/repositories/foundations/foundation_point_repository.dart';

class GetFoundationsPoints {
  final FoundationPointRepository repo;
  const GetFoundationsPoints(this.repo);
  Future<List<FoundationPoint>> call() => repo.fetchAll();
}
