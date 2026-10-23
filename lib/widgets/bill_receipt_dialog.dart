import 'package:flutter/material.dart';
import '../models/invoice.dart';

class BillReceiptDialog extends StatelessWidget {
  final Invoice invoice;

  const BillReceiptDialog({super.key, required this.invoice});

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Store Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/platano_splash.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.teal.shade50,
                      child: const Icon(
                        Icons.local_drink_rounded,
                        color: Colors.teal,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PLATANO AVIL MILK',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              const Text(
                'Kollanpadi, Ponnani\nMob: +91 9605067612',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(thickness: 1, height: 24),

              // Invoice Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill No: ${invoice.id}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                  ),
                  Text(
                    _formatDateTime(invoice.dateTime),
                    style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer: ${invoice.customerName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Mode: ${invoice.paymentMethod}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              if (invoice.customerPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Phone: ${invoice.customerPhone}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
              const Divider(thickness: 1, height: 24),

              // Table Headers
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Item rows
              ...invoice.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}${item.product.unit.isNotEmpty ? ' ${item.product.unit}' : ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${item.customPrice.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${item.totalPrice.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(thickness: 1, height: 24),

              // Subtotal & Discount
              if (invoice.discount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    Text('₹${invoice.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Text('-₹${invoice.discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Grand Total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: Colors.black),
                    ),
                    Text(
                      '₹${invoice.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                '--- Thank You! Visit Again ---',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade800,
                        side: BorderSide(color: Colors.teal.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bill sent to printer 🖨️'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
