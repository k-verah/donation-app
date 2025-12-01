import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:donation_app/presentation/providers/analytics/analytics_provider.dart';
import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';
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
  FoundationPoint? _lastRecommendedPoint;
  String? _lastFilterCombination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().init();
    });
  }

  void _zoomToRecommendedPoint(FoundationPoint? point) {
    if (point != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(point.pos.lat, point.pos.lng),
          15.0,
        ),
      );
    }
  }

  void _trackFilterUsage(String cause, String access, String schedule) {
    final combination = '$cause|$access|$schedule';
    if (combination != _lastFilterCombination) {
      _lastFilterCombination = combination;
      context.read<AnalyticsProvider>().trackFilterUsage(
            cause: cause,
            access: access,
            schedule: schedule,
          );
    }
  }

  void _trackPointUsage(FoundationPoint point) {
    context.read<AnalyticsProvider>().trackPointUsage(
          pointId: point.id,
          pointTitle: point.title,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationProvider>();
    final origin = vm.current ?? LocationProvider.bogota;

    // Track filter usage cuando cambian los filtros
    _trackFilterUsage(vm.cause, vm.access, vm.schedule);

    // Si hay filtros activos, usar puntos filtrados; si no, mostrar todos
    final sortedPoints =
        vm.hasActiveFilters() ? vm.getFilteredAndSorted() : vm.sorted();

    // Obtener el punto recomendado solo si hay filtros activos
    FoundationPoint? recommendedPoint;
    if (vm.hasActiveFilters()) {
      final recommendation = vm.recommendUC(
        points: vm.points,
        cause: vm.cause,
        access: vm.access,
        schedule: vm.schedule,
        origin: vm.current,
      );
      recommendedPoint = recommendation.best;
      vm.recommendationMsg = recommendation.message;

      // Track point usage cuando se recomienda un punto
      if (recommendedPoint != null &&
          recommendedPoint.id != _lastRecommendedPoint?.id) {
        _trackPointUsage(recommendedPoint);
        _lastRecommendedPoint = recommendedPoint;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _zoomToRecommendedPoint(recommendedPoint);
        });
      }
    } else {
      _lastRecommendedPoint = null;
      vm.recommendationMsg = null;
    }

    // Crear marcadores: todos rojos por defecto, excepto el recomendado que será verde
    final markers = sortedPoints.asMap().entries.map((e) {
      final p = e.value.$1;
      final d = e.value.$2;
      final isRecommended =
          recommendedPoint != null && p.id == recommendedPoint.id;

      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.pos.lat, p.pos.lng),
        infoWindow: InfoWindow(
          title: "${p.title}${d.isNaN ? '' : ' (${d.toStringAsFixed(0)} m)'}",
        ),
        // Todos rojos por defecto, excepto el recomendado que será verde
        icon: isRecommended
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          // Track cuando el usuario toca un marcador
          _trackPointUsage(p);
        },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.pushNamed(context, '/analytics');
            },
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
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
                  _trackPointUsage(best);
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(best.pos.lat, best.pos.lng),
                      15.0,
                    ),
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
