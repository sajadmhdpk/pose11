import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/invoice.dart';
import '../models/draft_bill.dart';
import 'backup_service.dart';

class BillingManager extends ChangeNotifier {
  static final BillingManager _instance = BillingManager._internal();
  factory BillingManager() => _instance;

  static const String _productsKey = 'pos_products_v1';
  static const String _invoicesKey = 'pos_invoices_v1';
  static const String _invoiceCounterKey = 'pos_invoice_counter_v1';
  static const String _draftsKey = 'pos_drafts_v1';
  static const String _cartKey = 'pos_cart_v1';
  static const String _cartDiscountKey = 'pos_cart_discount_v1';

  BillingManager._internal() {
    init();
  }

  final List<Product> _products = [];
  final List<CartItem> _cart = [];
  final List<Invoice> _invoices = [];
  final List<DraftBill> _drafts = [];
  double _discount = 0.0;
  int _invoiceCounter = 1001;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Product> get products => List.unmodifiable(_products);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<Invoice> get invoices => List.unmodifiable(_invoices.reversed.toList());
  List<DraftBill> get drafts => List.unmodifiable(_drafts);
  double get discount => _discount;

  Future<void>? _initFuture;

  /// Load all stored products, invoices, and drafts from phone storage
  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load products: check SharedPreferences first, fallback to internal disk file
      String? productsJson = prefs.getString(_productsKey);
      if (productsJson == null || productsJson.isEmpty) {
        productsJson = await _readInternalFile('pos_products.json');
      }

      if (productsJson != null && productsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(productsJson);
        _products.clear();
        bool anyImageHealed = false;
        for (final m in decoded) {
          final pMap = Map<String, dynamic>.from(m as Map);
          final productId = pMap['id']?.toString() ?? '';
          final currentPath = pMap['imagePath']?.toString();

          // Auto-heal broken image paths if cache was cleared
          if (currentPath != null && !File(currentPath).existsSync()) {
            final healedPath = await BackupService.resolveOrRestoreImage(
              productId: productId,
              originalPath: currentPath,
            );
            if (healedPath != null) {
              pMap['imagePath'] = healedPath;
              anyImageHealed = true;
            }
          }
          _products.add(Product.fromMap(pMap));
        }
        if (anyImageHealed) {
          final finalProdJson = jsonEncode(_products.map((p) => p.toMap()).toList());
          await prefs.setString(_productsKey, finalProdJson);
          await _writeInternalFile('pos_products.json', finalProdJson);
        }
      }

      // Load invoices: check SharedPreferences first, fallback to internal disk file
      String? invoicesJson = prefs.getString(_invoicesKey);
      if (invoicesJson == null || invoicesJson.isEmpty) {
        invoicesJson = await _readInternalFile('pos_invoices.json');
      }
      if (invoicesJson != null && invoicesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(invoicesJson);
        _invoices.clear();
        _invoices.addAll(
          decoded.map((m) => Invoice.fromMap(Map<String, dynamic>.from(m as Map))),
        );
        final finalInvJson = jsonEncode(_invoices.map((inv) => inv.toMap()).toList());
        await prefs.setString(_invoicesKey, finalInvJson);
        await _writeInternalFile('pos_invoices.json', finalInvJson);
      }

      // Load drafts: check SharedPreferences first, fallback to internal disk file
      String? draftsJson = prefs.getString(_draftsKey);
      if (draftsJson == null || draftsJson.isEmpty) {
        draftsJson = await _readInternalFile('pos_drafts.json');
      }
      if (draftsJson != null && draftsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(draftsJson);
        _drafts.clear();
        _drafts.addAll(
          decoded.map((m) => DraftBill.fromMap(Map<String, dynamic>.from(m as Map))),
        );
        final finalDraftJson = jsonEncode(_drafts.map((d) => d.toMap()).toList());
        await prefs.setString(_draftsKey, finalDraftJson);
        await _writeInternalFile('pos_drafts.json', finalDraftJson);
      }

