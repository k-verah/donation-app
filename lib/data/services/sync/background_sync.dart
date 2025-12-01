import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

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

Future<List<Map<String, dynamic>>> prepareDataForSync(
  List<Map<String, dynamic>> items,
) async {
  return await compute(_prepareDataInIsolate, items);
}

List<Map<String, dynamic>> _prepareDataInIsolate(
    List<Map<String, dynamic>> items) {
  final processed = <Map<String, dynamic>>[];

  for (final item in items) {
    if (item['id'] == null || item['uid'] == null) {
      continue;
    }

    final processedItem = Map<String, dynamic>.from(item);
    processedItem['processedAt'] = DateTime.now().millisecondsSinceEpoch;

    processed.add(processedItem);
  }

  return processed;
}

Future<List<Map<String, dynamic>>> parseJsonInIsolate(String jsonData) async {
  return await compute(_parseJsonData, jsonData);
}

List<Map<String, dynamic>> _parseJsonData(String jsonData) {
  try {
    final List<dynamic> decoded = [];

    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e) {
    return [];
  }
}

class BackgroundTaskRunner {
  static Future<R> run<R>(FutureOr<R> Function() computation) async {
    try {
      return await Isolate.run(computation);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<R>> runBatch<T, R>(
    List<T> items,
    R Function(T) processor, {
    int batchSize = 10,
  }) async {
    final results = <R>[];

    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      final batchResults = await Future.wait(
        batch.map((item) => compute((_) => processor(item), null)),
      );

      results.addAll(batchResults);
    }

    return results;
  }
}

mixin BackgroundProcessingMixin {
  Future<T> runInBackground<T>(T Function() operation) async {
    return await compute((_) => operation(), null);
  }

  bool shouldUseIsolate(int itemCount) {
    return itemCount > 50;
  }
}
