class FeedbackModel {
  final String id;
  final String type; // 'bug' veya 'suggestion'
  final String message;
  final String email;
  final String deviceInfo;
  final String appVersion;
  final DateTime timestamp;
  final String status; // 'new', 'in_progress', 'resolved'

  FeedbackModel({
    required this.id,
    required this.type,
    required this.message,
    required this.email,
    required this.deviceInfo,
    required this.appVersion,
    required this.timestamp,
    this.status = 'new',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'email': email,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
