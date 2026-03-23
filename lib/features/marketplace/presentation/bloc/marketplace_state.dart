part of 'marketplace_bloc.dart';

abstract class MarketplaceState {
  const MarketplaceState();
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceLoaded extends MarketplaceState {
  final List<ProductModel> products;

  const MarketplaceLoaded(this.products);
}

class MarketplaceError extends MarketplaceState {
  final String message;

  const MarketplaceError(this.message);
}

class ProductAddedSuccess extends MarketplaceState {
  const ProductAddedSuccess();
}

class ProductUpdatedSuccess extends MarketplaceState {
  const ProductUpdatedSuccess();
}

class ProductDeletedSuccess extends MarketplaceState {
  const ProductDeletedSuccess();
}
