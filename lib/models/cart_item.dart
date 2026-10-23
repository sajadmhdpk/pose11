import 'product.dart';

class CartItem {
  final Product product;
  double quantity;
  double customPrice;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    double? customPrice,
  }) : customPrice = customPrice ?? product.price;

  double get totalPrice => quantity * customPrice;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? customPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      customPrice: customPrice ?? this.customPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'customPrice': customPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(Map<String, dynamic>.from(map['product'] ?? {})),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      customPrice: (map['customPrice'] as num?)?.toDouble(),
    );
  }
}
