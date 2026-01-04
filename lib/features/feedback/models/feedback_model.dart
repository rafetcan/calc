class FeedbackModel {
  final String id;
  final String type;
  final String message;
  final String? email;
  final String deviceInfo;
  final String appVersion;
  final DateTime timestamp;

  FeedbackModel({
    required this.id,
    required this.type,
    required this.message,
    this.email,
    required this.deviceInfo,
    required this.appVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'email': email,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] as String,
      type: map['type'] as String,
      message: map['message'] as String,
      email: map['email'] as String?,
      deviceInfo: map['deviceInfo'] as String,
      appVersion: map['appVersion'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
