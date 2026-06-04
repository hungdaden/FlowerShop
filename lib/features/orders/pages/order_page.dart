import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/app_scaffold.dart';

final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill note if present from detail page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final note = context.read<OrderProvider>().checkoutNote;
      if (note != null && note.isNotEmpty) {
        _noteController.text = note;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final checkoutItem = orderProvider.checkoutItem;

    // If no active item, show empty state
    if (checkoutItem == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Không có sản phẩm nào trong giỏ hàng', style: AppTextStyles.h4),
              const SizedBox(height: 24),
              GlassButton(
                onPressed: () => context.go('/products'),
                label: 'Xem danh sách sản phẩm',
              ),
            ],
          ),
        ),
      );
    }

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
                    ? _buildMobileLayout(checkoutItem)
                    : _buildDesktopLayout(checkoutItem),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Shipping Details Form
        Expanded(
          flex: 6,
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin giao hàng', style: AppTextStyles.h3),
                  const SizedBox(height: 24),
                  GlassTextField(
                    controller: _nameController,
                    label: 'Họ và tên người nhận',
                    hint: 'Nhập đầy đủ họ tên',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại liên lạc',
                    hint: 'Nhập số điện thoại giao hàng',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r'^\d{9,11}$').hasMatch(val.trim())) {
                        return 'Số điện thoại không hợp lệ (9 - 11 chữ số)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassTextField(
                    controller: _addressController,
                    label: 'Địa chỉ giao hàng',
                    hint: 'Số nhà, tên đường, phường/xã, quận/huyện...',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập địa chỉ nhận hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassTextField(
                    controller: _noteController,
                    label: 'Ghi chú đơn hàng (Thời gian giao, Lời nhắn thiệp...)',
                    hint: 'Nhập lời chúc ghi trên thiệp tặng hoặc ghi chú giao hàng...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _isSubmitting
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : GlassButton(
                            onPressed: () => _submitOrder(item),
                            label: 'Xác nhận đặt hàng',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 42),
        // Right Column: Order Summary
        Expanded(
          flex: 4,
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tóm tắt đơn hàng', style: AppTextStyles.h4),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.local_florist, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text('Số lượng: ${item.quantity}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đơn giá', style: AppTextStyles.bodySmall),
                    Text(_currencyFormat.format(item.price), style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phí vận chuyển', style: AppTextStyles.bodySmall),
                    Text('Miễn phí', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng tiền', style: AppTextStyles.label),
                    Text(
                      _currencyFormat.format(item.total),
                      style: AppTextStyles.price.copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(OrderItem item) {
    return Column(
      children: [
        // Summary
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đơn hàng', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.local_florist, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Số lượng: ${item.quantity}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng:', style: AppTextStyles.label),
                  Text(_currencyFormat.format(item.total), style: AppTextStyles.priceSmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Form
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin giao hàng', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _nameController,
                  label: 'Người nhận',
                  hint: 'Nhập họ tên',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: 'Nhập SĐT nhận hoa',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^\d{9,11}$').hasMatch(val.trim())) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  hint: 'Địa chỉ giao hàng chi tiết',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _noteController,
                  label: 'Ghi chú',
                  hint: 'Lời ghi thiệp, giờ giao mong muốn...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : GlassButton(
                          onPressed: () => _submitOrder(item),
                          label: 'Xác nhận đặt hàng',
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder(OrderItem item) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final orderId = 'order_${const Uuid().v4().substring(0, 8)}';
      final order = OrderModel(
        id: orderId,
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
        items: [item],
        totalAmount: item.total,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final orderProvider = context.read<OrderProvider>();
      await orderProvider.createOrder(order);

      // Pre-fill phone number in search search results
      orderProvider.searchByPhone(_phoneController.text.trim());

      // Show success modal dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Text('Đặt hàng thành công!'),
              ],
            ),
            content: Text(
              'Cảm ơn bạn đã lựa chọn Flower Shop. Mã đơn hàng của bạn là: $orderId.\nBạn có thể theo dõi tiến độ đơn hàng bằng số điện thoại của mình.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/order-tracking'); // Redirect
                },
                child: Text('Theo dõi đơn hàng', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Có lỗi xảy ra: $e. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
