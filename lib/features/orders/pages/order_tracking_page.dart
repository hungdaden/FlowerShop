import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Check if there is already search searchResults in the provider (pre-filled from checkout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      if (orderProvider.searchResults.isNotEmpty) {
        setState(() {
          _hasSearched = true;
          // Set phone controller to the phone of the first search result
          _phoneController.text = orderProvider.searchResults.first.phone;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Text(
                      'Theo dõi đơn hàng',
                      style: isMobile
                          ? AppTextStyles.h2.copyWith(fontSize: 28)
                          : AppTextStyles.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập số điện thoại của bạn để kiểm tra trạng thái và lịch trình vận chuyển đơn hàng.',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Search Form
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _phoneController,
                                hint: 'Nhập số điện thoại đặt hàng (VD: 0987654321)',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_android_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập số điện thoại';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 52,
                              child: GlassButton(
                                onPressed: _searchOrders,
                                label: 'Tra cứu',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    if (orderProvider.isSearching)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else if (_hasSearched)
                      orderProvider.searchResults.isEmpty
                          ? _buildEmptyState()
                          : _buildOrdersList(orderProvider.searchResults)
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

  void _searchOrders() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OrderProvider>().searchByPhone(_phoneController.text.trim());
    setState(() {
      _hasSearched = true;
    });
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Không tìm thấy đơn hàng nào!', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text('Vui lòng kiểm tra lại số điện thoại đã nhập.', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Order header
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('MÃ ĐƠN: ${order.id}', style: AppTextStyles.label, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Ngày đặt: ${_dateFormat.format(order.createdAt)}', style: AppTextStyles.caption),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MÃ ĐƠN HÀNG: ${order.id}', style: AppTextStyles.label),
                              const SizedBox(height: 4),
                              Text('Ngày đặt: ${_dateFormat.format(order.createdAt)}', style: AppTextStyles.caption),
                            ],
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),

                // Order items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: AppColors.primaryLight.withValues(alpha: 0.2),
                              child: item.imageUrl != null
                                  ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.local_florist, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: AppTextStyles.label),
                                const SizedBox(height: 4),
                                Text('${_currencyFormat.format(item.price)} x ${item.quantity}', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng thanh toán:', style: AppTextStyles.body),
                    Text(_currencyFormat.format(order.totalAmount), style: AppTextStyles.priceSmall),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Progress Tracker
                Text('Tiến trình đơn hàng', style: AppTextStyles.label),
                const SizedBox(height: 24),
                _buildProgressTracker(order.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTracker(OrderStatus status) {
    if (status == OrderStatus.cancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Text('Đơn hàng đã bị hủy bỏ', style: AppTextStyles.label.copyWith(color: AppColors.error)),
        ],
      );
    }

    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.delivering,
      OrderStatus.completed,
    ];

    final activeIndex = steps.indexOf(status);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= activeIndex;
            final isActive = index == activeIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 0
                              ? Colors.transparent
                              : (isCompleted ? AppColors.primary : AppColors.border.withValues(alpha: 0.3)),
                        ),
                      ),
                      AnimatedContainer(
                        duration: AppTheme.animNormal,
                        width: isActive ? 24 : 16,
                        height: isActive ? 24 : 16,
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? AppColors.primary : AppColors.border,
                            width: isActive ? 4 : 2,
                          ),
                          boxShadow: isActive
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)]
                              : [],
                        ),
                        child: isCompleted && !isActive
                            ? const Icon(Icons.check, size: 10, color: Colors.white)
                            : null,
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == steps.length - 1
                              ? Colors.transparent
                              : (index < activeIndex ? AppColors.primary : AppColors.border.withValues(alpha: 0.3)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(step),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : (isCompleted ? AppColors.textPrimary : AppColors.textLight),
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  String _getStepTitle(OrderStatus step) {
    switch (step) {
      case OrderStatus.pending:
        return 'Chờ duyệt';
      case OrderStatus.confirmed:
        return 'Đã nhận';
      case OrderStatus.preparing:
        return 'Đang cắm';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      default:
        return '';
    }
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.labelSmall.copyWith(color: _getStatusColor(status)),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
      case OrderStatus.delivering:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
