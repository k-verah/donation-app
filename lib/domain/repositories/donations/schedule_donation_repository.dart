import 'package:donation_app/domain/entities/donations/schedule_donation.dart';

abstract class ScheduleDonationRepository {
  /// Confirma un schedule donation (offline-first)
  /// Guarda localmente y encola para sync
  Future<void> confirmSchedule(ScheduleDonation d);

  /// Obtiene los schedules del usuario (local + cached)
  List<ScheduleDonation> getSchedulesByUid(String uid);

  /// Obtiene schedules pendientes de sincronizar
  List<ScheduleDonation> getPendingSchedules();
}
