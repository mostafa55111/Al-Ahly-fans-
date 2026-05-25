import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/cubit/marketplace_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/merchant_store_page.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/merchant_store_admin_page.dart';

/// واجهة السوق: متاجر مميزة حسب الجمهور + أحدث المنتجات + شبكة كل التجار.
class StoreMarketHomePage extends StatelessWidget {
  const StoreMarketHomePage({super.key});

  static const String _currentClubTag = 'ahly';

  bool _isVisibleForCurrentClub(StoreProduct p) {
    final tag = p.audience.trim().toLowerCase();
    return p.active && (tag.isEmpty || tag == 'all' || tag == _currentClubTag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'سوق جمهور الأهلي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateMerchant(context),
        icon: const Icon(Icons.store_mall_directory_outlined),
        label: Text('كن تاجراً',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.royalRed,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: context.read<MarketplaceCubit>().setSearchQuery,
                style: GoogleFonts.cairo(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المتجر أو المعرف أو الاسم المختصر…',
                  hintStyle: GoogleFonts.cairo(
                      color: AppColors.mediumGray, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.luminousGold),
                  filled: true,
                  fillColor: AppColors.mediumBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.luminousGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'المتاجر الأكثر حضوراً',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
              builder: (context, state) {
                final featured = state.featuredMerchants;
                if (featured.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Text(
                      'لا توجد متاجر بعد. كن أول تاجر عبر الزر أدناه ⬇',
                      style: GoogleFonts.cairo(
                          color: AppColors.mediumGray, height: 1.4),
                    ),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) =>
                        _FeaturedMerchantCard(merchant: featured[i]),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.royalRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'أحدث المنتجات في السوق',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
              builder: (context, state) {
                final products = state.latestProducts
                    .where(_isVisibleForCurrentClub)
                    .take(24)
                    .toList();
                if (products.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'ستظهر المنتجات هنا فور إضافتها من قبل التجار.',
                      style: GoogleFonts.cairo(color: AppColors.mediumGray),
                    ),
                  );
                }
                return SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) =>
                        _ProductPreviewCard(product: products[i]),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.luminousGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'كل المتاجر',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<MarketplaceCubit, MarketplaceState>(
            builder: (context, state) {
              final list = state.filteredMerchants;
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        state.searchQuery.trim().isEmpty
                            ? 'لا توجد متاجر مسجّلة بعد.'
                            : 'لا يوجد متجر يطابق البحث.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: AppColors.mediumGray),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _MerchantGridTile(merchant: list[index]),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateMerchant(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سجّل الدخول أولاً لإنشاء متجر.',
              style: GoogleFonts.cairo()),
        ),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final coverCtrl = TextEditingController();
    final logoCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إنشاء صفحة متجر',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ستملك صفحة عامة + رابط دعوة للمشاركة، ولوحة لإدارة منتجاتك.',
                  style: GoogleFonts.cairo(
                      color: AppColors.mediumGray, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _sheetField(nameCtrl, 'اسم المتجر *'),
                _sheetField(slugCtrl, 'اسم مختصر (اختياري) للبحث'),
                _sheetField(bioCtrl, 'نبذة'),
                _sheetField(coverCtrl, 'رابط صورة الغلاف (اختياري)'),
                _sheetField(logoCtrl, 'رابط الشعار (اختياري)'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      final repo = context.read<MarketplaceRepository>();
                      final id = await repo.createMerchant(
                        ownerUid: uid,
                        nameAr: nameCtrl.text,
                        slug: slugCtrl.text,
                        bio: bioCtrl.text,
                        coverUrl: coverCtrl.text,
                        logoUrl: logoCtrl.text,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RepositoryProvider.value(
                            value: repo,
                            child: MerchantStoreAdminPage(merchantId: id),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('$e', style: GoogleFonts.cairo())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('إنشاء',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sheetField(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: GoogleFonts.cairo(color: AppColors.white),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle:
              GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 13),
          filled: true,
          fillColor: AppColors.mediumBlack,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FeaturedMerchantCard extends StatelessWidget {
  const _FeaturedMerchantCard({required this.merchant});

  final MarketplaceMerchant merchant;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RepositoryProvider.value(
            value: repo,
            child: MerchantStorePage(merchantId: merchant.id),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.luminousGold.withValues(alpha: 0.35)),
          color: AppColors.mediumBlack,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: merchant.hasCover
                    ? CachedNetworkImage(
                        imageUrl: merchant.coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholderCover(),
                      )
                    : _placeholderCover(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'شعبية: ${merchant.audienceScore}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.luminousGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _placeholderCover() {
    return Container(
      color: AppColors.darkBlack,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, color: AppColors.royalRed, size: 40),
    );
  }
}

class _MerchantGridTile extends StatelessWidget {
  const _MerchantGridTile({required this.merchant});

  final MarketplaceMerchant merchant;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RepositoryProvider.value(
              value: repo,
              child: MerchantStorePage(merchantId: merchant.id),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.darkBlack,
            border:
                Border.all(color: AppColors.royalRed.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                  child: merchant.hasLogo
                      ? CachedNetworkImage(
                          imageUrl: merchant.logoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _ph(),
                        )
                      : _ph(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        '👥 ${merchant.audienceScore}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _ph() {
    return Container(
      color: AppColors.mediumBlack,
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined,
          color: AppColors.luminousGold),
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RepositoryProvider.value(
            value: repo,
            child: MerchantStorePage(merchantId: product.merchantId),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.mediumBlack,
          border: Border.all(color: AppColors.royalRed.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: product.hasImage
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _ph(),
                      )
                    : _ph(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.titleAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '${product.priceEgp} ج',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.luminousGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _ph() {
    return Container(
      color: AppColors.darkBlack,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.mediumGray),
    );
  }
}
