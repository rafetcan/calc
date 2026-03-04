class PurchaseService {
  Future<bool> get isAvailable async => false;

  Future<bool> purchaseSupport({
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    onError('Ödeme bu platformda desteklenmiyor');
    return false;
  }
}
