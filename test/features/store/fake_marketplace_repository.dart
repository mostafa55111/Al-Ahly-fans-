import 'dart:async';

import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_order.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';

/// مستودع وهمي للاختبارات — يبثّ [watchMerchants] و [watchLatestProducts] فقط.
class FakeMarketplaceRepository implements MarketplaceRepository {
  FakeMarketplaceRepository() {
    merchantsCtrl = StreamController<List<MarketplaceMerchant>>.broadcast();
    productsCtrl = StreamController<List<StoreProduct>>.broadcast();
  }

  late final StreamController<List<MarketplaceMerchant>> merchantsCtrl;
  late final StreamController<List<StoreProduct>> productsCtrl;

  @override
  Stream<List<MarketplaceMerchant>> watchMerchants() => merchantsCtrl.stream;

  @override
  Stream<List<StoreProduct>> watchLatestProducts({int limit = 36}) =>
      productsCtrl.stream;

  @override
  Stream<List<StoreProduct>> watchProductsForMerchant(String merchantId) =>
      const Stream.empty();

  @override
  Future<MarketplaceMerchant?> getMerchant(String merchantId) async => null;

  @override
  Stream<MarketplaceMerchant?> watchMerchant(String merchantId) =>
      const Stream.empty();

  @override
  Future<String> createMerchant({
    required String ownerUid,
    required String nameAr,
    String slug = '',
    String bio = '',
    String coverUrl = '',
    String logoUrl = '',
  }) async =>
      '';

  @override
  Future<void> updateMerchant({
    required String merchantId,
    required String ownerUid,
    required String nameAr,
    String slug = '',
    String bio = '',
    String coverUrl = '',
    String logoUrl = '',
  }) async {}

  @override
  Future<String> createProduct({
    required String merchantId,
    required String ownerUid,
    required String titleAr,
    String description = '',
    required int priceEgp,
    String imageUrl = '',
    bool active = true,
    String audience = 'all',
  }) async =>
      '';

  @override
  Future<void> updateProduct({
    required String productId,
    required String ownerUid,
    required String titleAr,
    String description = '',
    required int priceEgp,
    String imageUrl = '',
    bool active = true,
    String audience = 'all',
  }) async {}

  @override
  Future<void> deleteProduct({
    required String productId,
    required String ownerUid,
  }) async {}

  @override
  Future<void> recordProductView(String productId) async {}

  @override
  Future<String> placeOrder({
    required String buyerUid,
    required String productId,
  }) async =>
      '';

  @override
  Stream<List<MarketplaceOrder>> watchOrdersForBuyer(String buyerUid) =>
      const Stream.empty();

  @override
  Future<void> activateVendorAccount({
    required String targetUid,
    required String adminUid,
  }) async {}

  @override
  Future<bool> isVendorAccountActive(String uid) async => false;

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String actorUid,
  }) async {}
}
