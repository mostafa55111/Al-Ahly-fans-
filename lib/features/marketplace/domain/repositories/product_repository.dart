import 'package:gomhor_alahly_clean_new/features/marketplace/data/models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getVendorProducts(String vendorId);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}
