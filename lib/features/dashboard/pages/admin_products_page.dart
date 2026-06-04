import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../widgets/admin_layout.dart';

final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  ProductModel? _editingProduct;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imagesController = TextEditingController();
  String _selectedCollectionId = '';
  bool _isFeatured = false;
  bool _isActive = true;

  void _clearForm() {
    _editingProduct = null;
    _nameController.clear();
    _priceController.clear();
    _descController.clear();
    _imagesController.clear();
    _isFeatured = false;
    _isActive = true;
    _selectedCollectionId = '';
  }

  void _fillForm(ProductModel p) {
    _editingProduct = p;
    _nameController.text = p.name;
    _priceController.text = p.price.toStringAsFixed(0);
    _descController.text = p.description;
    _imagesController.text = p.imageUrls.join(', ');
    _isFeatured = p.isFeatured;
    _isActive = p.isActive;
    _selectedCollectionId = p.collectionId;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final collectionProvider = context.watch<CollectionProvider>();

    return AdminLayout(
      currentPath: '/admin/products',
      title: 'Quản lý sản phẩm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header button to add product
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách hoa', style: AppTextStyles.h4),
              GlassButton(
                onPressed: () {
                  _clearForm();
                  if (collectionProvider.collections.isNotEmpty) {
                    _selectedCollectionId = collectionProvider.collections.first.id;
                  }
                  _showFormDialog(context, collectionProvider.collections);
                },
                label: 'Thêm sản phẩm',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main DataTable inside GlassCard
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : productProvider.products.isEmpty
                      ? const Center(child: Text('Chưa có sản phẩm nào.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Hình ảnh')),
                                DataColumn(label: Text('Tên sản phẩm')),
                                DataColumn(label: Text('Bộ sưu tập')),
                                DataColumn(label: Text('Giá bán')),
                                DataColumn(label: Text('Trạng thái')),
                                DataColumn(label: Text('Hành động')),
                              ],
                              rows: productProvider.products.map((p) {
                                final colList = collectionProvider.collections.where((c) => c.id == p.collectionId).toList();
                                final colName = colList.isNotEmpty ? colList.first.name : 'Không rõ';
                                final img = p.imageUrls.isNotEmpty ? p.imageUrls.first : '';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: img.isNotEmpty
                                            ? Image.network(img, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>_placeholderIcon())
                                            : _placeholderIcon(),
                                      ),
                                    ),
                                    DataCell(Text(p.name, style: AppTextStyles.label)),
                                    DataCell(Text(colName)),
                                    DataCell(Text(_currencyFormat.format(p.price))),
                                    DataCell(
                                      Row(
                                        children: [
                                          if (p.isFeatured) ...[
                                            const Icon(Icons.star_rounded, color: AppColors.secondary, size: 18),
                                            const SizedBox(width: 4),
                                          ],
                                          Icon(
                                            p.isActive ? Icons.check_circle_outline : Icons.remove_circle_outline,
                                            color: p.isActive ? AppColors.success : AppColors.textLight,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                            onPressed: () {
                                              _fillForm(p);
                                              _showFormDialog(context, collectionProvider.collections);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                            onPressed: () => _confirmDelete(p.id, productProvider),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: const Icon(Icons.local_florist, size: 20, color: AppColors.primary),
    );
  }

  void _showFormDialog(BuildContext context, List<dynamic> collections) {
    if (collections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Vui lòng tạo ít nhất 1 bộ sưu tập trước khi thêm sản phẩm.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
          title: Text(_editingProduct == null ? 'Thêm sản phẩm mới' : 'Cập nhật sản phẩm'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassTextField(
                      controller: _nameController,
                      label: 'Tên sản phẩm',
                      hint: 'VD: Bó hồng nhung tình yêu',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _priceController,
                      label: 'Giá bán (VND)',
                      hint: 'VD: 550000',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Không được để trống';
                        if (double.tryParse(val.trim()) == null) return 'Giá trị không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Collection Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bộ sưu tập', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCollectionId.isEmpty ? collections.first.id : _selectedCollectionId,
                              isExpanded: true,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    _selectedCollectionId = val;
                                  });
                                }
                              },
                              items: collections.map((col) {
                                return DropdownMenuItem<String>(
                                  value: col.id,
                                  child: Text(col.name),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _descController,
                      label: 'Mô tả',
                      hint: 'Nhập thông tin chi tiết về loại hoa, số cành...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _imagesController,
                      label: 'Link hình ảnh (Phân tách bằng dấu phẩy)',
                      hint: 'https://images.unsplash.com/photo-1...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Switches
                    Row(
                      children: [
                        Checkbox(
                          value: _isFeatured,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _isFeatured = val;
                              });
                            }
                          },
                        ),
                        Text('Sản phẩm nổi bật', style: AppTextStyles.label),
                        const Spacer(),
                        Checkbox(
                          value: _isActive,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _isActive = val;
                              });
                            }
                          },
                        ),
                        Text('Đang hoạt động', style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => _saveProduct(context),
              child: Text(
                'Lưu',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final desc = _descController.text.trim();
    final imgStr = _imagesController.text.trim();
    final imageUrls = imgStr.isNotEmpty ? imgStr.split(',').map((s) => s.trim()).toList() : <String>[];

    final productProvider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_editingProduct == null) {
        // Create new
        final newProd = ProductModel(
          id: '',
          name: name,
          price: price,
          description: desc,
          imageUrls: imageUrls,
          collectionId: _selectedCollectionId.isEmpty ? _selectedCollectionId : _selectedCollectionId,
          isFeatured: _isFeatured,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await productProvider.addProduct(newProd);
      } else {
        // Edit existing
        final data = {
          'name': name,
          'price': price,
          'description': desc,
          'imageUrls': imageUrls,
          'collectionId': _selectedCollectionId,
          'isFeatured': _isFeatured,
          'isActive': _isActive,
        };
        await productProvider.updateProduct(_editingProduct!.id, data);
      }
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(backgroundColor: AppColors.success, content: Text('Lưu sản phẩm thành công.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Lỗi: $e')),
      );
    }
  }

  void _confirmDelete(String id, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await provider.deleteProduct(id);
              messenger.showSnackBar(
                const SnackBar(backgroundColor: AppColors.success, content: Text('Xóa sản phẩm thành công.')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imagesController.dispose();
    super.dispose();
  }
}
