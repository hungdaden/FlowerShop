import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_product_card.dart';

/// Featured Products section with glass product cards.
class FeaturedProductsSection extends StatelessWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: AppTheme.spacing96,
      ),
      color: AppColors.surface.withValues(alpha: 0.5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            children: [
              Text('Sản phẩm nổi bật',
                  style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppTheme.maxTextWidth),
                child: Text(
                  'Những bó hoa được yêu thích nhất, được chọn lọc kỹ càng từ những bông hoa tươi nhất',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              if (provider.isLoading)
                _buildSkeletonGrid(isMobile)
              else if (provider.featuredProducts.isEmpty)
                _buildEmpty()
              else
                _buildGrid(context, provider.featuredProducts, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, List<ProductModel> products, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.65 : 0.68,
      ),
      itemCount: products.length.clamp(0, 8),
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
      itemCount: 4,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(Icons.local_florist,
            size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          'Chưa có sản phẩm nổi bật',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}


