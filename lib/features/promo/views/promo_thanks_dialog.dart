import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../services/promo_service.dart';

/// Reklam izlendikten sonra gösterilen teşekkür kartı; etkin kampanyadaki
/// uygulamayı tanıtır.
class PromoThanksDialog extends StatelessWidget {
  final PromoService promoService;

  const PromoThanksDialog({super.key, required this.promoService});

  @override
  Widget build(BuildContext context) {
    final name = promoService.campaign?.name ?? '';
    return AlertDialog(
      title: Text('support.thank_you'.tr()),
      content: Text('promo.new_app'.tr(namedArgs: {'name': name})),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('promo.close'.tr()),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            promoService.open('after_ad');
          },
          child: Text('promo.open'.tr()),
        ),
      ],
    );
  }
}
