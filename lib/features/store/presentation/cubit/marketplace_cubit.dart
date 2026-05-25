import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';

class MarketplaceState extends Equatable {
  const MarketplaceState({
    this.merchants = const [],
    this.latestProducts = const [],
    this.searchQuery = '',
    this.audienceFilter = 'all',
    this.productSort = 'popular',
  });

  final List<MarketplaceMerchant> merchants;
  final List<StoreProduct> latestProducts;
  final String searchQuery;

  /// `all` | `zamalek` | `ahly` — فلتر منتجات حسب الجمهور المستهدف.
  final String audienceFilter;

  /// `popular` | `new` | `price_asc`
  final String productSort;

  List<MarketplaceMerchant> get filteredMerchants {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return merchants;
    return merchants.where((m) {
      final idHit = m.id.toLowerCase().contains(q);
      final nameHit = m.nameAr.toLowerCase().contains(q);
      final slugHit = m.slug.toLowerCase().contains(q);
      return idHit || nameHit || slugHit;
    }).toList(growable: false);
  }

  /// واجهات البطريات — ترتيب حسب الحضور ثم الاسم.
  List<MarketplaceMerchant> get storefrontMerchants {
    final list = List<MarketplaceMerchant>.from(filteredMerchants);
    list.sort((a, b) {
      final c = b.audienceScore.compareTo(a.audienceScore);
      if (c != 0) return c;
      return a.nameAr.compareTo(b.nameAr);
    });
    return list;
  }

  /// الأكبر جمهوراً أولاً (لشريط المقدمة).
  List<MarketplaceMerchant> get featuredMerchants {
    final list = List<MarketplaceMerchant>.from(merchants);
    list.sort((a, b) {
      final c = b.audienceScore.compareTo(a.audienceScore);
      if (c != 0) return c;
      return a.nameAr.compareTo(b.nameAr);
    });
    return list.take(12).toList(growable: false);
  }

  /// منتجات مفعّلة ومناسبة لتطبيق النادي الحالي، مع فلتر الجمهور وترتيب popularity_score.
  List<StoreProduct> get processedProducts {
    final club = AppConfig.reelsFirestoreClubTag.trim().toLowerCase();
    var list = latestProducts.where((p) {
      if (!p.active) return false;
      final a = p.audience.trim().toLowerCase();
      return a.isEmpty || a == 'all' || a == club;
    }).toList();

    if (audienceFilter != 'all') {
      final f = audienceFilter.trim().toLowerCase();
      list = list
          .where((p) {
            final a = p.audience.trim().toLowerCase();
            return a == 'all' || a == f;
          })
          .toList();
    }

    final sorted = List<StoreProduct>.from(list);
    switch (productSort) {
      case 'new':
        sorted.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.priceEgp.compareTo(b.priceEgp));
        break;
      default:
        sorted.sort((a, b) {
          final c = b.popularityScore.compareTo(a.popularityScore);
          if (c != 0) return c;
          return b.updatedAtMs.compareTo(a.updatedAtMs);
        });
    }
    return sorted;
  }

  MarketplaceState copyWith({
    List<MarketplaceMerchant>? merchants,
    List<StoreProduct>? latestProducts,
    String? searchQuery,
    String? audienceFilter,
    String? productSort,
  }) {
    return MarketplaceState(
      merchants: merchants ?? this.merchants,
      latestProducts: latestProducts ?? this.latestProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      audienceFilter: audienceFilter ?? this.audienceFilter,
      productSort: productSort ?? this.productSort,
    );
  }

  @override
  List<Object?> get props =>
      [merchants, latestProducts, searchQuery, audienceFilter, productSort];
}

class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit({required MarketplaceRepository repository})
      : _repository = repository,
        super(const MarketplaceState()) {
    _mSub = _repository.watchMerchants().listen(
          (list) => emit(state.copyWith(merchants: list)),
        );
    _pSub = _repository.watchLatestProducts().listen(
          (list) => emit(state.copyWith(latestProducts: list)),
        );
  }

  final MarketplaceRepository _repository;
  StreamSubscription<List<MarketplaceMerchant>>? _mSub;
  StreamSubscription<List<StoreProduct>>? _pSub;

  MarketplaceRepository get repository => _repository;

  void setSearchQuery(String q) => emit(state.copyWith(searchQuery: q));

  void setAudienceFilter(String v) =>
      emit(state.copyWith(audienceFilter: v.trim().toLowerCase()));

  void setProductSort(String v) =>
      emit(state.copyWith(productSort: v.trim().toLowerCase()));

  @override
  Future<void> close() {
    // إلغاء اشتراكات [watchMerchants] / [watchLatestProducts] — يمنع تسريب بعد dispose للكيوبت.
    _mSub?.cancel();
    _pSub?.cancel();
    return super.close();
  }
}
