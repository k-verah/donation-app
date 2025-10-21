import 'package:donation_app/data/datasources/foundations/foundation_point_datasource.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/repositories/foundations/foundation_point_repository.dart';

class FoundationPointRepositoryImpl implements FoundationPointRepository {
  final FoundationPointDatasource ds;
  FoundationPointRepositoryImpl(this.ds);

  @override
  Future<List<FoundationPoint>> fetchAll() => ds.load();
}
