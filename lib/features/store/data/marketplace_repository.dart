import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_order.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';

/// مستودع السوق — يوفّر البيانات كـ [Stream] دون الاحتفاظ باشتراكات داخلية.
///
/// أي كود يستدعي [Stream.listen] على هذه التدفقات **يجب** أن يستدعي
/// [StreamSubscription.cancel] عند التخلّص (مثال: [MarketplaceCubit.close]).
abstract class MarketplaceRepository {
  Stream<List<MarketplaceMerchant>> watchMerchants();

  /// أحدث المنتجات عبر السوق (للمقدمة).
  Stream<List<StoreProduct>> watchLatestProducts({int limit});

  Stream<List<StoreProduct>> watchProductsForMerchant(String merchantId);

  Future<MarketplaceMerchant?> getMerchant(String merchantId);

  Stream<MarketplaceMerchant?> watchMerchant(String merchantId);

  Future<String> createMerchant({
    required String ownerUid,
    required String nameAr,
    String slug,
    String bio,
    String coverUrl,
    String logoUrl,
  });

  Future<void> updateMerchant({
    required String merchantId,
    required String ownerUid,
    required String nameAr,
    String slug,
    String bio,
    String coverUrl,
    String logoUrl,
  });

  Future<String> createProduct({
    required String merchantId,
    required String ownerUid,
    required String titleAr,
    String description,
    required int priceEgp,
    String imageUrl,
    bool active,
    String audience,
  });

  Future<void> updateProduct({
    required String productId,
    required String ownerUid,
    required String titleAr,
    String description,
    required int priceEgp,
    String imageUrl,
    bool active,
    String audience,
  });

  Future<void> deleteProduct({
    required String productId,
    required String ownerUid,
  });

  /// تسجيل مشاهدة للمنتج (يزيد popularity_score).
  Future<void> recordProductView(String productId);

  /// طلب شراء — يزيد sales_count ويُنشئ سجل طلب (يُرسل إشعاراً عبر FCM من الخادم أو محلياً عبر مستمع RTDB).
  Future<String> placeOrder({
    required String buyerUid,
    required String productId,
  });

  Stream<List<MarketplaceOrder>> watchOrdersForBuyer(String buyerUid);

  /// تفعيل صلاحية البائع في `all/marketplace/vendor_accounts/{uid}` (لوحة الإدارة).
  Future<void> activateVendorAccount({
    required String targetUid,
    required String adminUid,
  });

  Future<bool> isVendorAccountActive(String uid);

  /// تحديث حالة الطلب (تاجر/أدمن) — يحدّث `updatedAt` ليستقبل المشتري إشعار FCM/محلي.
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String actorUid,
  });
}
