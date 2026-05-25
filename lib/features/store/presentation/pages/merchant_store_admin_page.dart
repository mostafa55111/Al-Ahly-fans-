import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_merchant.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/store_product.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';
/// لوحة التاجر — تعديل بيانات المتجر وإدارة المنتجات (لمالك المتجر فقط).
class MerchantStoreAdminPage extends StatefulWidget {
  const MerchantStoreAdminPage({super.key, required this.merchantId});

  final String merchantId;

  @override
  State<MerchantStoreAdminPage> createState() => _MerchantStoreAdminPageState();
}

class _MerchantStoreAdminPageState extends State<MerchantStoreAdminPage> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  MarketplaceMerchant? _loaded;
  bool _savingShop = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _bioCtrl.dispose();
    _coverCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  void _maybeSyncCtrls(MarketplaceMerchant m) {
    if (_loaded?.id == m.id) return;
    _loaded = m;
    _nameCtrl.text = m.nameAr;
    _slugCtrl.text = m.slug;
    _bioCtrl.text = m.bio;
    _coverCtrl.text = m.coverUrl;
    _logoCtrl.text = m.logoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MarketplaceRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<MarketplaceMerchant?>(
      stream: repo.watchMerchant(widget.merchantId),
      builder: (context, snap) {
        final m = snap.data;
        if (snap.connectionState == ConnectionState.waiting && m == null) {
          return const Scaffold(
            backgroundColor: AppColors.deepBlack,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.royalRed)),
          );
        }
        if (m == null) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            appBar:
                AppBar(title: Text('إدارة المتجر', style: GoogleFonts.cairo())),
            body: Center(
              child: Text(
                'المتجر غير موجود.',
                style: GoogleFonts.cairo(color: AppColors.mediumGray),
              ),
            ),
          );
        }
        if (uid == null || uid != m.ownerUid) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            appBar:
                AppBar(title: Text('إدارة المتجر', style: GoogleFonts.cairo())),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'هذه اللوحة مخصّصة لمالك المتجر فقط.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      color: AppColors.mediumGray, height: 1.5),
                ),
              ),
            ),
          );
        }

        _maybeSyncCtrls(m);

        return Scaffold(
          backgroundColor: AppColors.deepBlack,
          appBar: AppBar(
            title: Text('إدارة: ${m.nameAr}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
          floatingActionButton: CustomFAB(
            isExtended: true,
            icon: Icons.add_rounded,
            label: 'منتج جديد',
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            semanticsLabel: 'زر إضافة منتج جديد للمتجر',
            backgroundColor: AppColors.luminousGold,
            foregroundColor: AppColors.deepBlack,
            onPressed: () => _openProductEditor(context, repo, uid, m.id, null),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'بيانات المتجر',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              _field(_nameCtrl, 'اسم المتجر'),
              _field(_slugCtrl, 'اسم مختصر للبحث'),
              _field(_bioCtrl, 'نبذة', maxLines: 3),
              _field(_coverCtrl, 'رابط صورة الغلاف'),
              _field(_logoCtrl, 'رابط الشعار'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _savingShop
                    ? null
                    : () async {
                        setState(() => _savingShop = true);
                        try {
                          await repo.updateMerchant(
                            merchantId: m.id,
                            ownerUid: uid,
                            nameAr: _nameCtrl.text,
                            slug: _slugCtrl.text,
                            bio: _bioCtrl.text,
                            coverUrl: _coverCtrl.text,
                            logoUrl: _logoCtrl.text,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('تم حفظ بيانات المتجر',
                                    style: GoogleFonts.cairo())),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('$e', style: GoogleFonts.cairo())),
                          );
                        } finally {
                          if (mounted) setState(() => _savingShop = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _savingShop
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('حفظ بيانات المتجر',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 28),
              Text(
                'المنتجات',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<StoreProduct>>(
                stream: repo.watchProductsForMerchant(widget.merchantId),
                builder: (context, ps) {
                  final list = ps.data ?? [];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'لا توجد منتجات. اضغط «منتج جديد».',
                        style: GoogleFonts.cairo(color: AppColors.mediumGray),
                      ),
                    );
                  }
                  return Column(
                    children: list.map((p) {
                      return Card(
                        color: AppColors.mediumBlack,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            p.titleAr,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${p.priceEgp} ج — ${p.active ? "معروض" : "مخفي"}',
                            style: GoogleFonts.cairo(
                                color: AppColors.mediumGray, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconButton(
                                icon: Icons.edit,
                                semanticsLabel: 'زر تعديل المنتج ${p.titleAr}',
                                color: AppColors.luminousGold,
                                onPressed: () => _openProductEditor(
                                    context, repo, uid, m.id, p),
                              ),
                              CustomIconButton(
                                icon: Icons.delete_outline,
                                semanticsLabel: 'زر حذف المنتج ${p.titleAr}',
                                color: AppColors.error,
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('حذف؟',
                                          style: GoogleFonts.cairo()),
                                      content: Text(
                                        'حذف المنتج نهائياً.',
                                        style: GoogleFonts.cairo(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text('إلغاء',
                                              style: GoogleFonts.cairo()),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text('حذف',
                                              style: GoogleFonts.cairo()),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) return;
                                  try {
                                    await repo.deleteProduct(
                                        productId: p.id, ownerUid: uid);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('$e',
                                              style: GoogleFonts.cairo())),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: GoogleFonts.cairo(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: AppColors.mediumGray),
          filled: true,
          fillColor: AppColors.darkBlack,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _openProductEditor(
    BuildContext context,
    MarketplaceRepository repo,
    String ownerUid,
    String merchantId,
    StoreProduct? existing,
  ) async {
    final titleCtrl = TextEditingController(text: existing?.titleAr ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? '${existing.priceEgp}' : '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    var active = existing?.active ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
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
                      existing == null ? 'منتج جديد' : 'تعديل منتج',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      decoration: _dec('اسم المنتج *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      decoration: _dec('وصف'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      decoration: _dec('السعر بالجنيه *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imgCtrl,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      decoration: _dec('رابط صورة'),
                    ),
                    SwitchListTile(
                      value: active,
                      onChanged: (v) => setS(() => active = v),
                      title: Text('معروض في المتجر',
                          style: GoogleFonts.cairo(color: AppColors.white)),
                      activeThumbColor: AppColors.luminousGold,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                        if (titleCtrl.text.trim().isEmpty || price <= 0) return;
                        try {
                          if (existing == null) {
                            await repo.createProduct(
                              merchantId: merchantId,
                              ownerUid: ownerUid,
                              titleAr: titleCtrl.text,
                              description: descCtrl.text,
                              priceEgp: price,
                              imageUrl: imgCtrl.text,
                              active: active,
                            );
                          } else {
                            await repo.updateProduct(
                              productId: existing.id,
                              ownerUid: ownerUid,
                              titleAr: titleCtrl.text,
                              description: descCtrl.text,
                              priceEgp: price,
                              imageUrl: imgCtrl.text,
                              active: active,
                            );
                          }
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('تم الحفظ',
                                    style: GoogleFonts.cairo())),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('$e', style: GoogleFonts.cairo())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('حفظ',
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    imgCtrl.dispose();
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: AppColors.mediumGray),
      filled: true,
      fillColor: AppColors.mediumBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