      // Load cart: check SharedPreferences first, fallback to internal disk file
      String? cartJson = prefs.getString(_cartKey);
      if (cartJson == null || cartJson.isEmpty) {
        cartJson = await _readInternalFile('pos_cart.json');
      }
      if (cartJson != null && cartJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cartJson);
          _cart.clear();
          for (final m in decoded) {
            _cart.add(CartItem.fromMap(Map<String, dynamic>.from(m as Map)));
          }
          _discount = prefs.getDouble(_cartDiscountKey) ?? 0.0;
          if (_discount == 0.0) {
            final discStr = await _readInternalFile('pos_cart_discount.json');
            if (discStr != null) {
              _discount = double.tryParse(discStr) ?? 0.0;
            }
          }
        } catch (e) {
          debugPrint('Error loading saved cart from phone storage: $e');
        }
      }

      // Sync cart item product data with current loaded products
      if (_cart.isNotEmpty && _products.isNotEmpty) {
        for (int i = 0; i < _cart.length; i++) {
          final pIndex = _products.indexWhere((p) => p.id == _cart[i].product.id);
          if (pIndex != -1) {
            _cart[i] = _cart[i].copyWith(product: _products[pIndex]);
          }
        }
      }

      _invoiceCounter = prefs.getInt(_invoiceCounterKey) ?? 1001;
      if (_invoiceCounter == 1001) {
        final counterStr = await _readInternalFile('pos_counter.json');
        if (counterStr != null) {
          _invoiceCounter = int.tryParse(counterStr) ?? 1001;
        }
      }

      // If app was uninstalled and freshly reinstalled, check if phone storage has existing backup
      if (_products.isEmpty) {
        final existingBackup = await BackupService.findExistingBackup();
        if (existingBackup != null) {
          final backupProducts = existingBackup['products'] as List?;
          if (backupProducts != null && backupProducts.isNotEmpty) {
            debugPrint('Found previous phone backup! Auto-restoring ${backupProducts.length} products...');
            await restoreBackupData(jsonEncode(existingBackup), triggerAutoSave: false);
          }
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from phone storage: $e');
    }
  }

  /// Manually trigger a backup save with fresh image embeddings
  Future<void> triggerManualBackup() async {
    await _triggerAutoBackup();
  }

  Future<void> _triggerAutoBackup() async {
    try {
      final List<Map<String, dynamic>> productMaps = [];
      bool pathsUpdated = false;

      for (int i = 0; i < _products.length; i++) {
        final p = _products[i];
        final m = p.toMap();

        if (p.imagePath != null && File(p.imagePath!).existsSync()) {
          // Embed Base64 so backup file is completely self-contained
          final b64 = await BackupService.imageFileToBase64(p.imagePath);
          if (b64 != null) {
            m['imageBase64'] = b64;
          }
          // Persist image to permanent Platano_POS/images folder if not already there
          if (!p.imagePath!.contains('Platano_POS')) {
            final perm = await BackupService.persistImageFile(p.imagePath!, p.id);
            if (perm != null && perm != p.imagePath) {
              m['imagePath'] = perm;
              _products[i] = p.copyWith(imagePath: perm);
              pathsUpdated = true;
            }
          }
        }
        productMaps.add(m);
      }

      if (pathsUpdated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_productsKey, jsonEncode(_products.map((p) => p.toMap()).toList()));
      }

      final Map<String, dynamic> backup = {
        'version': 1,
        'app': 'PLATANO POS',
        'exportDate': DateTime.now().toIso8601String(),
        'invoiceCounter': _invoiceCounter,
        'products': productMaps,
        'invoices': _invoices.map((inv) => inv.toMap()).toList(),
        'drafts': _drafts.map((d) => d.toMap()).toList(),
      };
      await BackupService.autoSaveBackup(backup);
    } catch (e) {
      debugPrint('Error triggering auto backup: $e');
    }
  }

  // --- Internal Direct Disk File Helpers (Crash/Kill Proof with flush: true) ---

  static Future<File?> _writeInternalFile(String fileName, String content) async {
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final file = File('${appDocs.path}/$fileName');
      return await file.writeAsString(content, flush: true);
    } catch (e) {
      debugPrint('Error writing internal file $fileName: $e');
      return null;
    }
  }

  static Future<String?> _readInternalFile(String fileName) async {
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final file = File('${appDocs.path}/$fileName');
      if (await file.exists()) {
        final text = await file.readAsString();
        if (text.trim().isNotEmpty) return text;
      }
    } catch (e) {
      debugPrint('Error reading internal file $fileName: $e');
    }
    return null;
  }

  static Future<void> _deleteInternalFile(String fileName) async {
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final file = File('${appDocs.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting internal file $fileName: $e');
    }
  }

  Future<void> _saveProducts() async {
    try {
      final jsonStr = jsonEncode(_products.map((p) => p.toMap()).toList());

      // 1. Write internal file directly with flush: true (survives instant process kills)
      await _writeInternalFile('pos_products.json', jsonStr);

      // 2. Also write to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_productsKey, jsonStr);

      // 3. Trigger auto backup
      _triggerAutoBackup();
    } catch (e) {
      debugPrint('Error saving products: $e');
    }
  }

  Future<void> _saveInvoices() async {
    try {
      final jsonStr = jsonEncode(_invoices.map((inv) => inv.toMap()).toList());
      await _writeInternalFile('pos_invoices.json', jsonStr);
      await _writeInternalFile('pos_counter.json', _invoiceCounter.toString());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invoicesKey, jsonStr);
      await prefs.setInt(_invoiceCounterKey, _invoiceCounter);
      _triggerAutoBackup();
    } catch (e) {
      debugPrint('Error saving invoices: $e');
    }
  }

  Future<void> _saveDrafts() async {
    try {
      final jsonStr = jsonEncode(_drafts.map((d) => d.toMap()).toList());
      await _writeInternalFile('pos_drafts.json', jsonStr);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftsKey, jsonStr);
      _triggerAutoBackup();
    } catch (e) {
      debugPrint('Error saving drafts: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      if (_cart.isEmpty) {
        await _deleteInternalFile('pos_cart.json');
        await _deleteInternalFile('pos_cart_discount.json');
      } else {
        final jsonStr = jsonEncode(_cart.map((c) => c.toMap()).toList());
        await _writeInternalFile('pos_cart.json', jsonStr);
        await _writeInternalFile('pos_cart_discount.json', _discount.toString());
      }

      final prefs = await SharedPreferences.getInstance();
      if (_cart.isEmpty) {
        await prefs.remove(_cartKey);
        await prefs.remove(_cartDiscountKey);
      } else {
        final jsonStr = jsonEncode(_cart.map((c) => c.toMap()).toList());
        await prefs.setString(_cartKey, jsonStr);
        await prefs.setDouble(_cartDiscountKey, _discount);
      }
    } catch (e) {
      debugPrint('Error saving cart to phone storage: $e');
    }
  }

  /// Exports all products, invoices, and drafts to a formatted JSON string (with embedded Base64 images)
  Future<String> exportBackupData() async {
    final List<Map<String, dynamic>> productMaps = [];
    for (final p in _products) {
      final m = p.toMap();
      if (p.imagePath != null && File(p.imagePath!).existsSync()) {
        final b64 = await BackupService.imageFileToBase64(p.imagePath);
        if (b64 != null) {
          m['imageBase64'] = b64;
        }
      }
      productMaps.add(m);
    }

    final Map<String, dynamic> backup = {
      'version': 1,
      'app': 'PLATANO POS',
      'exportDate': DateTime.now().toIso8601String(),
      'invoiceCounter': _invoiceCounter,
      'products': productMaps,
      'invoices': _invoices.map((inv) => inv.toMap()).toList(),
      'drafts': _drafts.map((d) => d.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Restores all data from JSON string into memory, SharedPreferences, and triggers backup
  Future<Map<String, int>> restoreBackupData(String jsonString, {bool triggerAutoSave = true}) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    int pCount = 0;
    int invCount = 0;
    int dCount = 0;

    if (data['products'] is List) {
      final List<dynamic> pList = data['products'];
      if (pList.isNotEmpty) {
        _products.clear();
        for (final it in pList) {
          final pMap = Map<String, dynamic>.from(it as Map);
          final productId = pMap['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
          final originalImagePath = pMap['imagePath']?.toString();
          final base64Image = pMap['imageBase64']?.toString();

          // Restore image file from Base64 or resolve from Platano_POS/images
          final restoredPath = await BackupService.resolveOrRestoreImage(
            productId: productId,
            originalPath: originalImagePath,
            base64Data: base64Image,
          );

          pMap['imagePath'] = restoredPath;
          _products.add(Product.fromMap(pMap));
          pCount++;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_productsKey, jsonEncode(_products.map((p) => p.toMap()).toList()));
      }
    }

    if (data['invoices'] is List) {
      final List<dynamic> invList = data['invoices'];
      _invoices.clear();
      for (final it in invList) {
        _invoices.add(Invoice.fromMap(Map<String, dynamic>.from(it as Map)));
        invCount++;
      }
      if (data['invoiceCounter'] is int) {
        _invoiceCounter = data['invoiceCounter'] as int;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invoicesKey, jsonEncode(_invoices.map((inv) => inv.toMap()).toList()));
      await prefs.setInt(_invoiceCounterKey, _invoiceCounter);
    }

    if (data['drafts'] is List) {
      final List<dynamic> dList = data['drafts'];
      _drafts.clear();
      for (final it in dList) {
        _drafts.add(DraftBill.fromMap(Map<String, dynamic>.from(it as Map)));
        dCount++;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftsKey, jsonEncode(_drafts.map((d) => d.toMap()).toList()));
    }

    if (triggerAutoSave) {
      await _triggerAutoBackup();
    }

    notifyListeners();
    return {
      'products': pCount,
      'invoices': invCount,
      'drafts': dCount,
    };
  }

  // --- Draft Bills Management ---

  DraftBill saveCurrentCartAsDraft({
    String customerName = 'Walk-in Customer',
    String customerPhone = '',
    String note = '',
  }) {
    if (_cart.isEmpty) {
      throw Exception('Cart is empty');
    }
    final draft = DraftBill(
      id: 'DFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      dateTime: DateTime.now(),
      customerName: customerName.trim().isEmpty ? 'Walk-in Customer' : customerName.trim(),
      customerPhone: customerPhone.trim(),
      items: List.from(_cart),
      subtotal: subtotal,
      discount: _discount,
      grandTotal: grandTotal,
      note: note.trim(),
    );
    _drafts.insert(0, draft);
    _saveDrafts();
    clearCart();
    return draft;
  }

  void resumeDraft(DraftBill draft) {
    _cart.clear();
    _cart.addAll(draft.items);
    _discount = draft.discount;
    _drafts.removeWhere((d) => d.id == draft.id);
    _saveDrafts();
    _saveCart();
    notifyListeners();
  }

  void deleteDraft(String id) {
    _drafts.removeWhere((d) => d.id == id);
    _saveDrafts();
    notifyListeners();
  }

  /// Clear all products and reset cart
  Future<void> clearAllProducts() async {
    _products.clear();
    _cart.clear();
    notifyListeners();
    await _saveProducts();
    await _saveCart();
  }

  // --- Product Management ---

  Future<void> addProduct(Product product) async {
    _products.add(product);
    notifyListeners();
    await _saveProducts();
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
      await _saveProducts();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    _cart.removeWhere((item) => item.product.id == id);
    notifyListeners();
    await _saveProducts();
    await _saveCart();
  }

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return _products;
    final lower = query.toLowerCase().trim();
    return _products.where((p) {
      final nameMatches = p.name.toLowerCase().contains(lower);
      final codeMatches = p.code.toLowerCase().contains(lower);
      final catMatches = p.category.toLowerCase().contains(lower);
      return nameMatches || codeMatches || catMatches;
    }).toList();
  }

  // --- Cart / Billing Management ---

  Future<void> addToCart(Product product, {double quantity = 1.0}) async {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
    await _saveCart();
  }

  Future<void> updateQuantity(String productId, double quantity) async {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = quantity;
      }
      notifyListeners();
      await _saveCart();
    }
  }

  Future<void> incrementQuantity(String productId) async {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _cart[index].quantity += 1.0;
      notifyListeners();
      await _saveCart();
    }
  }

  Future<void> decrementQuantity(String productId) async {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_cart[index].quantity > 1.0) {
        _cart[index].quantity -= 1.0;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
      await _saveCart();
    }
  }

  Future<void> removeFromCart(String productId) async {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    await _saveCart();
  }

  Future<void> clearCart() async {
    _cart.clear();
    _discount = 0.0;
    notifyListeners();
    await _saveCart();
  }

  Future<void> setDiscount(double discount) async {
    _discount = discount;
    notifyListeners();
    await _saveCart();
  }

  double get subtotal {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get grandTotal {
    final total = subtotal - _discount;
    return total > 0 ? total : 0.0;
  }

  // --- Invoice Creation ---

  Invoice checkout({
    String customerName = 'Cash Customer',
    String customerPhone = '',
    String paymentMethod = 'Cash',
  }) {
    if (_cart.isEmpty) {
      throw Exception('Cart is empty');
    }

    final invoice = Invoice(
      id: 'INV-${_invoiceCounter++}',
      dateTime: DateTime.now(),
      customerName: customerName.trim().isEmpty ? 'Cash Customer' : customerName.trim(),
      customerPhone: customerPhone.trim(),
      items: List.from(_cart),
      subtotal: subtotal,
      discount: _discount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
    );

    // Update stock if needed
    for (final item in _cart) {
      final pIndex = _products.indexWhere((p) => p.id == item.product.id);
      if (pIndex != -1) {
        final current = _products[pIndex];
        final newStock = (current.stock - item.quantity.toInt()).clamp(0, 999999);
        _products[pIndex] = current.copyWith(stock: newStock);
      }
    }

    _invoices.add(invoice);
    _saveInvoices();
    _saveProducts();
    clearCart();
    return invoice;
  }

  double get todaySales {
    final now = DateTime.now();
    return _invoices
        .where((inv) =>
            inv.dateTime.year == now.year &&
            inv.dateTime.month == now.month &&
            inv.dateTime.day == now.day)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }
}
