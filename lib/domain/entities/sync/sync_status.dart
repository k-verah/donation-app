/// Estado de sincronización para entidades offline-first
enum SyncStatus {
  /// Guardado localmente, pendiente de subir a Firebase
  pending,

  /// Sincronización en progreso
  syncing,

  /// Sincronizado exitosamente con Firebase
  synced,

  /// Falló la sincronización (se reintentará)
  failed,
}

extension SyncStatusExtension on SyncStatus {
  String toJson() => name;

  static SyncStatus fromJson(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }

  bool get isPending => this == SyncStatus.pending;
  bool get isSynced => this == SyncStatus.synced;
  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.failed;
}
