import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();
  int _activeImageIndex = 0;
  ProductModel? _product;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final provider = context.read<ProductProvider>();
    final prod = await provider.getProduct(widget.productId);
    if (mounted) {
      setState(() {
        _product = prod;
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (_isFetching) {
      return const Scaffold(
        body: Center(child: LoadingSkeleton.card(height: 400, width: 600)),
      );
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không tìm thấy sản phẩm'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/products'),
                child: const Text('Quay lại cửa hàng'),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrls = product.imageUrls.isNotEmpty ? product.imageUrls : [''];

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
                child: isMobile
                    ? _buildMobileLayout(product, imageUrls)
                    : _buildDesktopLayout(product, imageUrls),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ProductModel product, List<String> imageUrls) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Image Gallery
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              TextButton.icon(
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                label: Text('Quay lại cửa hàng', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 20),
              // Main Image
              AspectRatio(
                aspectRatio: 1.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  child: imageUrls[_activeImageIndex].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrls[_activeImageIndex],
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => _placeholder(size: 80),
                        )
                      : _placeholder(size: 80),
                ),
              ),
              // Thumbnails
              if (imageUrls.length > 1) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final isActive = index == _activeImageIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _activeImageIndex = index),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isActive ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
                              width: isActive ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 2),
                            child: CachedNetworkImage(
                              imageUrl: imageUrls[index],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _placeholder(size: 30),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 48),
        // Right Column: Details & Sticky purchase panel
        Expanded(
          flex: 5,
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.h2),
                const SizedBox(height: 12),
                Text(
                  _currencyFormat.format(product.price),
                  style: AppTextStyles.price.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Text('Mô tả sản phẩm', style: AppTextStyles.h5),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Quantity selector
                Text('Số lượng', style: AppTextStyles.label),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quantityBtn(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text('$_quantity', style: AppTextStyles.h4),
                    ),
                    _quantityBtn(Icons.add, () {
                      setState(() => _quantity++);
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Note text field
                Text('Ghi chú đặc biệt (Tùy chọn)', style: AppTextStyles.label),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: _noteController,
                  hint: 'VD: Thiệp ghi chúc mừng sinh nhật vui vẻ, giao buổi sáng...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Order button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: GlassButton(
                    onPressed: _proceedToCheckout,
                    label: 'Đặt mua ngay',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ProductModel product, List<String> imageUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        TextButton.icon(
          onPressed: () => context.go('/products'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          label: Text('Quay lại', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(height: 12),
        // Image
        AspectRatio(
          aspectRatio: 1.1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: imageUrls[_activeImageIndex].isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrls[_activeImageIndex],
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _placeholder(size: 80),
                  )
                : _placeholder(size: 80),
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final isActive = index == _activeImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeImageIndex = index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
                        width: isActive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 2),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _placeholder(size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(product.name, style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          _currencyFormat.format(product.price),
          style: AppTextStyles.price,
        ),
        const SizedBox(height: 16),
        Text('Mô tả', style: AppTextStyles.h5),
        const SizedBox(height: 6),
        Text(
          product.description,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text('Số lượng', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Row(
          children: [
            _quantityBtn(Icons.remove, () {
              if (_quantity > 1) setState(() => _quantity--);
            }),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text('$_quantity', style: AppTextStyles.h4),
            ),
            _quantityBtn(Icons.add, () {
              setState(() => _quantity++);
            }),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ghi chú đặc biệt (Tùy chọn)', style: AppTextStyles.label),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _noteController,
          hint: 'Lời chúc ghi thiệp, thời gian giao...',
          maxLines: 3,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: GlassButton(
            onPressed: _proceedToCheckout,
            label: 'Đặt mua ngay',
          ),
        ),
      ],
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _placeholder({double size = 80}) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Icon(Icons.local_florist, size: size, color: AppColors.primary),
      ),
    );
  }

  void _proceedToCheckout() {
    final product = _product;
    if (product == null) return;

    final item = OrderItem(
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: _quantity,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
    );

    // Save details to provider
    context.read<OrderProvider>().setCheckoutDetails(item, _noteController.text);

    // Navigate to checkout
    context.go('/order');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
