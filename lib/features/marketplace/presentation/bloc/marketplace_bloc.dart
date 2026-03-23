import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/data/models/product_model.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/domain/repositories/product_repository.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final ProductRepository productRepository;

  MarketplaceBloc({required this.productRepository}) : super(const MarketplaceInitial()) {
    on<GetProductsEvent>(_onGetProducts);
    on<GetVendorProductsEvent>(_onGetVendorProducts);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  Future<void> _onGetProducts(GetProductsEvent event, Emitter<MarketplaceState> emit) async {
    emit(const MarketplaceLoading());
    try {
      final products = await productRepository.getProducts();
      emit(MarketplaceLoaded(products));
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> _onGetVendorProducts(GetVendorProductsEvent event, Emitter<MarketplaceState> emit) async {
    emit(const MarketplaceLoading());
    try {
      final products = await productRepository.getVendorProducts(event.vendorId);
      emit(MarketplaceLoaded(products));
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> _onAddProduct(AddProductEvent event, Emitter<MarketplaceState> emit) async {
    try {
      await productRepository.addProduct(event.product);
      emit(const ProductAddedSuccess());
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(UpdateProductEvent event, Emitter<MarketplaceState> emit) async {
    try {
      await productRepository.updateProduct(event.product);
      emit(const ProductUpdatedSuccess());
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(DeleteProductEvent event, Emitter<MarketplaceState> emit) async {
    try {
      await productRepository.deleteProduct(event.productId);
      emit(const ProductDeletedSuccess());
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }
}
