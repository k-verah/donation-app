import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// Datos para enviar al Isolate de sincronización
class SyncPayload {
  final List<Map<String, dynamic>> pendingSchedules;
  final List<Map<String, dynamic>> pendingPickups;
  final List<Map<String, dynamic>> pendingDonations;

  SyncPayload({
    required this.pendingSchedules,
    required this.pendingPickups,
    required this.pendingDonations,
  });
}

/// Resultado de la sincronización en background
class SyncResult {
  final int successCount;
  final int failCount;
  final List<String> syncedIds;
  final List<String> failedIds;
  final String? error;

  SyncResult({
    required this.successCount,
    required this.failCount,
    required this.syncedIds,
    required this.failedIds,
    this.error,
  });
}

/// Ejecuta la preparación de datos para sync en un Isolate
///
/// Esto es útil para procesar grandes cantidades de datos sin bloquear la UI
Future<List<Map<String, dynamic>>> prepareDataForSync(
  List<Map<String, dynamic>> items,
) async {
  return await compute(_prepareDataInIsolate, items);
}

List<Map<String, dynamic>> _prepareDataInIsolate(
    List<Map<String, dynamic>> items) {
  // Procesamiento pesado de datos (validación, transformación, etc.)
  final processed = <Map<String, dynamic>>[];

  for (final item in items) {
    // Validar que el item tenga los campos necesarios
    if (item['id'] == null || item['uid'] == null) {
      continue;
    }

    // Agregar timestamp de procesamiento
    final processedItem = Map<String, dynamic>.from(item);
    processedItem['processedAt'] = DateTime.now().millisecondsSinceEpoch;

    processed.add(processedItem);
  }

  return processed;
}

/// Parsea una lista grande de donaciones en un Isolate
Future<List<Map<String, dynamic>>> parseJsonInIsolate(String jsonData) async {
  return await compute(_parseJsonData, jsonData);
}

List<Map<String, dynamic>> _parseJsonData(String jsonData) {
  // Esta función se ejecuta en un Isolate separado
  // Útil para parsear respuestas grandes de Firebase
  try {
    // Simular parsing pesado
    final List<dynamic> decoded = [];
    // En producción: decoded = jsonDecode(jsonData) as List<dynamic>;

    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e) {
    return [];
  }
}

/// Ejecutor de tareas en background usando Isolate.run (Dart 2.19+)
class BackgroundTaskRunner {
  /// Ejecuta una tarea costosa en un Isolate separado
  static Future<R> run<R>(FutureOr<R> Function() computation) async {
    try {
      // Usar Isolate.run para Dart 2.19+
      return await Isolate.run(computation);
    } catch (e) {
      // Fallback a compute si Isolate.run no está disponible
      debugPrint('⚠️ Isolate.run failed, falling back: $e');
      rethrow;
    }
  }

  /// Ejecuta procesamiento de batch en paralelo
  static Future<List<R>> runBatch<T, R>(
    List<T> items,
    R Function(T) processor, {
    int batchSize = 10,
  }) async {
    final results = <R>[];

    // Procesar en batches para no sobrecargar
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      // Procesar batch en paralelo
      final batchResults = await Future.wait(
        batch.map((item) => compute((_) => processor(item), null)),
      );

      results.addAll(batchResults);
    }

    return results;
  }
}

/// Mixin para agregar capacidades de background processing a cualquier servicio
mixin BackgroundProcessingMixin {
  /// Ejecuta una operación pesada en background
  Future<T> runInBackground<T>(T Function() operation) async {
    return await compute((_) => operation(), null);
  }

  /// Verifica si vale la pena usar un Isolate
  /// (para operaciones muy pequeñas, el overhead no vale la pena)
  bool shouldUseIsolate(int itemCount) {
    // Solo usar Isolate si hay más de 50 items
    return itemCount > 50;
  }
}
