import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../services/support_state_service.dart';
import '../services/purchase_service.dart';
import '../../../core/di/locator.dart';

class _AppItem {
  final String emoji;
  final String title;
  final String? storeUrl;

  const _AppItem(this.emoji, this.title, [this.storeUrl]);
}

class SupportDialog extends StatefulWidget {
  final AdService adService;
  final VoidCallback? onSupportSuccess;

  const SupportDialog({
    super.key,
    required this.adService,
    this.onSupportSuccess,
  });

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  bool _isLoading = false;
  bool _isPurchasing = false;

  static const _akideSoftDeveloperUrl =
      'https://play.google.com/store/apps/developer?id=AkideSoft';
  // Hikayeler ve Masallar uygulama sayfası - package ID'yi güncelleyin
  static const _storiesAppUrl =
      'https://play.google.com/store/apps/details?id=com.rafethokka.stories_and_tales';

  static List<_AppItem> _getApps() => [
    _AppItem('📖', 'support.app_stories'.tr(), _storiesAppUrl),
    _AppItem('📱', 'support.other_apps'.tr(), _akideSoftDeveloperUrl),
  ];

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onWatchAdTap() async {
    setState(() => _isLoading = true);

    final shown = await widget.adService.showRewardedAd(
      onRewarded: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('support.thank_you'.tr())),
          );
          Navigator.pop(context);
        }
      },
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('support.ad_error'.tr())),
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!shown) Navigator.pop(context);
    }
  }

  Future<void> _onSupportProjectTap() async {
    final supportState = context.read<SupportStateService>();
    if (supportState.hasSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('support.already_supported'.tr())),
        );
      }
      return;
    }

    setState(() => _isPurchasing = true);

    final purchaseService = getIt.get<PurchaseService>();
    await purchaseService.purchaseSupport(
      onSuccess: () async {
        if (!mounted) return;
        await supportState.setSupported();
        widget.onSupportSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('support.thank_you'.tr())),
          );
          Navigator.pop(context);
        }
      },
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      },
    );

    if (mounted) setState(() => _isPurchasing = false);
  }

  @override
  void initState() {
    super.initState();
    widget.adService.loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportState = context.read<SupportStateService>();

    return AlertDialog(
      title: Text(
        'support.akidesoft_apps'.tr(),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Uygulama listesi
            ..._getApps().map((app) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(app.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(app.title),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _launchUrl(app.storeUrl),
                )),
            const Divider(height: 24),
            // Alt kısım - destek seçenekleri (küçük)
            Text(
              'support.support_section'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading || _isPurchasing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              InkWell(
                onTap: (_isLoading || _isPurchasing) ? null : _onWatchAdTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text('❤️', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'support.watch_ad_support'.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: supportState.hasSupported ? null : _onSupportProjectTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text('❤️', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'support.support_project'.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
      ],
    );
  }
}
