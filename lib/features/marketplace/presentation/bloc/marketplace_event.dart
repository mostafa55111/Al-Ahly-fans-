part of 'marketplace_bloc.dart';

abstract class MarketplaceEvent {
  const MarketplaceEvent();
}

class GetProductsEvent extends MarketplaceEvent {
  const GetProductsEvent();
}

class GetVendorProductsEvent extends MarketplaceEvent {
  final String vendorId;

  const GetVendorProductsEvent({required this.vendorId});
}

class AddProductEvent extends MarketplaceEvent {
  final ProductModel product;

  const AddProductEvent({required this.product});
}

class UpdateProductEvent extends MarketplaceEvent {
  final ProductModel product;

  const UpdateProductEvent({required this.product});
}

class DeleteProductEvent extends MarketplaceEvent {
  final String productId;

  const DeleteProductEvent({required this.productId});
}
