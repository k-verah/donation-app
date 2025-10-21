import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().init(); // 👈 carga puntos + ubicación
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationProvider>();
    final origin = vm.current ?? LocationProvider.bogota;

    final markers = vm.sorted().asMap().entries.map((e) {
      final i = e.key;
      final p = e.value.$1;
      final d = e.value.$2;
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.pos.lat, p.pos.lng),
        infoWindow: InfoWindow(
          title: "${p.title}${d.isNaN ? '' : ' (${d.toStringAsFixed(0)} m)'}",
        ),
        icon: i < 2
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarker,
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (r) => false),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _Filter(
                  label: 'Cause',
                  value: vm.cause,
                  items: const ['All', 'Clothing', 'Food', 'Books'],
                  onChanged: (v) => vm.setFilters(causeVal: v),
                ),
                const SizedBox(width: 6),
                _Filter(
                  label: 'Access',
                  value: vm.access,
                  items: const ['All', 'Easy', 'Medium', 'Difficult'],
                  onChanged: (v) => vm.setFilters(accessVal: v),
                ),
                const SizedBox(width: 6),
                _Filter(
                  label: 'Schedule',
                  value: vm.schedule,
                  items: const ['All', 'Morning', 'Afternoon', 'Night'],
                  onChanged: (v) => vm.setFilters(scheduleVal: v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                final best = vm.recommend();
                if (best != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(best.pos.lat, best.pos.lng)),
                  );
                }
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Get Recommendation'),
            ),
          ),
          if (vm.recommendationMsg != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                vm.recommendationMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(origin.lat, origin.lng),
                zoom: 12,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (c) => _mapController = c,
              markers: markers,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Filter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
