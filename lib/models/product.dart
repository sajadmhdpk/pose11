class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  final String category;
  final String code;
  final int stock;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit = '',
    this.category = 'General',
    this.code = '',
    this.stock = 0,
    this.imagePath,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? unit,
    String? category,
    String? code,
    int? stock,
    String? imagePath,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      code: code ?? this.code,
      stock: stock ?? this.stock,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'category': category,
      'code': code,
      'stock': stock,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      code: map['code']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      imagePath: map['imagePath']?.toString(),
    );
  }
}
