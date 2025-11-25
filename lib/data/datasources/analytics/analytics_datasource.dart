import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/domain/entities/analytics/filter_usage.dart';
import 'package:donation_app/domain/entities/analytics/point_usage.dart';

class AnalyticsDataSource {
  final FirebaseFirestore db;

  AnalyticsDataSource(this.db);

  Future<void> trackFilterUsage(FilterUsage usage) async {
    await db.collection('analytics').doc('filter_usage').collection('events').add({
      'cause': usage.cause,
      'access': usage.access,
      'schedule': usage.schedule,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': usage.userId,
    });
  }

  Future<void> trackPointUsage(PointUsage usage) async {
    await db.collection('analytics').doc('point_usage').collection('events').add({
      'pointId': usage.pointId,
      'pointTitle': usage.pointTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': usage.userId,
    });
  }

  Future<List<Map<String, dynamic>>> getFilterUsageStats() async {
    final snapshot = await db
        .collection('analytics')
        .doc('filter_usage')
        .collection('events')
        .get();

    final Map<String, int> combinationCounts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final key = '${data['cause']}_${data['access']}_${data['schedule']}';
      combinationCounts[key] = (combinationCounts[key] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> stats = [];
    combinationCounts.forEach((key, count) {
      final parts = key.split('_');
      if (parts.length == 3) {
        stats.add({
          'cause': parts[0],
          'access': parts[1],
          'schedule': parts[2],
          'count': count,
        });
      }
    });

    stats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return stats;
  }

  Future<List<Map<String, dynamic>>> getPointUsageStats() async {
    final snapshot = await db
        .collection('analytics')
        .doc('point_usage')
        .collection('events')
        .get();

    final Map<String, Map<String, dynamic>> pointCounts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final pointId = data['pointId'] as String? ?? '';
      final pointTitle = data['pointTitle'] as String? ?? '';

      if (pointCounts.containsKey(pointId)) {
        pointCounts[pointId]!['count'] =
            (pointCounts[pointId]!['count'] as int) + 1;
      } else {
        pointCounts[pointId] = {
          'pointId': pointId,
          'pointTitle': pointTitle,
          'count': 1,
        };
      }
    }

    final List<Map<String, dynamic>> stats = pointCounts.values.toList();
    stats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return stats;
  }
}