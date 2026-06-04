import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_product_card.dart';
import '../../../core/widgets/app_scaffold.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _selectedCollectionId = 'all';

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final collectionProvider = context.watch<CollectionProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final filteredProducts = _selectedCollectionId == 'all'
        ? productProvider.products
        : productProvider.products.where((p) => p.collectionId == _selectedCollectionId).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.navbarHeight + 40),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 64,
              vertical: 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                child: Column(
                  children: [
                    Text('Sản phẩm', style: AppTextStyles.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppTheme.maxTextWidth),
                      child: Text(
                        'Tuyển chọn những bó hoa tươi thắm, tinh tế được cắm thủ công bởi các nghệ nhân.',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Filter Pills
                    if (!collectionProvider.isLoading && collectionProvider.collections.isNotEmpty)
                      _buildFilterPills(collectionProvider.collections, isMobile),

                    const SizedBox(height: 40),

                    if (productProvider.isLoading)
                      _buildSkeletonGrid(isMobile)
                    else if (filteredProducts.isEmpty)
                      _buildEmpty()
                    else
                      _buildGrid(context, filteredProducts, isMobile),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildFilterPills(List<dynamic> collections, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPill('all', 'Tất cả'),
          const SizedBox(width: 12),
          ...collections.map((col) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildPill(col.id, col.name),
              )),
        ],
      ),
    );
  }

  Widget _buildPill(String id, String label) {
    final isSelected = _selectedCollectionId == id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCollectionId = id;
          });
        },
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          curve: AppTheme.animCurve,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<dynamic> products, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.65 : 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return GlassProductCard(
          product: products[index],
          onTap: () => context.go('/products/${products[index].id}'),
        );
      },
    );
  }

  Widget _buildSkeletonGrid(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.65 : 0.68,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 64),
        Icon(Icons.local_florist_rounded,
            size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          'Chưa có sản phẩm nào thuộc danh mục này',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
