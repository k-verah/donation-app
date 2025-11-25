class PointUsage {
  final String pointId;
  final String pointTitle;
  final DateTime timestamp;
  final String? userId;

  PointUsage({
    required this.pointId,
    required this.pointTitle,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'pointId': pointId,
      'pointTitle': pointTitle,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory PointUsage.fromMap(Map<String, dynamic> map) {
    return PointUsage(
      pointId: map['pointId'] ?? '',
      pointTitle: map['pointTitle'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
    );
  }
}