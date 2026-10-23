import 'cart_item.dart';

class Invoice {
  final String id;
  final DateTime dateTime;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String paymentMethod; // Cash, UPI, Card

  Invoice({
    required this.id,
    required this.dateTime,
    this.customerName = 'Cash Customer',
    this.customerPhone = '',
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.grandTotal,
    this.paymentMethod = 'Cash',
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity.toInt());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((it) => it.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    return Invoice(
      id: map['id']?.toString() ?? '',
      dateTime: DateTime.tryParse(map['dateTime']?.toString() ?? '') ?? DateTime.now(),
      customerName: map['customerName']?.toString() ?? 'Cash Customer',
      customerPhone: map['customerPhone']?.toString() ?? '',
      items: rawItems.map((it) => CartItem.fromMap(Map<String, dynamic>.from(it as Map))).toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
    );
  }
}
