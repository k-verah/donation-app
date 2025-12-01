enum SyncStatus {
  pending,

  syncing,

  synced,

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
