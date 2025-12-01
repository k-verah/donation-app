/// Tipos de operación para la cola de sincronización
enum SyncOperation {
  createDonation,
  createSchedule,
  createPickup,
  updateDonation,
  updateSchedule,
  updatePickup,

  /// Actualiza completionStatus de donaciones a pendingCompletion
  markDonationsPendingCompletion,

  /// Actualiza completionStatus de donaciones a completed
  markDonationsCompleted,

  /// Marca un schedule como entregado
  markScheduleDelivered,

  /// Marca un pickup como entregado
  markPickupDelivered,

  /// Revierte una donación completada a disponible
  markDonationAvailable,
}

extension SyncOperationExtension on SyncOperation {
  String toJson() => name;

  static SyncOperation fromJson(String value) {
    return SyncOperation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncOperation.createDonation,
    );
  }
}

/// Item en la cola de sincronización
class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final String entityId;
  final Map<String, dynamic> payload;
  final int attempts;
  final DateTime createdAt;
  final DateTime? lastAttempt;
  final String? lastError;

  const SyncQueueItem({
    required this.id,
    required this.operation,
    required this.entityId,
    required this.payload,
    this.attempts = 0,
    required this.createdAt,
    this.lastAttempt,
    this.lastError,
  });

  SyncQueueItem copyWith({
    int? attempts,
    DateTime? lastAttempt,
    String? lastError,
  }) =>
      SyncQueueItem(
        id: id,
        operation: operation,
        entityId: entityId,
        payload: payload,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt,
        lastAttempt: lastAttempt ?? this.lastAttempt,
        lastError: lastError ?? this.lastError,
      );

  /// Serializa a JSON para SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation.toJson(),
        'entityId': entityId,
        'payload': payload,
        'attempts': attempts,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastAttempt': lastAttempt?.millisecondsSinceEpoch,
        'lastError': lastError,
      };

  /// Deserializa desde JSON de SharedPreferences
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] as String,
        operation: SyncOperationExtension.fromJson(json['operation'] as String),
        entityId: json['entityId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        attempts: json['attempts'] as int? ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        lastAttempt: json['lastAttempt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastAttempt'] as int)
            : null,
        lastError: json['lastError'] as String?,
      );

  /// Máximo de reintentos antes de marcar como fallido permanente
  static const int maxAttempts = 5;

  bool get canRetry => attempts < maxAttempts;
}
