import 'package:flutter/material.dart';
import '../models/draft_bill.dart';
import '../services/billing_manager.dart';

class DraftScreen extends StatefulWidget {
  final VoidCallback? onOpenBilling;

  const DraftScreen({super.key, this.onOpenBilling});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final BillingManager _billingManager = BillingManager();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resumeDraft(DraftBill draft) {
    if (_billingManager.cart.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 8),
              Text('Current Bill Has Items'),
            ],
          ),
          content: const Text(
            'Your current billing cart already contains items. Resuming this draft will replace the current bill.\n\nDo you want to continue?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(ctx);
                _billingManager.resumeDraft(draft);
                widget.onOpenBilling?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded ${draft.id} into Current Bill!'),
                    backgroundColor: Colors.teal.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Resume Draft'),
            ),
          ],
        ),
      );
    } else {
      _billingManager.resumeDraft(draft);
      widget.onOpenBilling?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded ${draft.id} into Current Bill!'),
          backgroundColor: Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteDraft(DraftBill draft) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Draft?'),
        content: Text('Are you sure you want to delete ${draft.id}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _billingManager.deleteDraft(draft.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draft deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _billingManager,
      builder: (context, _) {
        final allDrafts = _billingManager.drafts;
        final filteredDrafts = allDrafts.where((d) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final matchesId = d.id.toLowerCase().contains(q);
          final matchesName = d.customerName.toLowerCase().contains(q);
          final matchesPhone = d.customerPhone.toLowerCase().contains(q);
          final matchesItems = d.items.any((it) => it.product.name.toLowerCase().contains(q));
          return matchesId || matchesName || matchesPhone || matchesItems;
        }).toList();

        final totalHeldAmount = allDrafts.fold(0.0, (sum, d) => sum + d.grandTotal);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              // --- Header Summary Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.shade900,
                      Colors.teal.shade800,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.drafts_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Draft & Held Bills',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${allDrafts.length} Held',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pending Bills Value',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${totalHeldAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Container(height: 32, width: 1, color: Colors.white24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Items Held',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${allDrafts.fold(0, (sum, d) => sum + d.totalItemCount)} Items',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Search Bar ---
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: Colors.white,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search draft by ID, customer, or item...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.teal),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.teal),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.teal.shade50.withValues(alpha: 0.35),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: Colors.teal, width: 1.8),
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // --- Drafts List or Empty State ---
              Expanded(
                child: filteredDrafts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.drafts_outlined,
                                  size: 56,
                                  color: Colors.teal.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No Draft Bills'
                                    : 'No Drafts Matching "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'When you hold a bill in the Billing Screen, it will appear here so you can resume it anytime.'
                                    : 'Try searching with a different keyword or customer name.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.teal.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.point_of_sale, size: 18),
                                  label: const Text('Go to Billing'),
                                  onPressed: () => widget.onOpenBilling?.call(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: filteredDrafts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final draft = filteredDrafts[index];
                          return _buildDraftCard(draft);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraftCard(DraftBill draft) {
    final timeStr =
        '${draft.dateTime.hour.toString().padLeft(2, '0')}:${draft.dateTime.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${draft.dateTime.day.toString().padLeft(2, '0')}/${draft.dateTime.month.toString().padLeft(2, '0')}/${draft.dateTime.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        draft.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$dateStr • $timeStr',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Delete Draft',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteDraft(draft),
                ),
              ],
            ),
          ),

          // Card Middle Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Name & Phone
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        draft.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (draft.customerPhone.isNotEmpty) ...[
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        draft.customerPhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Items list summary
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: draft.items.map((it) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${it.product.name} × ${it.quantity.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Amount & Resume Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total (${draft.totalItemCount} items)',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                        Text(
                          '₹${draft.grandTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text(
                        'Open Bill',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () => _resumeDraft(draft),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
