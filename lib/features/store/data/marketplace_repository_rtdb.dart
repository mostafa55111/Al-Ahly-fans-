import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_order.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';

class MarketplaceRepositoryRtdb implements MarketplaceRepository {
  MarketplaceRepositoryRtdb(this._db);

  /// مرجع قاعدة البيانات فقط — لا توجد [StreamSubscription] هنا؛ الإلغاء على عاتق المستهلك.
  final FirebaseDatabase _db;

  DatabaseReference get _root => _db.ref();

  List<MarketplaceMerchant> _parseMerchants(Map<dynamic, dynamic>? raw) {
    if (raw == null) return const [];
    final out = <MarketplaceMerchant>[];
    raw.forEach((key, value) {
      if (key is! String || value is! Map) return;
      out.add(
          MarketplaceMerchant.fromMap(key, Map<dynamic, dynamic>.from(value)));
    });
    out.sort((a, b) {
      final c = b.audienceScore.compareTo(a.audienceScore);
      if (c != 0) return c;
      return a.nameAr.compareTo(b.nameAr);
    });
    return out;
  }

  List<StoreProduct> _parseProducts(Map<dynamic, dynamic>? raw) {
    if (raw == null) return const [];
    final out = <StoreProduct>[];
    raw.forEach((key, value) {
      if (key is! String || value is! Map) return;
      out.add(StoreProduct.fromMap(key, Map<dynamic, dynamic>.from(value)));
    });
    out.sort((a, b) {
      final c = b.popularityScore.compareTo(a.popularityScore);
      if (c != 0) return c;
      return b.updatedAtMs.compareTo(a.updatedAtMs);
    });
    return out;
  }

