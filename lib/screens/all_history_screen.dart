import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/billing_manager.dart';
import '../widgets/bill_receipt_dialog.dart';

enum HistoryDateFilter { today, yesterday, thisWeek, thisMonth, custom, all }

class AllHistoryScreen extends StatefulWidget {
  const AllHistoryScreen({super.key});

  @override
  State<AllHistoryScreen> createState() => _AllHistoryScreenState();
}

class _AllHistoryScreenState extends State<AllHistoryScreen> {
  final BillingManager _billingManager = BillingManager();
  final TextEditingController _searchController = TextEditingController();

  HistoryDateFilter _selectedFilter = HistoryDateFilter.all;
  DateTimeRange? _customDateRange;
  String _selectedPaymentMethod = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  String _formatDateOnly(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day-$month-$year';
  }

  bool _matchesDateFilter(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case HistoryDateFilter.today:
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;

      case HistoryDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

      case HistoryDateFilter.thisWeek:
        final weekAgo = today.subtract(const Duration(days: 7));
        return dt.isAfter(weekAgo.subtract(const Duration(seconds: 1)));

      case HistoryDateFilter.thisMonth:
        return dt.year == now.year && dt.month == now.month;

      case HistoryDateFilter.custom:
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(end.add(const Duration(seconds: 1)));

      case HistoryDateFilter.all:
        return true;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade800,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = HistoryDateFilter.custom;
      });
    }
  }

  String _getDateFilterLabel() {
    switch (_selectedFilter) {
      case HistoryDateFilter.today:
        return "Today's Bills";
      case HistoryDateFilter.yesterday:
        return "Yesterday's Bills";
      case HistoryDateFilter.thisWeek:
        return "Past 7 Days Bills";
      case HistoryDateFilter.thisMonth:
        return "This Month's Bills";
      case HistoryDateFilter.custom:
        if (_customDateRange != null) {
          return '${_formatDateOnly(_customDateRange!.start)} to ${_formatDateOnly(_customDateRange!.end)}';
        }
        return 'Custom Date Range';
      case HistoryDateFilter.all:
        return 'All Time History';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _billingManager,
      builder: (context, _) {
        final allInvoices = _billingManager.invoices;

        // Filter invoices
        final filteredInvoices = allInvoices.where((inv) {
          // Date Filter
          if (!_matchesDateFilter(inv.dateTime)) return false;

          // Payment Method Filter
          if (_selectedPaymentMethod != 'All' &&
              inv.paymentMethod.toLowerCase() != _selectedPaymentMethod.toLowerCase()) {
            return false;
          }

          // Search Query Filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            final idMatch = inv.id.toLowerCase().contains(query);
            final nameMatch = inv.customerName.toLowerCase().contains(query);
            final phoneMatch = inv.customerPhone.toLowerCase().contains(query);
            final itemMatch = inv.items.any((it) => it.product.name.toLowerCase().contains(query));
            if (!idMatch && !nameMatch && !phoneMatch && !itemMatch) return false;
          }

          return true;
        }).toList();

        // Calculate Totals
        final totalAmount = filteredInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
        final totalBillsCount = filteredInvoices.length;

        final cashSales = filteredInvoices
            .where((it) => it.paymentMethod.toLowerCase() == 'cash')
            .fold(0.0, (sum, inv) => sum + inv.grandTotal);

        final upiSales = filteredInvoices
            .where((it) => it.paymentMethod.toLowerCase() == 'upi')
            .fold(0.0, (sum, inv) => sum + inv.grandTotal);

        final cardSales = filteredInvoices
            .where((it) => it.paymentMethod.toLowerCase() == 'card')
            .fold(0.0, (sum, inv) => sum + inv.grandTotal);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            toolbarHeight: 65,
            elevation: 1,
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Sales History',
                  style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Filter by date & review all past bills',
                  style: TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Pick Custom Date Range',
                icon: const Icon(Icons.date_range_rounded),
                onPressed: _pickCustomDateRange,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // --- 1. Date Filter Chips ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Time', HistoryDateFilter.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Today', HistoryDateFilter.today),
                      const SizedBox(width: 8),
                      _buildFilterChip('Yesterday', HistoryDateFilter.yesterday),
                      const SizedBox(width: 8),
                      _buildFilterChip('This Week', HistoryDateFilter.thisWeek),
                      const SizedBox(width: 8),
                      _buildFilterChip('This Month', HistoryDateFilter.thisMonth),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _pickCustomDateRange,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedFilter == HistoryDateFilter.custom
                                ? Colors.teal.shade800
                                : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedFilter == HistoryDateFilter.custom
                                  ? Colors.teal.shade800
                                  : Colors.teal.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: _selectedFilter == HistoryDateFilter.custom
                                    ? Colors.white
                                    : Colors.teal.shade900,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedFilter == HistoryDateFilter.custom && _customDateRange != null
                                    ? '${_formatDateOnly(_customDateRange!.start)} - ${_formatDateOnly(_customDateRange!.end)}'
                                    : 'Custom Range...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedFilter == HistoryDateFilter.custom
                                      ? Colors.white
                                      : Colors.teal.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. Summary Cards (Total Amount & Total Bills) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade900, Colors.teal.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.event_note, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDateFilterLabel(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalBillsCount Invoices',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Total Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Revenue',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          Container(height: 38, width: 1, color: Colors.white24),
                          // Total Bills
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Bills',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$totalBillsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Payment Mode Breakdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPaymentMiniStat('Cash', cashSales),
                            Container(height: 16, width: 1, color: Colors.white30),
                            _buildPaymentMiniStat('UPI', upiSales),
                            Container(height: 16, width: 1, color: Colors.white30),
                            _buildPaymentMiniStat('Card', cardSales),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. Search & Filter Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search bill #, customer name, phone...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.teal),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          icon: const Icon(Icons.filter_list, size: 18, color: Colors.teal),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Pay')),
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'Card', child: Text('Card')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentMethod = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 4. Invoices List ---
              Expanded(
                child: filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No bills match "$_searchQuery"'
                                  : 'No bills in this date range',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Show All History'),
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = HistoryDateFilter.all;
                                  _selectedPaymentMethod = 'All';
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredInvoices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final inv = filteredInvoices[index];
                          return _buildInvoiceCard(context, inv);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, HistoryDateFilter filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade800 : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal.shade800 : Colors.teal.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? Colors.white : Colors.teal.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMiniStat(String label, double amount) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice inv) {
    Color payColor;
    IconData payIcon;
    switch (inv.paymentMethod.toLowerCase()) {
      case 'upi':
        payColor = Colors.purple.shade700;
        payIcon = Icons.qr_code_2;
        break;
      case 'card':
        payColor = Colors.blue.shade700;
        payIcon = Icons.credit_card;
        break;
      case 'cash':
      default:
        payColor = const Color(0xFF059669);
        payIcon = Icons.payments_outlined;
        break;
    }

    return Card(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => BillReceiptDialog(invoice: inv),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Avatar / Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.teal, size: 22),
              ),
              const SizedBox(width: 12),

              // Center Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inv.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: payColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: payColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(payIcon, size: 12, color: payColor),
                              const SizedBox(width: 3),
                              Text(
                                inv.paymentMethod,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: payColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    if (inv.customerPhone.isNotEmpty) ...[
                      Text(
                        'Ph: ${inv.customerPhone}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          _formatDateTime(inv.dateTime),
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${inv.totalItemCount} items',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Price & Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${inv.grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17.5,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 14, color: Colors.teal),
                      ],
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

