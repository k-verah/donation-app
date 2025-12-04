import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRemoteDatasource {
  final FirebaseFirestore db;
  AnalyticsRemoteDatasource(this.db);

  DocumentReference<Map<String, dynamic>> globalDoc() =>
      db.collection('analyticsdonationpickup').doc('global');

  Map<String, dynamic> incSchedule() =>
      {'schedule_confirm_count': FieldValue.increment(1)};
  Map<String, dynamic> incPickup() =>
      {'pickup_confirm_count': FieldValue.increment(1)};

  DocumentReference<Map<String, dynamic>> scheduleHoursDoc() =>
      db.collection('analyticsdonationpickup').doc('schedule_hours');

  DocumentReference<Map<String, dynamic>> pickupHoursDoc() =>
      db.collection('analyticsdonationpickup').doc('pickup_hours');

  Map<String, dynamic> incScheduleHour(int hour) =>
      {'hour_${hour.toString().padLeft(2, '0')}': FieldValue.increment(1)};

  Map<String, dynamic> incPickupHour(int hour) =>
      {'hour_${hour.toString().padLeft(2, '0')}': FieldValue.increment(1)};

  int? parseHourFromTimeString(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final cleanTime = timeString.trim().toUpperCase();

      final regex12h = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
      final match12h = regex12h.firstMatch(cleanTime);

      if (match12h != null) {
        int hour = int.parse(match12h.group(1)!);
        final period = match12h.group(3)!;

        if (period == 'AM') {
          if (hour == 12) hour = 0;
        } else {
          if (hour != 12) hour += 12;
        }
        return hour;
      }

      final regex24h = RegExp(r'^(\d{1,2}):(\d{2})$');
      final match24h = regex24h.firstMatch(cleanTime);

      if (match24h != null) {
        return int.parse(match24h.group(1)!);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
