import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getVendorProducts(String vendorId);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseDatabase _database;

  ProductRemoteDataSourceImpl(this._database);

  @override
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _database.ref().child('products').get();
    if (snapshot.exists) {
      final List<ProductModel> products = [];
      (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
        products.add(ProductModel.fromSnapshot(DataSnapshot(key, value, snapshot.ref)));
      });
      return products;
    } else {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getVendorProducts(String vendorId) async {
    final snapshot = await _database.ref().child('products').orderByChild('vendorId').equalTo(vendorId).get();
    if (snapshot.exists) {
      final List<ProductModel> products = [];
      (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
        products.add(ProductModel.fromSnapshot(DataSnapshot(key, value, snapshot.ref)));
      });
      return products;
    } else {
      return [];
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final newProductRef = _database.ref().child('products').push();
    await newProductRef.set(product.toJson());
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await _database.ref().child('products/${product.id}').update(product.toJson());
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _database.ref().child('products/$productId').remove();
  }
}
