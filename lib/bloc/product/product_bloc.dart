import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:new_flutter_app/category.dart';
import 'package:new_flutter_app/product.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

part 'product_event.dart';
part 'product_state.dart';

const _limit = 10;
const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(const ProductState()) {
    on<ProductStarted>(_onStarted);
    on<ProductCategorySelected>(_onCategorySelected);
    on<ProductViewToggled>((event, emit) {
      emit(state.copyWithResult(isGridView: !state.isGridView));
    });
    on<ProductNextPageRequested>(
      _onNextPageRequested,
      transformer: throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _onStarted(
      ProductStarted event, Emitter<ProductState> emit) async {
    emit(state.copyWithResult(status: ProductStatus.initial));
    try {
      // Fetch Categories and First Page of Products
      final categoriesHelper = _fetchCategories();
      final productsHelper = _fetchProducts(0, null);

      final results = await Future.wait([categoriesHelper, productsHelper]);
      
      final categories = results[0] as List<Category>;
      final productData = results[1] as Map<String, dynamic>;
      final products = productData['products'] as List<Product>;
      final total = productData['total'] as int;

      emit(state.copyWithResult(
        status: ProductStatus.success,
        categories: categories,
        products: products,
        hasReachedMax: products.length >= total,
      ));
    } catch (e) {
      emit(state.copyWithResult(status: ProductStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onCategorySelected(
      ProductCategorySelected event, Emitter<ProductState> emit) async {
    emit(state.copyWithResult(
      selectedCategory: event.category,
      setCategoryToNull: event.category == null,
      products: [],
      hasReachedMax: false,
      status: ProductStatus.initial // Show loading again strictly speaking or just use isLoadingMore? 
      // We want to clear the list.
    ));

    try {
      final productData = await _fetchProducts(0, event.category);
      final products = productData['products'] as List<Product>;
      final total = productData['total'] as int;

      emit(state.copyWithResult(
        status: ProductStatus.success,
        products: products,
        hasReachedMax: products.length >= total,
      ));
    } catch (e) {
      emit(state.copyWithResult(status: ProductStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onNextPageRequested(
      ProductNextPageRequested event, Emitter<ProductState> emit) async {
    if (state.hasReachedMax) return;
    
    // We can add an isLoadingMore field if we want to show a loader at bottom without clearing list
    emit(state.copyWithResult(isLoadingMore: true));

    try {
      final productData = await _fetchProducts(state.products.length, state.selectedCategory);
      final newProducts = productData['products'] as List<Product>;
      final total = productData['total'] as int;

      if (newProducts.isEmpty) {
        emit(state.copyWithResult(hasReachedMax: true, isLoadingMore: false));
      } else {
        emit(state.copyWithResult(
          status: ProductStatus.success,
          products: List.of(state.products)..addAll(newProducts),
          hasReachedMax: (state.products.length + newProducts.length) >= total,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
       emit(state.copyWithResult(status: ProductStatus.failure, errorMessage: e.toString(), isLoadingMore: false));
    }
  }

  Future<List<Category>> _fetchCategories() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/products/categories'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  Future<Map<String, dynamic>> _fetchProducts(int skip, Category? category) async {
    final String baseUrl = category != null 
          ? category.url 
          : 'https://dummyjson.com/products';
      
    final String connector = baseUrl.contains('?') ? '&' : '?';
    final String url = '$baseUrl${connector}limit=$_limit&skip=$skip';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final products = (data['products'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
      final total = data['total'] as int;
      return {'products': products, 'total': total};
    } else {
      throw Exception('Failed to fetch products');
    }
  }
}
