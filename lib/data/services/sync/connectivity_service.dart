import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para detectar el estado de conectividad
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream que emite true cuando hay conexión, false cuando no
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Inicializa el servicio y comienza a escuchar cambios
  Future<void> init() async {
    // Verificar estado inicial
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);
    _controller.add(_isOnline);

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _hasConnection(results);

      if (wasOnline != _isOnline) {
        debugPrint(
            '📶 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
        _controller.add(_isOnline);
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  /// Verifica la conectividad actual
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
