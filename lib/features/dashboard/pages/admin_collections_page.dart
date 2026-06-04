import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/collection_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../widgets/admin_layout.dart';

class AdminCollectionsPage extends StatefulWidget {
  const AdminCollectionsPage({super.key});

  @override
  State<AdminCollectionsPage> createState() => _AdminCollectionsPageState();
}

class _AdminCollectionsPageState extends State<AdminCollectionsPage> {
  CollectionModel? _editingCollection;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  bool _isActive = true;

  void _clearForm() {
    _editingCollection = null;
    _nameController.clear();
    _descController.clear();
    _imageController.clear();
    _isActive = true;
  }

  void _fillForm(CollectionModel c) {
    _editingCollection = c;
    _nameController.text = c.name;
    _descController.text = c.description;
    _imageController.text = c.imageUrl;
    _isActive = c.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();

    return AdminLayout(
      currentPath: '/admin/collections',
      title: 'Quản lý danh mục',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách bộ sưu tập', style: AppTextStyles.h4),
              GlassButton(
                onPressed: () {
                  _clearForm();
                  _showFormDialog(context);
                },
                label: 'Thêm bộ sưu tập',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main collections table
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: collectionProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : collectionProvider.collections.isEmpty
                      ? const Center(child: Text('Chưa có bộ sưu tập nào.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Hình ảnh')),
                                DataColumn(label: Text('Tên danh mục')),
                                DataColumn(label: Text('Mô tả')),
                                DataColumn(label: Text('Trạng thái')),
                                DataColumn(label: Text('Hành động')),
                              ],
                              rows: collectionProvider.collections.map((c) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: c.imageUrl.isNotEmpty
                                            ? Image.network(c.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>_placeholderIcon())
                                            : _placeholderIcon(),
                                      ),
                                    ),
                                    DataCell(Text(c.name, style: AppTextStyles.label)),
                                    DataCell(
                                      SizedBox(
                                        width: 300,
                                        child: Text(c.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        c.isActive ? Icons.check_circle_outline : Icons.remove_circle_outline,
                                        color: c.isActive ? AppColors.success : AppColors.textLight,
                                        size: 18,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                            onPressed: () {
                                              _fillForm(c);
                                              _showFormDialog(context);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                            onPressed: () => _confirmDelete(c.id, collectionProvider),
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
      child: const Icon(Icons.collections, size: 20, color: AppColors.primary),
    );
  }

  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
          title: Text(_editingCollection == null ? 'Thêm bộ sưu tập mới' : 'Cập nhật bộ sưu tập'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassTextField(
                      controller: _nameController,
                      label: 'Tên bộ sưu tập',
                      hint: 'VD: Hoa Sinh Nhật',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _descController,
                      label: 'Mô tả bộ sưu tập',
                      hint: 'VD: Các mẫu thiết kế đặc sắc chúc mừng tuổi mới...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _imageController,
                      label: 'Link hình ảnh danh mục',
                      hint: 'https://images.unsplash.com/photo-1...',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
              onPressed: () => _saveCollection(context),
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

  Future<void> _saveCollection(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final imgUrl = _imageController.text.trim();

    final collectionProvider = context.read<CollectionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_editingCollection == null) {
        final newCol = CollectionModel(
          id: '',
          name: name,
          description: desc,
          imageUrl: imgUrl,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await collectionProvider.addCollection(newCol);
      } else {
        final data = {
          'name': name,
          'description': desc,
          'imageUrl': imgUrl,
          'isActive': _isActive,
        };
        await collectionProvider.updateCollection(_editingCollection!.id, data);
      }
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(backgroundColor: AppColors.success, content: Text('Lưu bộ sưu tập thành công.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Lỗi: $e')),
      );
    }
  }

  void _confirmDelete(String id, CollectionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bộ sưu tập này? Các sản phẩm thuộc danh mục này vẫn được lưu trữ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await provider.deleteCollection(id);
              messenger.showSnackBar(
                const SnackBar(backgroundColor: AppColors.success, content: Text('Xóa bộ sưu tập thành công.')),
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
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}
