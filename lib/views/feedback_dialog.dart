import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();
  bool _isLoading = false;
  String _selectedType = 'bug'; // varsayılan olarak hata bildirimi
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;

    if (_messageController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.errorEmptyMessage);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.errorEmptyEmail);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _errorMessage = l10n.errorInvalidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _feedbackService.submitFeedback(
        _selectedType,
        _messageController.text.trim(),
        _emailController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.thankYouFeedback),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.feedback, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'bug',
                  icon: const Icon(Icons.bug_report),
                  label: Text(l10n.bug),
                ),
                ButtonSegment(
                  value: 'suggestion',
                  icon: const Icon(Icons.lightbulb),
                  label: Text(l10n.suggestion),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                hintText: l10n.emailHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    _selectedType == 'bug'
                        ? l10n.bugDescription
                        : l10n.suggestionDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(l10n.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
