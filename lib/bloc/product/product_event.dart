part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

final class ProductStarted extends ProductEvent {}

final class ProductCategorySelected extends ProductEvent {
  final Category? category;

  const ProductCategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

final class ProductNextPageRequested extends ProductEvent {}

final class ProductViewToggled extends ProductEvent {}
