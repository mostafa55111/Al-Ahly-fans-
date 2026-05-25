/// مسارات Realtime Database الموحّدة لسوق الجمهور — نفس المسار في تطبيقي الأهلي والزمالك.
///
/// ```
/// all/marketplace/
///   merchants/{merchantId}
///   products/{productId}
///   orders/{orderId}
///   vendor_accounts/{uid}   ← تفعيل البائع من لوحة الإدارة
/// ```
class MarketplaceRtdbPaths {
  static const String root = 'all/marketplace';
  static const String merchants = '$root/merchants';
  static const String products = '$root/products';
  static const String orders = '$root/orders';
  static const String vendorAccounts = '$root/vendor_accounts';

  static String merchant(String id) => '$merchants/$id';
  static String product(String id) => '$products/$id';
  static String order(String id) => '$orders/$id';
  static String vendorAccount(String uid) => '$vendorAccounts/$uid';
}
