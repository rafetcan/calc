import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // Configure Analytics
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e');
      if (kDebugMode) {
        print(stack);
      }
    }
  }

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Analytics event logging failed: $e');
    }
  }

  static Future<void> logError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Crashlytics error logging failed: $e');
    }
  }
}
