import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String _supportProductId = 'support_project';

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> get isAvailable async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _iap.isAvailable();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> purchaseSupport({
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      onError('Ödeme bu platformda desteklenmiyor');
      return false;
    }

    try {
      if (!await _iap.isAvailable()) {
        onError('Mağaza kullanılamıyor. Fiziksel cihazda ve Play Store ile test edin.');
        return false;
      }

      final response = await _iap.queryProductDetails({_supportProductId});
      if (response.notFoundIDs.isNotEmpty) {
        onError('Ürün bulunamadı. Play Console\'da "support_project" ürününü oluşturun.');
        return false;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);

      _subscription = _iap.purchaseStream.listen(
        (purchases) async => await _handlePurchases(purchases, onSuccess, onError),
        onDone: () => _subscription?.cancel(),
        onError: (e) => onError(e.toString()),
      );

      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        _subscription?.cancel();
        onError('Satın alma başlatılamadı');
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      _subscription?.cancel();
        if (e.code == 'channel-error' || e.message?.contains('connection') == true) {
        onError('Ödeme servisine bağlanılamadı. Lütfen fiziksel cihazda, Google Play yüklü ve uygulama test track\'te iken deneyin.');
      } else {
        onError(e.message ?? 'Ödeme başarısız');
      }
      return false;
    }
  }

  Future<void> _handlePurchases(
    List<PurchaseDetails> purchases,
    void Function() onSuccess,
    void Function(String) onError,
  ) async {
    for (final purchase in purchases) {
      if (purchase.productID != _supportProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          _subscription?.cancel();
          onSuccess();
          break;
        case PurchaseStatus.error:
          _subscription?.cancel();
          onError(purchase.error?.message ?? 'Ödeme başarısız');
          break;
        case PurchaseStatus.canceled:
          _subscription?.cancel();
          break;
      }
    }
  }
}
