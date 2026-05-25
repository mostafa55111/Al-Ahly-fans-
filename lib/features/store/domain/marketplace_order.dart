import 'package:equatable/equatable.dart';

/// طلب شراء في السوق الموحد (Realtime Database).
class MarketplaceOrder extends Equatable {
  const MarketplaceOrder({
    required this.id,
    required this.buyerUid,
    required this.merchantId,
    required this.productId,
    required this.productTitleSnapshot,
    required this.status,
    required this.totalEgp,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String buyerUid;
  final String merchantId;
  final String productId;

  /// نسخة عنوان المنتج وقت الطلب (للإشعارات).
  final String productTitleSnapshot;
  final String status;
  final int totalEgp;
  final int createdAtMs;
  final int updatedAtMs;

  factory MarketplaceOrder.fromMap(String id, Map<dynamic, dynamic> m) {
    return MarketplaceOrder(
      id: id,
      buyerUid: m['buyerUid']?.toString() ?? '',
      merchantId: m['merchantId']?.toString() ?? '',
      productId: m['productId']?.toString() ?? '',
      productTitleSnapshot: m['productTitleSnapshot']?.toString() ?? '',
      status: m['status']?.toString() ?? 'pending',
      totalEgp: (m['totalEgp'] as num?)?.toInt() ?? 0,
      createdAtMs: (m['createdAt'] as num?)?.toInt() ??
          (m['createdAtMs'] as num?)?.toInt() ??
          0,
      updatedAtMs: (m['updatedAt'] as num?)?.toInt() ??
          (m['updatedAtMs'] as num?)?.toInt() ??
          0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        buyerUid,
        merchantId,
        productId,
        productTitleSnapshot,
        status,
        totalEgp,
        createdAtMs,
        updatedAtMs,
      ];
}
