import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show pow, sqrt;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _bogotaCenter = LatLng(4.7110, -74.0721);
  LatLng? _currentLocation;

  String _selectedCause = "All";
  String _selectedAccess = "All";
  String _selectedSchedule = "All";
  String? _recommendationMessage;

  // 🔹 Base list of donation points with attributes
  final List<Map<String, dynamic>> _donationPoints = [
    {
      "id": "donation1",
      "position": const LatLng(4.65, -74.1),
      "title": "Donation Point 1",
      "cause": "Clothing",
      "access": "Easy",
      "schedule": "Morning"
    },
    {
      "id": "donation2",
      "position": const LatLng(4.68, -74.05),
      "title": "Donation Point 2",
      "cause": "Food",
      "access": "Medium",
      "schedule": "Afternoon"
    },
    {
      "id": "donation3",
      "position": const LatLng(4.72, -74.08),
      "title": "Donation Point 3",
      "cause": "Books",
      "access": "Difficult",
      "schedule": "Night"
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// 🔹 Get user's current location
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

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_currentLocation!),
    );
  }

  /// 🔹 Calculate distance between user and donation point
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// 🔹 Return list of markers sorted by distance
  List<Marker> _getMarkersSortedByDistance() {
    if (_currentLocation == null) {
      return _donationPoints
          .map((point) => Marker(
                markerId: MarkerId(point["id"]),
                position: point["position"],
                infoWindow: InfoWindow(title: point["title"]),
              ))
          .toList();
    }

    final sortedPoints = _donationPoints.map((point) {
      final distance = _calculateDistance(
          _currentLocation!, point["position"] as LatLng);
      return {...point, "distance": distance};
    }).toList();

    sortedPoints.sort((a, b) => a["distance"].compareTo(b["distance"]));

    return sortedPoints.map((point) {
      final distance = point["distance"] as double;
      final isNearest = sortedPoints.indexOf(point) < 2;

      return Marker(
        markerId: MarkerId(point["id"]),
        position: point["position"] as LatLng,
        infoWindow: InfoWindow(
          title: "${point["title"]} (${distance.toStringAsFixed(0)} m)",
        ),
        icon: isNearest
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarker,
      );
    }).toList();
  }

  /// 🔹 Generate recommendation based on selected filters
  void _generateRecommendation() {
    final filtered = _donationPoints.where((point) {
      final causeMatch = _selectedCause == "All" || point["cause"] == _selectedCause;
      final accessMatch = _selectedAccess == "All" || point["access"] == _selectedAccess;
      final scheduleMatch = _selectedSchedule == "All" || point["schedule"] == _selectedSchedule;
      return causeMatch && accessMatch && scheduleMatch;
    }).toList();

    if (filtered.isEmpty) {
      setState(() {
        _recommendationMessage =
            "No donation point matches your preferences. Try adjusting your filters.";
      });
      return;
    }

    if (_currentLocation != null) {
      filtered.sort((a, b) {
        final distA = _calculateDistance(_currentLocation!, a["position"]);
        final distB = _calculateDistance(_currentLocation!, b["position"]);
        return distA.compareTo(distB);
      });
    }

    final best = filtered.first;
    setState(() {
      _recommendationMessage =
          "We recommend ${best["title"]}.\nCause: ${best["cause"]}, Access: ${best["access"]}, Schedule: ${best["schedule"]}.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = _getMarkersSortedByDistance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Filters section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCause,
                    items: ["All", "Clothing", "Food", "Books"]
                        .map((cause) => DropdownMenuItem(
                              value: cause,
                              child: Text(cause,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCause = value!),
                    decoration: const InputDecoration(
                      labelText: "Cause",
                      labelStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccess,
                    items: ["All", "Easy", "Medium", "Difficult"]
                        .map((access) => DropdownMenuItem(
                              value: access,
                              child: Text(access,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAccess = value!),
                    decoration: const InputDecoration(
                      labelText: "Access",
                      labelStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSchedule,
                    items: ["All", "Morning", "Afternoon", "Night"]
                        .map((schedule) => DropdownMenuItem(
                              value: schedule,
                              child: Text(schedule,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSchedule = value!),
                    decoration: const InputDecoration(
                      labelText: "Schedule",
                      labelStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Button for recommendation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: _generateRecommendation,
              icon: const Icon(Icons.lightbulb),
              label: const Text("Get Recommendation"),
            ),
          ),

          // 🔹 Dynamic recommendation message
          if (_recommendationMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _recommendationMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),

          // 🔹 Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _bogotaCenter,
                zoom: 12,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: Set<Marker>.of(markers),
            ),
          ),
        ],
      ),
    );
  }
}