  @override
  Stream<List<MarketplaceMerchant>> watchMerchants() {
    return _root.child(MarketplaceRtdbPaths.merchants).onValue.map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return const <MarketplaceMerchant>[];
      return _parseMerchants(Map<dynamic, dynamic>.from(v));
    });
  }

  @override
  Stream<List<StoreProduct>> watchLatestProducts({int limit = 36}) {
    return _root
        .child(MarketplaceRtdbPaths.products)
        .orderByChild('updatedAt')
        .limitToLast(limit)
        .onValue
        .map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return const <StoreProduct>[];
      return _parseProducts(Map<dynamic, dynamic>.from(v));
    });
  }

  @override
  Stream<List<StoreProduct>> watchProductsForMerchant(String merchantId) {
    return _root
        .child(MarketplaceRtdbPaths.products)
        .orderByChild('merchantId')
        .equalTo(merchantId)
        .onValue
        .map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return const <StoreProduct>[];
      return _parseProducts(Map<dynamic, dynamic>.from(v));
    });
  }

  @override
  Stream<MarketplaceMerchant?> watchMerchant(String merchantId) {
    return _root
        .child(MarketplaceRtdbPaths.merchant(merchantId))
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value is! Map) return null;
      return MarketplaceMerchant.fromMap(
        merchantId,
        Map<dynamic, dynamic>.from(e.snapshot.value! as Map),
      );
    });
  }

  @override
  Future<MarketplaceMerchant?> getMerchant(String merchantId) async {
    final snap =
        await _root.child(MarketplaceRtdbPaths.merchant(merchantId)).get();
    if (!snap.exists || snap.value is! Map) return null;
    return MarketplaceMerchant.fromMap(
      merchantId,
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<String> createMerchant({
    required String ownerUid,
    required String nameAr,
    String slug = '',
    String bio = '',
    String coverUrl = '',
    String logoUrl = '',
  }) async {
    final ref = _root.child(MarketplaceRtdbPaths.merchants).push();
    final id = ref.key;
    if (id == null) throw StateError('تعذر إنشاء معرف المتجر');
    await ref.set({
      'ownerUid': ownerUid,
      'nameAr': nameAr.trim(),
      'slug': slug.trim(),
      'bio': bio.trim(),
      'coverUrl': coverUrl.trim(),
      'logoUrl': logoUrl.trim(),
      'audienceScore': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  @override
  Future<void> updateMerchant({
    required String merchantId,
    required String ownerUid,
    required String nameAr,
    String slug = '',
    String bio = '',
    String coverUrl = '',
    String logoUrl = '',
  }) async {
    final ref = _root.child(MarketplaceRtdbPaths.merchant(merchantId));
    final snap = await ref.get();
    if (!snap.exists || snap.value is! Map) {
      throw StateError('المتجر غير موجود');
    }
    final m = MarketplaceMerchant.fromMap(
      merchantId,
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
    if (m.ownerUid != ownerUid) throw StateError('غير مصرح بتعديل هذا المتجر');
    await ref.update({
      'nameAr': nameAr.trim(),
      'slug': slug.trim(),
      'bio': bio.trim(),
      'coverUrl': coverUrl.trim(),
      'logoUrl': logoUrl.trim(),
    });
  }

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
  }) async {
    final ref = _root.child(MarketplaceRtdbPaths.products).push();
    final id = ref.key;
    if (id == null) throw StateError('تعذر إنشاء المنتج');
    await ref.set({
      'merchantId': merchantId,
      'ownerUid': ownerUid,
      'titleAr': titleAr.trim(),
      'description': description.trim(),
      'priceEgp': priceEgp,
      'imageUrl': imageUrl.trim(),
      'active': active,
      'audience': audience.trim().toLowerCase(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'viewCount': 0,
      'salesCount': 0,
      'popularityScore': 0,
    });
    return id;
  }

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
  }) async {
    final ref = _root.child(MarketplaceRtdbPaths.product(productId));
    final snap = await ref.get();
    if (!snap.exists || snap.value is! Map) {
      throw StateError('المنتج غير موجود');
    }
    final p = StoreProduct.fromMap(
      productId,
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
    if (p.ownerUid != ownerUid) throw StateError('غير مصرح بتعديل هذا المنتج');
    await ref.update({
      'titleAr': titleAr.trim(),
      'description': description.trim(),
      'priceEgp': priceEgp,
      'imageUrl': imageUrl.trim(),
      'active': active,
      'audience': audience.trim().toLowerCase(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> deleteProduct({
    required String productId,
    required String ownerUid,
  }) async {
    final ref = _root.child(MarketplaceRtdbPaths.product(productId));
    final snap = await ref.get();
    if (!snap.exists || snap.value is! Map) return;
    final p = StoreProduct.fromMap(
      productId,
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
    if (p.ownerUid != ownerUid) throw StateError('غير مصرح بحذف هذا المنتج');
    await ref.remove();
  }

  @override
  Future<void> recordProductView(String productId) async {
    if (productId.trim().isEmpty) return;
    final pref = _root.child(MarketplaceRtdbPaths.product(productId));
    final result = await pref.runTransaction((mutableData) {
      if (mutableData == null) return Transaction.abort();
      final md = mutableData as dynamic;
      final current = md.value as Object?;
      if (current is! Map) return Transaction.abort();
      final full = Map<String, dynamic>.from(
        current.map((k, v) => MapEntry(k.toString(), v)),
      );
      final v = (full['viewCount'] as num?)?.toInt() ?? 0;
      final s = (full['salesCount'] as num?)?.toInt() ?? 0;
      full['viewCount'] = v + 1;
      full['popularityScore'] = StoreProduct.computePopularityScore(s, v + 1);
      full['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      md.value = full;
      return Transaction.success(mutableData);
    });
    if (!result.committed) {
      // منتج محذوف أو بيانات غير متوقعة — نتجاهل بصمت
    }
  }

  @override
  Future<String> placeOrder({
    required String buyerUid,
    required String productId,
  }) async {
    if (buyerUid.trim().isEmpty) {
      throw StateError('تسجيل الدخول مطلوب للشراء');
    }
    final pref = _root.child(MarketplaceRtdbPaths.product(productId));
    final psnap = await pref.get();
    if (!psnap.exists || psnap.value is! Map) {
      throw StateError('المنتج غير موجود');
    }
    final p = StoreProduct.fromMap(
      productId,
      Map<dynamic, dynamic>.from(psnap.value! as Map),
    );
    if (!p.active) throw StateError('المنتج غير متاح');

    final orderRef = _root.child(MarketplaceRtdbPaths.orders).push();
    final oid = orderRef.key;
    if (oid == null) throw StateError('تعذر إنشاء الطلب');
    final now = DateTime.now().millisecondsSinceEpoch;

    final tx = await pref.runTransaction((mutableData) {
      if (mutableData == null) return Transaction.abort();
      final md = mutableData as dynamic;
      final current = md.value as Object?;
      if (current is! Map) return Transaction.abort();
      final full = Map<String, dynamic>.from(
        current.map((k, v) => MapEntry(k.toString(), v)),
      );
      final active = full['active'] == true || full['active'] == 1;
      if (!active) return Transaction.abort();
      final s = (full['salesCount'] as num?)?.toInt() ?? 0;
      final v = (full['viewCount'] as num?)?.toInt() ?? 0;
      full['salesCount'] = s + 1;
      full['popularityScore'] = StoreProduct.computePopularityScore(s + 1, v);
      full['updatedAt'] = now;
      md.value = full;
      return Transaction.success(mutableData);
    });

    if (!tx.committed) {
      throw StateError('تعذر تأكيد الشراء (قد يكون المنتج غير متاح)');
    }

    await orderRef.set({
      'buyerUid': buyerUid,
      'merchantId': p.merchantId,
      'productId': productId,
      'productTitleSnapshot': p.titleAr,
      'status': 'pending',
      'totalEgp': p.priceEgp,
      'createdAt': now,
      'updatedAt': now,
    });
    return oid;
  }

  @override
  Stream<List<MarketplaceOrder>> watchOrdersForBuyer(String buyerUid) {
    return _root
        .child(MarketplaceRtdbPaths.orders)
        .orderByChild('buyerUid')
        .equalTo(buyerUid)
        .onValue
        .map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return const <MarketplaceOrder>[];
      final out = <MarketplaceOrder>[];
      for (final entry in v.entries) {
        final key = entry.key?.toString();
        final val = entry.value;
        if (key == null || val is! Map) continue;
        out.add(MarketplaceOrder.fromMap(key, Map<dynamic, dynamic>.from(val)));
      }
      out.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      return out;
    });
  }

  @override
  Future<void> activateVendorAccount({
    required String targetUid,
    required String adminUid,
  }) async {
    if (targetUid.trim().isEmpty) return;
    await _root.child(MarketplaceRtdbPaths.vendorAccount(targetUid)).set({
      'active': true,
      'activatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'activatedByUid': adminUid,
    });
  }

  @override
  Future<bool> isVendorAccountActive(String uid) async {
    final s = await _root.child(MarketplaceRtdbPaths.vendorAccount(uid)).get();
    if (!s.exists) return false;
    final v = s.value;
    if (v is Map) {
      return v['active'] == true || v['active'] == 1;
    }
    return v == true || v == 1;
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String actorUid,
  }) async {
    if (orderId.trim().isEmpty || newStatus.trim().isEmpty) return;
    final ref = _root.child(MarketplaceRtdbPaths.order(orderId));
    final snap = await ref.get();
    if (!snap.exists || snap.value is! Map) return;
    final order = MarketplaceOrder.fromMap(
      orderId,
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
    final merchant = await getMerchant(order.merchantId);
    if (merchant == null) return;
    if (merchant.ownerUid != actorUid) {
      throw StateError('غير مصرّح بتحديث هذا الطلب');
    }
    await ref.update({
      'status': newStatus.trim().toLowerCase(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
