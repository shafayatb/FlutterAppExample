import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:new_flutter_app/category.dart';
import 'package:new_flutter_app/list_item.dart';
import 'package:new_flutter_app/login_page.dart';
import 'package:new_flutter_app/product.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('accessToken');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _checkToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return const MyHomePage(title: 'My Custom List');
          }
          return const LoginPage();
        },
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<ListItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  static const int _limit = 10;
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products/categories'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _categories = data.map((e) => Category.fromJson(e)).toList();
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      // Handle category error silently or with a snackbar? For now just stop loading.
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skip = _items.length;
      final String baseUrl = _selectedCategory != null 
          ? _selectedCategory!.url 
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

        if (mounted) {
          setState(() {
            _items.addAll(products.map((p) => ListItem(
                  title: p.title,
                  subtitle: p.description,
                  author: p.brand,
                  date: '\$${p.price}',
                  imageUrl: p.thumbnail,
                )));
            _isLoading = false;
            _hasMore = _items.length < total;
          });
        }
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(Category? category) {
    if (_selectedCategory == category) return;
    
    setState(() {
      _selectedCategory = category;
      _items.clear();
      _hasMore = true;
      _errorMessage = null;
    });
    _fetchProducts(); // Fetch first page of new category
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            snap: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.linear,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: Text(
                _selectedCategory?.name ?? 'All Products',
                key: ValueKey<String>(_selectedCategory?.name ?? 'All Products'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _categories.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedCategory == null;
                          return ChoiceChip(
                            label: const Text('All'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) _onCategorySelected(null);
                            },
                          );
                        }
                        final category = _categories[index - 1];
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _onCategorySelected(category);
                          },
                        );
                      },
                    ),
              ),
            ),
          ),
        ],
        body: _items.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty && _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage'),
                        ElevatedButton(
                          onPressed: _fetchProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                              child: _errorMessage != null
                                  ? ElevatedButton(
                                      onPressed: _fetchProducts, child: const Text('Retry Load More'))
                                  : const CircularProgressIndicator()),
                        );
                      }
                      return ListItemWidget(item: _items[index]);
                    },
                  ),
      ),
    );
  }
}
