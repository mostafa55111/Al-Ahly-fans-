import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/cubit/marketplace_cubit.dart';

import 'fake_marketplace_repository.dart';

void main() {
  group('MarketplaceCubit — إغلاق الاشتراكات (dispose / close)', () {
    late FakeMarketplaceRepository repo;

    setUp(() {
      repo = FakeMarketplaceRepository();
    });

    tearDown(() async {
      if (!repo.merchantsCtrl.isClosed) await repo.merchantsCtrl.close();
      if (!repo.productsCtrl.isClosed) await repo.productsCtrl.close();
    });

    test('بعد close لا يبقى مستمعون على تدفّقي التجار والمنتجات', () async {
      expect(repo.merchantsCtrl.hasListener, isFalse);
      expect(repo.productsCtrl.hasListener, isFalse);

      final cubit = MarketplaceCubit(repository: repo);

      expect(repo.merchantsCtrl.hasListener, isTrue);
      expect(repo.productsCtrl.hasListener, isTrue);

      await cubit.close();

      expect(repo.merchantsCtrl.hasListener, isFalse);
      expect(repo.productsCtrl.hasListener, isFalse);
    });

    test('حدث على التدفّق بعد close لا يُحدّث الكيوبت (لا استثناء)', () async {
      final cubit = MarketplaceCubit(repository: repo);
      await cubit.close();

      expect(() {
        repo.merchantsCtrl.add(const <MarketplaceMerchant>[]);
        repo.productsCtrl.add(const <StoreProduct>[]);
      }, returnsNormally);
    });
  });
}
