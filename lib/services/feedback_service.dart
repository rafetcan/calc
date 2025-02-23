import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  DateTime? _lastFeedback;
  static const _minFeedbackInterval = Duration(minutes: 1);

  Future<void> submitFeedback(String type, String message, String email) async {
    // Rate limiting kontrolü
    if (_lastFeedback != null) {
      final timeSinceLastFeedback = DateTime.now().difference(_lastFeedback!);
      if (timeSinceLastFeedback < _minFeedbackInterval) {
        throw Exception(
          'Lütfen ${_minFeedbackInterval.inMinutes} dakika bekleyin',
        );
      }
    }

    try {
      // Cihaz bilgilerini al
      String deviceInfo = await _getDeviceInfo();

      // Uygulama versiyonunu al
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appVersion = packageInfo.version;

      // Geri bildirimi oluştur
      final feedback = FeedbackModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        message: message,
        email: email,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
        timestamp: DateTime.now(),
      );

      // Firestore'a kaydet
      await _firestore.collection('calculator_feedback').add(feedback.toMap());

      _lastFeedback = DateTime.now();
    } catch (e) {
      throw Exception('Geri bildirim gönderilemedi: $e');
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} (iOS ${iosInfo.systemVersion})';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Device Info Not Available';
    }
  }
}
