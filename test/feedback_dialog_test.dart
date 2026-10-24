import 'package:calc/features/feedback/services/feedback_service.dart';
import 'package:calc/features/feedback/views/feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedbackService implements FeedbackService {
  String? type;
  String? message;

  @override
  Future<bool> canSubmitFeedback() async => true;

  @override
  Future<void> submitFeedback({
    required String type,
    required String message,
    String? email,
  }) async {
    this.type = type;
    this.message = message;
  }
}

void main() {
  testWidgets('yıldız yok; tür seçimi, mesaj ve herkese açık Play bağlantısı var',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FeedbackDialog(feedbackService: _FakeFeedbackService()),
      ),
    ));

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byIcon(Icons.star_outline), findsOneWidget); // Play bağlantısı
  });
}
