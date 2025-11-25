import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';

class FoundationPointDatasource {
  Future<List<FoundationPoint>> load() async {
    return const [
      // Clothing + Easy + Morning
      FoundationPoint(
        id: 'donation1',
        title: 'Centro de Donación Ropa Fácil',
        cause: 'Clothing',
        access: 'Easy',
        schedule: 'Morning',
        pos: GeoPoint(4.65, -74.10),
      ),
      // Clothing + Easy + Afternoon
      FoundationPoint(
        id: 'donation2',
        title: 'Punto de Donación Ropa Centro',
        cause: 'Clothing',
        access: 'Easy',
        schedule: 'Afternoon',
        pos: GeoPoint(4.66, -74.08),
      ),
      // Clothing + Easy + Night
      FoundationPoint(
        id: 'donation3',
        title: 'Donación Ropa Nocturna',
        cause: 'Clothing',
        access: 'Easy',
        schedule: 'Night',
        pos: GeoPoint(4.64, -74.09),
      ),
      // Clothing + Medium + Morning
      FoundationPoint(
        id: 'donation4',
        title: 'Centro Ropa Mañana',
        cause: 'Clothing',
        access: 'Medium',
        schedule: 'Morning',
        pos: GeoPoint(4.67, -74.11),
      ),
      // Clothing + Medium + Afternoon
      FoundationPoint(
        id: 'donation5',
        title: 'Punto Ropa Tarde',
        cause: 'Clothing',
        access: 'Medium',
        schedule: 'Afternoon',
        pos: GeoPoint(4.68, -74.07),
      ),
      // Clothing + Medium + Night
      FoundationPoint(
        id: 'donation6',
        title: 'Donación Ropa Noche',
        cause: 'Clothing',
        access: 'Medium',
        schedule: 'Night',
        pos: GeoPoint(4.69, -74.06),
      ),
      // Clothing + Difficult + Morning
      FoundationPoint(
        id: 'donation7',
        title: 'Centro Ropa Dificil Mañana',
        cause: 'Clothing',
        access: 'Difficult',
        schedule: 'Morning',
        pos: GeoPoint(4.70, -74.12),
      ),
      // Clothing + Difficult + Afternoon
      FoundationPoint(
        id: 'donation8',
        title: 'Punto Ropa Dificil Tarde',
        cause: 'Clothing',
        access: 'Difficult',
        schedule: 'Afternoon',
        pos: GeoPoint(4.71, -74.05),
      ),
      // Clothing + Difficult + Night
      FoundationPoint(
        id: 'donation9',
        title: 'Donación Ropa Dificil Noche',
        cause: 'Clothing',
        access: 'Difficult',
        schedule: 'Night',
        pos: GeoPoint(4.72, -74.04),
      ),
      // Food + Easy + Morning
      FoundationPoint(
        id: 'donation10',
        title: 'Banco de Alimentos Mañana',
        cause: 'Food',
        access: 'Easy',
        schedule: 'Morning',
        pos: GeoPoint(4.73, -74.13),
      ),
      // Food + Easy + Afternoon
      FoundationPoint(
        id: 'donation11',
        title: 'Centro Alimentos Tarde',
        cause: 'Food',
        access: 'Easy',
        schedule: 'Afternoon',
        pos: GeoPoint(4.74, -74.14),
      ),
      // Food + Easy + Night
      FoundationPoint(
        id: 'donation12',
        title: 'Donación Alimentos Noche',
        cause: 'Food',
        access: 'Easy',
        schedule: 'Night',
        pos: GeoPoint(4.75, -74.15),
      ),
      // Food + Medium + Morning
      FoundationPoint(
        id: 'donation13',
        title: 'Banco Alimentos Mañana',
        cause: 'Food',
        access: 'Medium',
        schedule: 'Morning',
        pos: GeoPoint(4.76, -74.16),
      ),
      // Food + Medium + Afternoon
      FoundationPoint(
        id: 'donation14',
        title: 'Punto Alimentos Tarde',
        cause: 'Food',
        access: 'Medium',
        schedule: 'Afternoon',
        pos: GeoPoint(4.68, -74.05),
      ),
      // Food + Medium + Night
      FoundationPoint(
        id: 'donation15',
        title: 'Centro Alimentos Noche',
        cause: 'Food',
        access: 'Medium',
        schedule: 'Night',
        pos: GeoPoint(4.77, -74.17),
      ),
      // Food + Difficult + Morning
      FoundationPoint(
        id: 'donation16',
        title: 'Banco Alimentos Dificil',
        cause: 'Food',
        access: 'Difficult',
        schedule: 'Morning',
        pos: GeoPoint(4.78, -74.18),
      ),
      // Food + Difficult + Afternoon
      FoundationPoint(
        id: 'donation17',
        title: 'Punto Alimentos Dificil Tarde',
        cause: 'Food',
        access: 'Difficult',
        schedule: 'Afternoon',
        pos: GeoPoint(4.79, -74.19),
      ),
      // Food + Difficult + Night
      FoundationPoint(
        id: 'donation18',
        title: 'Donación Alimentos Dificil',
        cause: 'Food',
        access: 'Difficult',
        schedule: 'Night',
        pos: GeoPoint(4.80, -74.20),
      ),
      // Books + Easy + Morning
      FoundationPoint(
        id: 'donation19',
        title: 'Biblioteca Donación Mañana',
        cause: 'Books',
        access: 'Easy',
        schedule: 'Morning',
        pos: GeoPoint(4.81, -74.21),
      ),
      // Books + Easy + Afternoon
      FoundationPoint(
        id: 'donation20',
        title: 'Centro Libros Tarde',
        cause: 'Books',
        access: 'Easy',
        schedule: 'Afternoon',
        pos: GeoPoint(4.82, -74.22),
      ),
      // Books + Easy + Night
      FoundationPoint(
        id: 'donation21',
        title: 'Punto Libros Noche',
        cause: 'Books',
        access: 'Easy',
        schedule: 'Night',
        pos: GeoPoint(4.83, -74.23),
      ),
      // Books + Medium + Morning
      FoundationPoint(
        id: 'donation22',
        title: 'Biblioteca Mañana',
        cause: 'Books',
        access: 'Medium',
        schedule: 'Morning',
        pos: GeoPoint(4.84, -74.24),
      ),
      // Books + Medium + Afternoon
      FoundationPoint(
        id: 'donation23',
        title: 'Centro Libros Tarde',
        cause: 'Books',
        access: 'Medium',
        schedule: 'Afternoon',
        pos: GeoPoint(4.72, -74.08),
      ),
      // Books + Medium + Night
      FoundationPoint(
        id: 'donation24',
        title: 'Punto Libros Noche',
        cause: 'Books',
        access: 'Medium',
        schedule: 'Night',
        pos: GeoPoint(4.85, -74.25),
      ),
      // Books + Difficult + Morning
      FoundationPoint(
        id: 'donation25',
        title: 'Biblioteca Dificil Mañana',
        cause: 'Books',
        access: 'Difficult',
        schedule: 'Morning',
        pos: GeoPoint(4.86, -74.26),
      ),
      // Books + Difficult + Afternoon
      FoundationPoint(
        id: 'donation26',
        title: 'Centro Libros Dificil',
        cause: 'Books',
        access: 'Difficult',
        schedule: 'Afternoon',
        pos: GeoPoint(4.87, -74.27),
      ),
      // Books + Difficult + Night
      FoundationPoint(
        id: 'donation27',
        title: 'Punto Libros Dificil Noche',
        cause: 'Books',
        access: 'Difficult',
        schedule: 'Night',
        pos: GeoPoint(4.88, -74.28),
      ),
    ];
  }
}
