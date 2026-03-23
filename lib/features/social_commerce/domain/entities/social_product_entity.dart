import 'package:equatable/equatable.dart';

/// كيان المنتج الاجتماعي (Social Product Entity)
/// منتجات يمكن شراؤها مباشرة من المنشورات والفيديوهات
class SocialProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // 'jersey', 'merchandise', 'tickets', 'experiences'
  final int stock;
  final double rating;
  final int reviewsCount;
  final String sellerId;
  final String sellerName;
  final bool isVerified;
  final List<String> tags;
  final DateTime createdAt;
  final bool isAvailable;
  final String? linkedPostId; // معرف المنشور المرتبط
  final String? linkedReelId; // معرف الفيديو المرتبط
  final int purchasesCount;
  final List<String> colors; // الألوان المتاحة
  final List<String> sizes; // المقاسات المتاحة

  const SocialProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.rating,
    required this.reviewsCount,
    required this.sellerId,
    required this.sellerName,
    required this.isVerified,
    required this.tags,
    required this.createdAt,
    required this.isAvailable,
    this.linkedPostId,
    this.linkedReelId,
    required this.purchasesCount,
    required this.colors,
    required this.sizes,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageUrl,
    category,
    stock,
    rating,
    reviewsCount,
    sellerId,
    sellerName,
    isVerified,
    tags,
    createdAt,
    isAvailable,
    linkedPostId,
    linkedReelId,
    purchasesCount,
    colors,
    sizes,
  ];
}

/// فئة فئات المنتجات
class ProductCategories {
  static const String jersey = 'jersey'; // القمصان
  static const String merchandise = 'merchandise'; // السلع
  static const String tickets = 'tickets'; // التذاكر
  static const String experiences = 'experiences'; // التجارب (حضور مباريات، لقاء لاعبين)
  static const String digital = 'digital'; // المحتوى الرقمي

  static List<String> getAllCategories() => [
    jersey,
    merchandise,
    tickets,
    experiences,
    digital,
  ];
}
