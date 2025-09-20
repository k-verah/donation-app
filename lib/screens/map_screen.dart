import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;

  // Centro del mapa (Bogotá)
  static const _initial = LatLng(4.7110, -74.0721);

  // Filtros
  String _cause = 'Todos';
  String _access = 'Todos';
  String _schedule = 'Todos';

  // Datos de ejemplo
  final List<_DonationPoint> _points = const [
    _DonationPoint(
      id: 'p1',
      name: 'Fundación Niñez Feliz',
      position: LatLng(4.651, -74.060),
      cause: 'Niñez',
      accessible: true,
      schedule: 'Mañana',
    ),
    _DonationPoint(
      id: 'p2',
      name: 'Abrigo para Todos',
      position: LatLng(4.730, -74.082),
      cause: 'Adultos',
      accessible: false,
      schedule: 'Tarde',
    ),
    _DonationPoint(
      id: 'p3',
      name: 'Refugio Esperanza',
      position: LatLng(4.705, -74.100),
      cause: 'Emergencia',
      accessible: true,
      schedule: 'Noche',
    ),
    _DonationPoint(
      id: 'p4',
      name: 'Ropero Comunitario',
      position: LatLng(4.745, -74.050),
      cause: 'Niñez',
      accessible: false,
      schedule: 'Mañana',
    ),
  ];

  Set<Marker> _buildMarkers() {
    final filtered = _points.where((p) {
      final okCause = (_cause == 'Todos') || (_cause == p.cause);
      final okAcc =
          (_access == 'Todos') || ((_access == 'Accesible') == p.accessible);
      final okSch = (_schedule == 'Todos') || (_schedule == p.schedule);
      return okCause && okAcc && okSch;
    });

    return filtered
        .map((p) => Marker(
              markerId: MarkerId(p.id),
              position: p.position,
              infoWindow: InfoWindow(
                title: p.name,
                snippet:
                    '${p.cause} • ${p.schedule}${p.accessible ? " • ♿" : ""}',
              ),
            ))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de donación')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _initial, zoom: 12),
            onMapCreated: (c) => _controller = c,
            markers: _buildMarkers(),
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // Controles de filtro
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _Drop(
                        label: 'Causa',
                        value: _cause,
                        items: const ['Todos', 'Niñez', 'Adultos', 'Emergencia'],
                        onChanged: (v) => setState(() => _cause = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Drop(
                        label: 'Acceso',
                        value: _access,
                        items: const ['Todos', 'Accesible', 'No accesible'],
                        onChanged: (v) => setState(() => _access = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Drop(
                        label: 'Horario',
                        value: _schedule,
                        items: const ['Todos', 'Mañana', 'Tarde', 'Noche'],
                        onChanged: (v) => setState(() => _schedule = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Drop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // 👈 esto asegura que use todo el ancho
      value: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _DonationPoint {
  final String id;
  final String name;
  final LatLng position;
  final String cause; // Niñez, Adultos, Emergencia
  final bool accessible;
  final String schedule; // Mañana, Tarde, Noche

  const _DonationPoint({
    required this.id,
    required this.name,
    required this.position,
    required this.cause,
    required this.accessible,
    required this.schedule,
  });
}