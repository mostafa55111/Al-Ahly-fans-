import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/core/widgets/club_badge.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/cubit/marketplace_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/merchant_store_admin_page.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/merchant_store_page.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// واجهة السوق الموحّدة — بحث، فلاتر، بطريات التجار، ومنتجات مرتبة بـ [popularity_score].
class MainMarketplacePage extends StatelessWidget {
  const MainMarketplacePage({super.key, this.title = 'Fan Store'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.deepBlack,
        foregroundColor: primary,
      ),
      floatingActionButton: CustomFAB(
        isExtended: true,
        icon: Icons.store_mall_directory_outlined,
        label: 'كن تاجراً',
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        semanticsLabel: 'زر التسجيل كتاجر وإنشاء متجر',
        backgroundColor: primary.withValues(alpha: 0.15),
        foregroundColor: primary,
        onPressed: () => _openCreateMerchant(context),
      ),
      body: BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    onChanged: context.read<MarketplaceCubit>().setSearchQuery,
                    style: GoogleFonts.cairo(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن متجر أو منتج…',
                      hintStyle: GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: primary),
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
              SliverToBoxAdapter(child: _FilterChipsRow(primary: primary)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'بطريات التجار',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _StorefrontsStrip(primary: primary)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المنتجات (حسب الشعبية)',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ProductGridSliver(primary: primary),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreateMerchant(BuildContext context) async {
    final uidByFirebase = FirebaseAuth.instance.currentUser?.uid;
    if (uidByFirebase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('سجّل الدخول أولاً.', style: GoogleFonts.cairo())),
      );
      return;
    }
    final repo = context.read<MarketplaceRepository>();
    final ok = await repo.isVendorAccountActive(uidByFirebase);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حساب البائع غير مفعّل. تواصل مع الإدارة لتفعيل صلاحية vendor.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;

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
                  'إنشاء متجر',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _sheetField(nameCtrl, 'اسم المتجر *'),
                _sheetField(slugCtrl, 'اسم مختصر (اختياري)'),
                _sheetField(bioCtrl, 'نبذة'),
                _sheetField(coverCtrl, 'رابط الغلاف'),
                _sheetField(logoCtrl, 'رابط الشعار'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      final id = await repo.createMerchant(
                        ownerUid: uidByFirebase,
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
                        SnackBar(content: Text('$e', style: GoogleFonts.cairo())),
                      );
                    }
                  },
                  child: Text('إنشاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
          labelStyle: GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 13),
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

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MarketplaceCubit>();
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فلتر الجمهور',
                style: GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _audChip(context, state, cubit, 'all', 'الكل'),
                  _audChip(context, state, cubit, 'ahly', 'الأهلي'),
                  _audChip(context, state, cubit, 'zamalek', 'الزمالك'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'الترتيب',
                style: GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortChip(context, state, cubit, 'popular', 'الأكثر شعبية'),
                  _sortChip(context, state, cubit, 'new', 'الأحدث'),
                  _sortChip(context, state, cubit, 'price_asc', 'السعر ↑'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _audChip(
    BuildContext context,
    MarketplaceState state,
    MarketplaceCubit cubit,
    String value,
    String label,
  ) {
    final sel = state.audienceFilter == value;
    return FilterChip(
      label: Text(label, style: GoogleFonts.cairo()),
      selected: sel,
      onSelected: (_) => cubit.setAudienceFilter(value),
      selectedColor: primary.withValues(alpha: 0.35),
      checkmarkColor: primary,
      labelStyle: GoogleFonts.cairo(color: sel ? Colors.white : AppColors.mediumGray),
    );
  }

  Widget _sortChip(
    BuildContext context,
    MarketplaceState state,
    MarketplaceCubit cubit,
    String value,
    String label,
  ) {
    final sel = state.productSort == value;
    return FilterChip(
      label: Text(label, style: GoogleFonts.cairo()),
      selected: sel,
      onSelected: (_) => cubit.setProductSort(value),
      selectedColor: primary.withValues(alpha: 0.35),
      checkmarkColor: primary,
      labelStyle: GoogleFonts.cairo(color: sel ? Colors.white : AppColors.mediumGray),
    );
  }
}

class _StorefrontsStrip extends StatelessWidget {
  const _StorefrontsStrip({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final list = state.storefrontMerchants;
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'لا متاجر تطابق البحث.',
              style: GoogleFonts.cairo(color: AppColors.mediumGray),
            ),
          );
        }
        return SizedBox(
          height: 108,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemExtent: 172,
            itemCount: list.length,
            itemBuilder: (context, i) {
              return RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 160,
                    child: _StorefrontChip(merchant: list[i], primary: primary),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StorefrontChip extends StatelessWidget {
  const _StorefrontChip({required this.merchant, required this.primary});

  final MarketplaceMerchant merchant;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    return Material(
      color: AppColors.mediumBlack,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RepositoryProvider.value(
                value: repo,
                child: MerchantStorePage(merchantId: merchant.id),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withValues(alpha: 0.2),
                backgroundImage: merchant.hasLogo ? CachedNetworkImageProvider(merchant.logoUrl) : null,
                child: !merchant.hasLogo
                    ? Icon(Icons.store_rounded, color: primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            merchant.nameAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ClubBadge(appSource: merchant.appSource, size: 16),
                      ],
                    ),
                    Text(
                      'ادخل المتجر ←',
                      style: GoogleFonts.cairo(color: primary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductGridSliver extends StatelessWidget {
  const _ProductGridSliver({required this.primary});

  final Color primary;

  /// ارتفاع ثابت لصفّ منتجين — يُسرّع تخطيط السحب (Robo / 60 FPS).
  static const double _rowExtent = 272;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final products = state.processedProducts;
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'لا منتجات حالياً.',
                  style: GoogleFonts.cairo(color: AppColors.mediumGray),
                ),
              ),
            ),
          );
        }
        final rowCount = (products.length + 1) ~/ 2;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverFixedExtentList(
            itemExtent: _rowExtent,
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final left = rowIndex * 2;
                final right = left + 1;
                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ProductTile(
                            product: products[left],
                            primary: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: right < products.length
                              ? _ProductTile(
                                  product: products[right],
                                  primary: primary,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.primary});

  final StoreProduct product;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    return Material(
      color: AppColors.mediumBlack,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openProductSheet(context, repo, product),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: product.hasImage
                    ? CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover)
                    : Container(
                        alignment: Alignment.center,
                        color: AppColors.darkBlack,
                        child: Icon(Icons.image_outlined, color: primary),
                      ),
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
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'شعبية ${product.popularityScore}',
                    style: GoogleFonts.cairo(fontSize: 10, color: AppColors.mediumGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductSheet(
    BuildContext context,
    MarketplaceRepository repo,
    StoreProduct product,
  ) async {
    await repo.recordProductView(product.id);
    if (!context.mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.titleAr,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${product.priceEgp} ج.م',
                style: GoogleFonts.cairo(fontSize: 16, color: primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<MarketplaceMerchant?>(
                future: repo.getMerchant(product.merchantId),
                builder: (ctx, ms) {
                  final merchant = ms.data;
                  final badgeSrc = (merchant?.appSource != null &&
                          merchant!.appSource!.trim().isNotEmpty)
                      ? merchant.appSource
                      : audienceToClubSource(product.audience);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined,
                          color: primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: UserNameWithClubBadge(
                          name: merchant?.nameAr ?? 'التاجر',
                          appSource: badgeSrc,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightGray,
                          ),
                          badgeSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'شراء المنتج ${product.titleAr}',
                button: true,
                child: Tooltip(
                  message: 'شراء المنتج بسعر ${product.priceEgp} ج.م',
                  child: FilledButton.icon(
                    onPressed: uid == null
                        ? null
                        : () async {
                            try {
                              final id = await repo.placeOrder(buyerUid: uid, productId: product.id);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم تسجيل الطلب $id — ستصلك تحديثات الحالة عبر الإشعارات.',
                                    style: GoogleFonts.cairo(),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('$e', style: GoogleFonts.cairo())),
                              );
                            }
                          },
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text('شراء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: primary),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RepositoryProvider.value(
                        value: repo,
                        child: MerchantStorePage(merchantId: product.merchantId),
                      ),
                    ),
                  );
                },
                child: Text('عرض متجر التاجر', style: GoogleFonts.cairo(color: primary)),
              ),
            ],
          ),
        );
      },
    );
  }
}
