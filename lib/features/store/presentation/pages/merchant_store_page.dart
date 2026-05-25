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
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/merchant_store_admin_page.dart';
import 'package:gomhor_alahly_clean_new/features/store/services/marketplace_share.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// صفحة تاجر عامة — عرض المتجر والمنتجات + مشاركة للترويج.
class MerchantStorePage extends StatelessWidget {
  const MerchantStorePage({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<MarketplaceMerchant?>(
      stream: repo.watchMerchant(merchantId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.deepBlack,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.royalRed)),
          );
        }
        final m = snap.data;
        if (m == null) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            appBar: AppBar(title: Text('Store', style: GoogleFonts.cairo())),
            body: Center(
              child: Text(
                'لم يُعثر على هذا المتجر.',
                style: GoogleFonts.cairo(color: AppColors.mediumGray),
              ),
            ),
          );
        }
        final isOwner = uid != null && uid == m.ownerUid;

        return Scaffold(
          backgroundColor: AppColors.deepBlack,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        m.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClubBadge(appSource: m.appSource, size: 16),
                  ],
                ),
                actions: [
                  CustomIconButton(
                    tooltip: 'نسخ معرّف الدعوة',
                    icon: Icons.copy_rounded,
                    semanticsLabel: 'زر نسخ معرّف دعوة المتجر',
                    onPressed: () async {
                      await copyMerchantInviteId(m.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('تم النسخ', style: GoogleFonts.cairo())),
                      );
                    },
                  ),
                  CustomIconButton(
                    tooltip: 'مشاركة للترويج',
                    icon: Icons.share_rounded,
                    semanticsLabel: 'زر مشاركة المتجر للترويج',
                    onPressed: () => shareMerchantForPromotion(
                      merchantName: m.nameAr,
                      merchantId: m.id,
                      slug: m.slug,
                    ),
                  ),
                  if (isOwner)
                    CustomIconButton(
                      tooltip: 'إدارة المتجر',
                      icon: Icons.settings_suggest_rounded,
                      semanticsLabel: 'زر فتح إدارة المتجر',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RepositoryProvider.value(
                            value: repo,
                            child: MerchantStoreAdminPage(merchantId: m.id),
                          ),
                        ),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: m.hasCover
                      ? CachedNetworkImage(
                          imageUrl: m.coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _coverFallback(),
                        )
                      : _coverFallback(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (m.hasLogo)
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  CachedNetworkImageProvider(m.logoUrl),
                            )
                          else
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.mediumBlack,
                              child: Icon(Icons.store,
                                  color: AppColors.luminousGold),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.nameAr,
                                        style: GoogleFonts.cairo(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                    ClubBadge(appSource: m.appSource, size: 16),
                                  ],
                                ),
                                Text(
                                  'شعبية السوق: ${m.audienceScore}',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.luminousGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (m.slug.isNotEmpty)
                                  Text(
                                    'الاسم المختصر: ${m.slug}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppColors.mediumGray,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (m.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          m.bio,
                          style: GoogleFonts.cairo(
                            color: AppColors.lightGray,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => shareMerchantForPromotion(
                          merchantName: m.nameAr,
                          merchantId: m.id,
                          slug: m.slug,
                        ),
                        icon: const Icon(Icons.campaign_outlined,
                            color: AppColors.luminousGold),
                        label: Text(
                          'رابط دعوة للترويج',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'المنتجات',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              StreamBuilder<List<StoreProduct>>(
                stream: repo.watchProductsForMerchant(merchantId),
                builder: (context, pSnap) {
                  final list =
                      (pSnap.data ?? []).where((p) => p.active).toList();
                  if (list.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Text(
                          'لا توجد منتجات معروضة بعد.',
                          style: GoogleFonts.cairo(color: AppColors.mediumGray),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductTile(product: list[i]),
                        childCount: list.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _coverFallback() {
    return Container(
      color: AppColors.mediumBlack,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, size: 64, color: AppColors.royalRed),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.mediumBlack,
        border: Border.all(color: AppColors.royalRed.withValues(alpha: 0.15)),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${product.priceEgp} جنيه',
                  style: GoogleFonts.cairo(
                    color: AppColors.luminousGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ph() {
    return Container(
      color: AppColors.darkBlack,
      alignment: Alignment.center,
      child:
          const Icon(Icons.shopping_bag_outlined, color: AppColors.mediumGray),
    );
  }
}
