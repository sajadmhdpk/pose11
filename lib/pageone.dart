import 'package:flutter/material.dart';
import 'screens/billing_screen.dart';
import 'screens/draft_screen.dart';
import 'screens/products_screen.dart';
import 'screens/invoices_screen.dart';
import 'services/billing_manager.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  int _currentIndex = 0;
  final BillingManager _billingManager = BillingManager();

  late final List<Widget> _screens = [
    const BillingScreen(),
    DraftScreen(onOpenBilling: () => setState(() => _currentIndex = 0)),
    const ProductsScreen(),
    const InvoicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade900,
                Colors.teal.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/platano_splash.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.teal.shade700,
                    child: const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PLATANO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Avil Milk',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: Colors.tealAccent.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'BILLING & POS SYSTEM',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _billingManager,
        builder: (context, _) {
          final draftCount = _billingManager.drafts.length;
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            indicatorColor: Colors.teal.shade100,
            backgroundColor: Colors.white,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale, color: Colors.teal),
                label: 'Billing',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: draftCount > 0,
                  label: Text('$draftCount'),
                  backgroundColor: Colors.teal.shade800,
                  child: const Icon(Icons.drafts_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: draftCount > 0,
                  label: Text('$draftCount'),
                  backgroundColor: Colors.teal.shade800,
                  child: const Icon(Icons.drafts, color: Colors.teal),
                ),
                label: 'Draft',
              ),
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2, color: Colors.teal),
                label: 'Products',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: Colors.teal),
                label: 'History',
              ),
            ],
          );
        },
      ),
    );
  }
}
