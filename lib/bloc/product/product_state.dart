part of 'product_bloc.dart';

enum ProductStatus { initial, success, failure }

final class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;
  final List<Category> categories;
  final Category? selectedCategory;
  final bool hasReachedMax;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool isGridView;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const <Product>[],
    this.categories = const <Category>[],
    this.selectedCategory,
    this.hasReachedMax = false,
    this.errorMessage,
    this.isLoadingMore = false,
    this.isGridView = false,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    List<Category>? categories,
    Category? selectedCategory,
    bool? hasReachedMax,
    String? errorMessage,
    bool? isLoadingMore,
    bool? isGridView,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isGridView: isGridView ?? this.isGridView,
    );
  }
  
  // Better copyWith for nullable field
  ProductState copyWithResult({
    ProductStatus? status,
    List<Product>? products,
    List<Category>? categories,
    Category? selectedCategory,
    bool setCategoryToNull = false,
    bool? hasReachedMax,
    String? errorMessage,
    bool? isLoadingMore,
    bool? isGridView,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: setCategoryToNull ? null : (selectedCategory ?? this.selectedCategory),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        categories,
        selectedCategory,
        hasReachedMax,
        errorMessage,
        isLoadingMore,
        isGridView,
      ];
}
