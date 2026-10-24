import 'package:calc/features/feedback/models/feedback_model.dart';
import 'package:calc/features/feedback/services/feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// firestore.rules (calculator_feedback) ile uyum: türler ve alan adları.
void main() {
  const allowedTypes = ['bug', 'suggestion'];

  test('formdaki her tür kuralın kabul ettiği türe çevrilir', () {
    for (final formType in ['bug', 'feature', 'other', 'bilinmeyen']) {
      expect(allowedTypes, contains(FeedbackService.firestoreType(formType)));
    }
    expect(FeedbackService.firestoreType('bug'), 'bug');
    expect(FeedbackService.firestoreType('feature'), 'suggestion');
    expect(FeedbackService.firestoreType('other'), 'suggestion');
  });

  test('gönderilen alanlar kuraldaki izinli alanlarla birebir uyar', () {
    final map = FeedbackModel(
      id: '1',
      type: 'bug',
      message: 'm',
      email: null,
      deviceInfo: 'd',
      appVersion: '1.0.0',
      timestamp: DateTime(2026, 10, 24),
    ).toMap();
    const allowedKeys = {
      'id', 'type', 'message', 'email', 'deviceInfo', 'appVersion', 'timestamp'
    };
    expect(map.keys.toSet(), allowedKeys);
    expect(map['timestamp'], isA<String>());
  });
}
