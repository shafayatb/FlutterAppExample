import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_flutter_app/bloc/auth/auth_bloc.dart';
import 'package:new_flutter_app/bloc/product/product_bloc.dart';
import 'package:new_flutter_app/list_item.dart';
import 'package:new_flutter_app/login_page.dart';
import 'package:new_flutter_app/profile_page.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => ProductBloc(),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'My Custom List'),
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
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start fetching products when the page loads
    context.read<ProductBloc>().add(ProductStarted());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductBloc>().add(ProductNextPageRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    // Avoid crash during AnimatedSwitcher transition when multiple scroll views are attached
    if (_scrollController.positions.length > 1) return false;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildProductList(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1) {
                if (state is! AuthAuthenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ).then((_) {
                    if (!context.mounted) return;
                    if (context.read<AuthBloc>().state is AuthAuthenticated) {
                       setState(() {
                         _currentIndex = 1;
                       });
                    }
                  });
                  return;
                }
              }
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: state is AuthAuthenticated 
                    ? CircleAvatar(
                        radius: 12, // Standard icon size is 24, so radius 12
                        backgroundImage: NetworkImage(state.user.image),
                      )
                    : const Icon(Icons.person),
                label: state is AuthAuthenticated ? state.user.firstName : 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              snap: true,
              actions: [
                IconButton(
                  icon: Icon(
                    state.isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    context.read<ProductBloc>().add(ProductViewToggled());
                  },
                ),
              ],
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
                transitionBuilder: (Widget child, Animation<double> animation) {
                   return FadeTransition(
                     opacity: animation,
                     child: SlideTransition(
                       position: Tween<Offset>(
                         begin: const Offset(0.0, 0.5),
                         end: Offset.zero,
                       ).animate(animation),
                       child: child,
                     ),
                   );
                },
                child: Text(
                  state.selectedCategory?.name ?? 'All Products',
                  key: ValueKey<String>(state.selectedCategory?.name ?? 'All Products'),
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
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: state.categories.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = state.selectedCategory == null;
                        return ChoiceChip(
                          label: const Text('All'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              context.read<ProductBloc>().add(const ProductCategorySelected(null));
                            }
                          },
                        );
                      }
                      final category = state.categories[index - 1];
                      final isSelected = state.selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                              context.read<ProductBloc>().add(ProductCategorySelected(category));
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          body: Builder(
            builder: (context) {
              if (state.status == ProductStatus.initial) {
                 return const Center(child: CircularProgressIndicator());
              }
              if (state.status == ProductStatus.failure && state.products.isEmpty) {
                 return Center(child: Text('Error: ${state.errorMessage}'));
              }
              if (state.products.isEmpty) {
                return const Center(child: Text('No products found'));
              }
              
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.isGridView
                    ? GridView.builder(
                        key: const ValueKey('GridView'),
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                        ),
                        itemCount: state.hasReachedMax
                            ? state.products.length
                            : state.products.length + 1,
                        itemBuilder: (context, index) {
                           if (index >= state.products.length) {
                             return const Center(child: CircularProgressIndicator());
                           }
                           final product = state.products[index];
                           return Card(
                             elevation: 4.0,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                 Expanded(
                                   child: ClipRRect(
                                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                     child: Image.network(
                                       product.thumbnail,
                                       fit: BoxFit.cover,
                                       errorBuilder: (ctx, error, stack) => const Center(child: Icon(Icons.error)),
                                     ),
                                   ),
                                 ),
                                 Padding(
                                   padding: const EdgeInsets.all(8.0),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         product.title,
                                         maxLines: 2,
                                         overflow: TextOverflow.ellipsis,
                                         style: const TextStyle(fontWeight: FontWeight.bold),
                                       ),
                                       const SizedBox(height: 4),
                                       Text(
                                         '\$${product.price}',
                                         style: TextStyle(
                                           color: Theme.of(context).primaryColor,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           );
                        },
                      )
                    : ListView.builder(
                        key: const ValueKey('ListView'),
                        controller: _scrollController,
                        itemCount: state.hasReachedMax
                            ? state.products.length
                            : state.products.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= state.products.length) {
                             return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final product = state.products[index];
                          return ListItemWidget(
                            item: ListItem(
                              title: product.title,
                              subtitle: product.description,
                              author: product.brand,
                              date: '\$${product.price}',
                              imageUrl: product.thumbnail,
                            ),
                          );
                        },
                      ),
              );
            }
          ),
        );
      },
    );
  }
}
