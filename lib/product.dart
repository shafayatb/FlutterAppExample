class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String brand;
  final String thumbnail;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.brand,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      brand: json['brand'] as String? ?? 'Unknown Brand',
      thumbnail: json['thumbnail'] as String,
    );
  }
}
