class FilterUsage {
  final String cause;
  final String access;
  final String schedule;
  final DateTime timestamp;
  final String? userId;

  FilterUsage({
    required this.cause,
    required this.access,
    required this.schedule,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'cause': cause,
      'access': access,
      'schedule': schedule,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory FilterUsage.fromMap(Map<String, dynamic> map) {
    return FilterUsage(
      cause: map['cause'] ?? 'All',
      access: map['access'] ?? 'All',
      schedule: map['schedule'] ?? 'All',
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
    );
  }
}