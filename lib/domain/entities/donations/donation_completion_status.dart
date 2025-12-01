enum DonationCompletionStatus {
  available,

  pendingCompletion,

  completed,
}

extension DonationCompletionStatusExtension on DonationCompletionStatus {
  String toJson() => name;

  static DonationCompletionStatus fromJson(String? value) {
    if (value == null) return DonationCompletionStatus.available;
    return DonationCompletionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DonationCompletionStatus.available,
    );
  }

  bool get isAvailable => this == DonationCompletionStatus.available;
  bool get isPendingCompletion =>
      this == DonationCompletionStatus.pendingCompletion;
  bool get isCompleted => this == DonationCompletionStatus.completed;

  String get displayName {
    switch (this) {
      case DonationCompletionStatus.available:
        return 'Available';
      case DonationCompletionStatus.pendingCompletion:
        return 'Pending Delivery';
      case DonationCompletionStatus.completed:
        return 'Completed';
    }
  }
}
