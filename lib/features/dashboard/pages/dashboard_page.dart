import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../widgets/admin_layout.dart';

final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final totalProducts = productProvider.products.length;
    final totalOrders = orderProvider.orders.length;
    final todayOrders = orderProvider.todayOrders.length;
    final totalRevenue = orderProvider.totalRevenue;

    return AdminLayout(
      currentPath: '/admin/dashboard',
      title: 'Tổng quan hệ thống',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width < 768 ? 2 : 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _buildMetricCard(
                title: 'Tổng doanh thu',
                value: _currencyFormat.format(totalRevenue),
                icon: Icons.monetization_on_rounded,
                color: AppColors.success,
              ),
              _buildMetricCard(
                title: 'Tổng đơn hàng',
                value: '$totalOrders',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.primary,
              ),
              _buildMetricCard(
                title: 'Đơn hàng hôm nay',
                value: '$todayOrders',
                icon: Icons.today_rounded,
                color: AppColors.secondary,
              ),
              _buildMetricCard(
                title: 'Sản phẩm hoạt động',
                value: '$totalProducts',
                icon: Icons.local_florist_rounded,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Lower Section: Quick actions & Stats list
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lối tắt quản lý', style: AppTextStyles.h4),
                        const SizedBox(height: 20),
                        _buildActionTile(
                          context: context,
                          title: 'Thêm sản phẩm mới',
                          description: 'Đăng hoa lên cửa hàng',
                          icon: Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          onTap: () => context.go('/admin/products'),
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          context: context,
                          title: 'Xử lý đơn hàng mới',
                          description: 'Kiểm tra & xác nhận đơn',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.secondary,
                          onTap: () => context.go('/admin/orders'),
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          context: context,
                          title: 'Tạo bộ sưu tập mới',
                          description: 'Phân loại hoa theo chủ đề',
                          icon: Icons.create_new_folder_rounded,
                          color: AppColors.info,
                          onTap: () => context.go('/admin/collections'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Recent Orders summary list
                Expanded(
                  flex: 5,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đơn hàng gần đây', style: AppTextStyles.h4),
                        const SizedBox(height: 20),
                        if (orderProvider.isLoading)
                          const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        else if (orderProvider.orders.isEmpty)
                          const Expanded(child: Center(child: Text('Chưa có đơn hàng nào.')))
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: orderProvider.orders.take(5).length,
                              itemBuilder: (context, index) {
                                final order = orderProvider.orders[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(order.customerName, style: AppTextStyles.label),
                                  subtitle: Text('Đơn giá: ${_currencyFormat.format(order.totalAmount)}'),
                                  trailing: Chip(
                                    label: Text(order.status.displayName),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  ),
                                  onTap: () => context.go('/admin/orders'),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontSize: value.length > 12 ? 18 : 24,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: Colors.white.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label),
                  Text(description, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
