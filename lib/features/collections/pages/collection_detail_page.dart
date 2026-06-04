import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_product_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CollectionDetailPage extends StatelessWidget {
  final String collectionId;

  const CollectionDetailPage({
    super.key,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final productProvider = context.watch<ProductProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final collection = collectionProvider.collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => collectionProvider.collections.isNotEmpty
          ? collectionProvider.collections.first
          : throw Exception('Collection not found'),
    );

    final collectionProducts = productProvider.products
        .where((p) => p.collectionId == collectionId)
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner Section
          Stack(
            children: [
              Container(
                height: isMobile ? 250 : 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
                child: collection.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: collection.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.local_florist, size: 72, color: Colors.white),
                        ),
                      ),
              ),
              Container(
                height: isMobile ? 250 : 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: isMobile ? 24 : 64,
                right: isMobile ? 24 : 64,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: isMobile ? 32 : 48),
                        ),
                        if (collection.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            collection.description,
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Products List Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 64,
              vertical: 64,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sản phẩm trong bộ sưu tập',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 32),
                    if (productProvider.isLoading)
                      _buildSkeletonGrid(isMobile)
                    else if (collectionProducts.isEmpty)
                      _buildEmpty()
                    else
                      _buildGrid(context, collectionProducts, isMobile),
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
      itemCount: 4,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Icon(Icons.local_florist_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'Hiện tại chưa có sản phẩm nào trong bộ sưu tập này.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
