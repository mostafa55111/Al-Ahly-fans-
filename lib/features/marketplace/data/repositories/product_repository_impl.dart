import 'package:gomhor_alahly_clean_new/features/marketplace/data/datasources/product_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/data/models/product_model.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductModel>> getProducts() async {
    return await remoteDataSource.getProducts();
  }

  @override
  Future<List<ProductModel>> getVendorProducts(String vendorId) async {
    return await remoteDataSource.getVendorProducts(vendorId);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    await remoteDataSource.addProduct(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await remoteDataSource.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await remoteDataSource.deleteProduct(productId);
  }
}
