import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/billing_manager.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductDialog({super.key, this.productToEdit});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _codeController;

  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Avil Milk';

  final List<String> _categories = [
    'Avil Milk',
    'Juice',
    'Shakes',
    'Mojitos',
    'Snacks',
    'Ice Cream',
    'Beverages',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _imagePath = p?.imagePath;

    if (p != null) {
      if (_categories.contains(p.category)) {
        _selectedCategory = p.category;
      } else {
        _categories.add(p.category);
        _selectedCategory = p.category;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Item Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.teal),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick existing photo from device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.teal),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use camera to capture item'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final code = _codeController.text.trim();

    final manager = BillingManager();

    if (widget.productToEdit != null) {
      // Edit existing
      final updated = widget.productToEdit!.copyWith(
        name: name,
        price: price,
        category: _selectedCategory,
        code: code,
        imagePath: _imagePath,
        clearImage: _imagePath == null,
      );
      manager.updateProduct(updated);
    } else {
      // Add new
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        category: _selectedCategory,
        code: code.isEmpty ? '${manager.products.length + 101}' : code,
        imagePath: _imagePath,
      );
      manager.addProduct(newProduct);
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.productToEdit != null ? 'Item updated successfully!' : 'Item added successfully! ✅',
        ),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Icon(isEditing ? Icons.edit : Icons.local_drink_rounded, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Item' : 'Add New Item',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Photo Picker Section
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          onTap: _showImageSourcePicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _imagePath != null ? Colors.teal : Colors.teal.shade200,
                                width: 2,
                              ),
                              image: (_imagePath != null && File(_imagePath!).existsSync())
                                  ? DecorationImage(
                                      image: FileImage(File(_imagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (_imagePath == null || !File(_imagePath!).existsSync())
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 34, color: Colors.teal.shade700),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (_imagePath != null)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: InkWell(
                              onTap: _showImageSourcePicker,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Special Avil Milk, Mango Juice',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Price and Item Code Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price (₹) *',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.currency_rupee, size: 22, color: Colors.black),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter price';
                            }
                            if (double.tryParse(val) == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Item Code (Optional)',
                            hintText: 'e.g. 101',
                            prefixIcon: Icon(Icons.qr_code),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveProduct,
                    icon: Icon(isEditing ? Icons.check : Icons.save),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Add Item',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
