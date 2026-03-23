import 'package:firebase_database/firebase_database.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String vendorId;
  final int stock;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.vendorId,
    this.stock = 0,
    required this.createdAt,
  });

  factory ProductModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return ProductModel(
      id: snapshot.key!,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String,
      vendorId: data['vendorId'] as String,
      stock: data['stock'] as int? ?? 0,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'vendorId': vendorId,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
