import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:donation_app/data/services/sync/connectivity_service.dart';
import 'package:donation_app/data/services/sync/sync_service.dart';

/// Provider que expone el estado de conectividad y sincronización a la UI
class SyncProvider extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final SyncService _syncService;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<SyncServiceStatus>? _syncStatusSub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  SyncServiceStatus _status = SyncServiceStatus.idle;
  SyncServiceStatus get status => _status;

  bool get isSyncing => _status == SyncServiceStatus.syncing;
  bool get hasPendingSync => _syncService.hasPendingSync;
  int get pendingCount => _syncService.pendingCount;

  SyncProvider({
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _connectivity = connectivity,
        _syncService = syncService {
    _init();
  }

  void _init() {
    _isOnline = _connectivity.isOnline;

    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });

    _syncStatusSub = _syncService.syncStatus.listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  /// Fuerza una sincronización manual
  Future<void> forceSync() async {
    await _syncService.syncPendingOperations();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncStatusSub?.cancel();
    super.dispose();
  }
}
