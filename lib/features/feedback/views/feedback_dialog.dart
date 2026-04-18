import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  final FeedbackService feedbackService;

  /// Menüden "Hata bildiri" gibi: yıldız ekranını atla, doğrudan mesaj formu.
  final bool directMessageForm;

  /// Firestore kaydındaki `type` (örn. `bug`, `other`).
  final String submissionType;

  const FeedbackDialog({
    super.key,
    required this.feedbackService,
    this.directMessageForm = false,
    this.submissionType = 'other',
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  late int? _selectedRating; // 1-5, null = rating screen
  int? _previewRating; // dokunma/hover sırasında önizleme

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.directMessageForm ? 1 : null;
  }

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.akidesoft.calc';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Debug APK: In-App Review çoğu zaman çalışmaz → doğrudan Play Store.
  /// Play’den yüklü release: önce uygulama içi sheet, sonra (kota vb. yüzünden
  /// görünmüş olmasa bile) mağaza sayfası — kullanıcı mutlaka puan verebilir.
  Future<void> _openPlayStoreReview() async {
    if (kIsWeb) return;

    final inAppReview = InAppReview.instance;

    Future<void> openListing() async {
      await inAppReview.openStoreListing();
    }

    try {
      if (kDebugMode) {
        // Fiziksel cihaz + debug: Google yerel pencereyi neredeyse hiç göstermez
        await openListing();
        return;
      }

      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }
      await openListing();
    } catch (_) {
      final uri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _onStarTap(int rating) async {
    setState(() => _selectedRating = rating);

    if (rating == 5) {
      await _openPlayStoreReview();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('feedback.rate_thanks'.tr())),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  bool get _showMessageForm => _selectedRating != null && _selectedRating! < 5;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.feedbackService.submitFeedback(
        type: widget.submissionType,
        message: _messageController.text,
        email: null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('feedback.success'.tr())),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _showMessageForm ? _buildMessageForm() : _buildRatingScreen(),
        ),
      ),
    );
  }

  Widget _buildRatingScreen() {
    final theme = Theme.of(context);
    // Dokunma/hover sırasında önizleme, yoksa seçilen değer
    final displayRating = _previewRating ?? _selectedRating;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'feedback.rate_prompt'.tr(),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              final isHighlighted =
                  displayRating != null && displayRating >= star;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _previewRating = star),
                  onTapUp: (_) => setState(() => _previewRating = null),
                  onTapCancel: () => setState(() => _previewRating = null),
                  onTap: () => _onStarTap(star),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    child: Icon(
                      isHighlighted ? Icons.star : Icons.star_border,
                      size: 36,
                      color: isHighlighted
                          ? Colors.amber
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'feedback.tell_us_more'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'feedback.message'.tr(),
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'feedback.error.message_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text('common.cancel'.tr()),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('feedback.submit'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
