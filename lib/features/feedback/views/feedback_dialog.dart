import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/feedback_service.dart';

/// Serbest geri bildirim formu: tür (hata/öneri/diğer) + mesaj.
/// Yıldız ekranı yoktur; kullanıcı puana göre ayrılmaz. Formun altında HERKESE
/// görünen ayrı bir "Play'de puan ver" bağlantısı bulunur.
class FeedbackDialog extends StatefulWidget {
  final FeedbackService feedbackService;

  /// Formda başlangıçta seçili tür (`bug`, `feature`, `other`).
  final String initialType;

  const FeedbackDialog({
    super.key,
    required this.feedbackService,
    this.initialType = 'other',
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  static const List<String> _types = ['bug', 'feature', 'other'];
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.akidesoft.calc';

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  late String _type;

  @override
  void initState() {
    super.initState();
    _type = _types.contains(widget.initialType) ? widget.initialType : 'other';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Play mağaza sayfasını açar; olmazsa aynı adresi tarayıcıda/Play'de açar.
  Future<void> _openPlayStoreListing() async {
    if (kIsWeb) return;
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {
      final uri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.feedbackService.submitFeedback(
        type: _type,
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
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('feedback.title'.tr(), style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in _types)
                      ChoiceChip(
                        label: Text('feedback.type.$type'.tr()),
                        selected: _type == type,
                        onSelected: _isLoading
                            ? null
                            : (_) => setState(() => _type = type),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'feedback.message'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'feedback.error.message_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Uzun çeviriler taşmasın diye düğmeler Flexible içinde.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'common.cancel'.tr(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitFeedback,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'feedback.submit'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Herkese görünür; puana göre koşullu değil.
                TextButton.icon(
                  onPressed: _openPlayStoreListing,
                  icon: const Icon(Icons.star_outline),
                  label: Text('feedback.rate_on_play'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
