import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/cubit/marketplace_cubit.dart';

import 'fake_marketplace_repository.dart';

void main() {
  final club = AppConfig.reelsFirestoreClubTag.trim().toLowerCase();

  StoreProduct product({
    required String id,
    required int priceEgp,
    required int updatedAtMs,
    required int popularityScore,
    String audience = 'all',
    bool active = true,
  }) {
    return StoreProduct(
      id: id,
      merchantId: 'm1',
      ownerUid: 'u1',
      titleAr: 'منتج $id',
      description: '',
      priceEgp: priceEgp,
      imageUrl: '',
      active: active,
      updatedAtMs: updatedAtMs,
      audience: audience,
      popularityScore: popularityScore,
    );
  }

  MarketplaceMerchant merchant({
    required String id,
    required String nameAr,
    required int score,
    String slug = 's',
  }) {
    return MarketplaceMerchant(
      id: id,
      ownerUid: 'o',
      nameAr: nameAr,
      slug: slug,
      bio: '',
      coverUrl: '',
      logoUrl: '',
      audienceScore: score,
      createdAtMs: 0,
    );
  }

  group('MarketplaceState — خصائص العرض', () {
    test('filteredMerchants يطابق البحث على id وnameAr وslug', () {
      final m = [
        merchant(id: 'a1', nameAr: 'متجر القاهرة', score: 1, slug: 'cairo'),
        merchant(id: 'b2', nameAr: 'أسوان', score: 2, slug: 'aswan'),
      ];
      final s = MarketplaceState(merchants: m, searchQuery: 'cairo');
      expect(s.filteredMerchants.length, 1);
      expect(s.filteredMerchants.single.id, 'a1');
    });

    test('storefrontMerchants يرتب بالجمهور ثم الاسم', () {
      final m = [
        merchant(id: 'x', nameAr: 'ب', score: 5),
        merchant(id: 'y', nameAr: 'أ', score: 10),
      ];
      final s = MarketplaceState(merchants: m);
      expect(s.storefrontMerchants.first.id, 'y');
      expect(s.storefrontMerchants.last.nameAr, 'ب');
    });

    test('featuredMerchants يأخذ 12 كحد أقصى', () {
      final m = List.generate(
        20,
        (i) => merchant(id: '$i', nameAr: 'م$i', score: i),
      );
      final s = MarketplaceState(merchants: m);
      expect(s.featuredMerchants.length, 12);
    });

    test('processedProducts يفلتر غير النشط والجمهور غير المناسب للنادي الحالي', () {
      final otherAudience = club == 'zamalek' ? 'ahly' : 'zamalek';
      final products = [
        product(id: '1', priceEgp: 10, updatedAtMs: 1, popularityScore: 1, active: false),
        product(id: '2', priceEgp: 10, updatedAtMs: 2, popularityScore: 2, audience: otherAudience),
        product(id: '3', priceEgp: 10, updatedAtMs: 3, popularityScore: 3, audience: 'all'),
        product(id: '4', priceEgp: 10, updatedAtMs: 4, popularityScore: 4, audience: club),
      ];
      final s = MarketplaceState(latestProducts: products);
      final ids = s.processedProducts.map((p) => p.id).toList();
      expect(ids, contains('3'));
      expect(ids, contains('4'));
      expect(ids, isNot(contains('1')));
      expect(ids, isNot(contains('2')));
    });

    test('processedProducts مع audienceFilter: all يظلّ ظاهراً مع فلتر النادي', () {
      final products = [
        product(id: '1', priceEgp: 1, updatedAtMs: 1, popularityScore: 1, audience: 'all'),
        product(id: '2', priceEgp: 1, updatedAtMs: 2, popularityScore: 2, audience: club),
      ];
      final s = MarketplaceState(
        latestProducts: products,
        audienceFilter: club,
      );
      // منطق السوق: جمهور [all] يمرّ مع أي فلتر جمهور ضيّق
      expect(s.processedProducts.map((e) => e.id).toSet(), {'1', '2'});
    });

    test('processedProducts مع audienceFilter يستبعد غير المطابق', () {
      final other = club == 'zamalek' ? 'ahly' : 'zamalek';
      final products = [
        product(id: '1', priceEgp: 1, updatedAtMs: 1, popularityScore: 1, audience: club),
        product(id: '2', priceEgp: 1, updatedAtMs: 2, popularityScore: 2, audience: other),
      ];
      final s = MarketplaceState(
        latestProducts: products,
        audienceFilter: club,
      );
      expect(s.processedProducts.map((e) => e.id).toList(), ['1']);
    });

    test('processedProducts ترتيب new و price_asc و popular', () {
      final base = [
        product(id: 'a', priceEgp: 300, updatedAtMs: 100, popularityScore: 1, audience: 'all'),
        product(id: 'b', priceEgp: 100, updatedAtMs: 300, popularityScore: 10, audience: 'all'),
        product(id: 'c', priceEgp: 200, updatedAtMs: 200, popularityScore: 5, audience: 'all'),
      ];
      final popular = MarketplaceState(latestProducts: base, productSort: 'popular');
      expect(popular.processedProducts.first.id, 'b');

      final newest = MarketplaceState(latestProducts: base, productSort: 'new');
      expect(newest.processedProducts.first.id, 'b');

      final price = MarketplaceState(latestProducts: base, productSort: 'price_asc');
      expect(price.processedProducts.map((p) => p.id).join(), 'bca');
    });

    test('copyWith يحافظ على الحقول غير الممررة', () {
      final s0 = const MarketplaceState(searchQuery: 'x');
      final s1 = s0.copyWith(audienceFilter: 'ahly');
      expect(s1.searchQuery, 'x');
      expect(s1.audienceFilter, 'ahly');
    });

    test('props للمساواة', () {
      const a = MarketplaceState(searchQuery: 'q');
      const b = MarketplaceState(searchQuery: 'q');
      expect(a, b);
    });
  });

  group('MarketplaceCubit — تحديثات الواجهة', () {
    late FakeMarketplaceRepository repo;

    setUp(() {
      repo = FakeMarketplaceRepository();
    });

    tearDown(() async {
      if (!repo.merchantsCtrl.isClosed) await repo.merchantsCtrl.close();
      if (!repo.productsCtrl.isClosed) await repo.productsCtrl.close();
    });

    test('setSearchQuery و setAudienceFilter و setProductSort يحدثون الحالة', () async {
      final cubit = MarketplaceCubit(repository: repo);
      cubit.setSearchQuery('  test ');
      expect(cubit.state.searchQuery, '  test ');
      cubit.setAudienceFilter('ZAMALEK');
      expect(cubit.state.audienceFilter, 'zamalek');
      cubit.setProductSort('NEW');
      expect(cubit.state.productSort, 'new');
      await cubit.close();
    });

    test('repository getter', () async {
      final cubit = MarketplaceCubit(repository: repo);
      expect(cubit.repository, repo);
      await cubit.close();
    });
  });
}
