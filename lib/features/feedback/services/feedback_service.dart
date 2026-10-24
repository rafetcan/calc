import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;
  final DeviceInfoPlugin _deviceInfo;
  DateTime? _lastFeedbackTime;

  FeedbackService({
    FirebaseFirestore? firestore,
    DeviceInfoPlugin? deviceInfo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Formdaki türü Firestore güvenlik kurallarının kabul ettiği değere çevirir.
  ///
  /// `calculator_feedback` kuralı `type` için yalnızca `bug` ve `suggestion`
  /// kabul eder (bkz. firestore.rules); başka değer PERMISSION_DENIED verir.
  /// Bu yüzden hata dışındaki her şey (özellik isteği, diğer) `suggestion` olur.
  static String firestoreType(String formType) =>
      formType == 'bug' ? 'bug' : 'suggestion';

  Future<bool> canSubmitFeedback() async {
    if (_lastFeedbackTime == null) return true;
    final difference = DateTime.now().difference(_lastFeedbackTime!);
    return difference.inMinutes >= 1;
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model} - Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.systemVersion}';
      }
      return 'Unknown device';
    } catch (e) {
      return 'Error getting device info';
    }
  }

  Future<void> submitFeedback({
    required String type,
    required String message,
    String? email,
  }) async {
    if (!await canSubmitFeedback()) {
      throw Exception(
          'Please wait at least 1 minute between feedback submissions');
    }

    final deviceInfo = await _getDeviceInfo();
    final packageInfo = await PackageInfo.fromPlatform();

    final feedback = FeedbackModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: firestoreType(type),
      message: message,
      email: email,
      deviceInfo: deviceInfo,
      appVersion: packageInfo.version,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('calculator_feedback')
        .doc(feedback.id)
        .set(feedback.toMap());
    _lastFeedbackTime = DateTime.now();
  }
}
