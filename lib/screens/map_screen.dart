import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  // Bogotá como punto inicial
  static const LatLng _bogotaCenter = LatLng(4.7110, -74.0721);

  LatLng? _currentLocation;

  String _selectedCause = "Todos";
  String _selectedAccess = "Todos";
  String _selectedSchedule = "Todos";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_currentLocation!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Donación'),
        leading: BackButton(
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushNamedAndRemoveUntil('/home', (route) => false);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 🔹 Barra de filtros en una sola fila compacta
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCause,
                    items: ["Todos", "Ropa", "Alimentos", "Libros"]
                        .map((cause) => DropdownMenuItem(
                            value: cause,
                            child: Text(cause,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCause = value!),
                    decoration: const InputDecoration(
                      labelText: "Causa",
                      labelStyle: TextStyle(fontSize: 12),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccess,
                    items: ["Todos", "Fácil", "Medio", "Difícil"]
                        .map((access) => DropdownMenuItem(
                            value: access,
                            child: Text(access,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAccess = value!),
                    decoration: const InputDecoration(
                      labelText: "Acceso",
                      labelStyle: TextStyle(fontSize: 12),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSchedule,
                    items: ["Todos", "Mañana", "Tarde", "Noche"]
                        .map((schedule) => DropdownMenuItem(
                            value: schedule,
                            child: Text(schedule,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSchedule = value!),
                    decoration: const InputDecoration(
                      labelText: "Horario",
                      labelStyle: TextStyle(fontSize: 12),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Mapa con GPS y marcadores
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _bogotaCenter,
                zoom: 12,
              ),
              myLocationEnabled: true, // GPS: punto azul
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                const Marker(
                  markerId: MarkerId("donation1"),
                  position: LatLng(4.65, -74.1),
                  infoWindow: InfoWindow(title: "Punto de donación 1"),
                ),
                const Marker(
                  markerId: MarkerId("donation2"),
                  position: LatLng(4.68, -74.05),
                  infoWindow: InfoWindow(title: "Punto de donación 2"),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
