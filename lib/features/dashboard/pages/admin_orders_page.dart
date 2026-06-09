import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../widgets/admin_layout.dart';

final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final filteredOrders = _selectedStatusFilter == 'all'
        ? orderProvider.orders
        : orderProvider.orders.where((o) => o.status.name == _selectedStatusFilter).toList();

    return AdminLayout(
      currentPath: '/admin/orders',
      title: 'Quản lý đơn hàng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                Text('Trạng thái:', style: AppTextStyles.label),
                const SizedBox(width: 12),
                _buildFilterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.pending.name, OrderStatus.pending.displayName),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.confirmed.name, OrderStatus.confirmed.displayName),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.preparing.name, OrderStatus.preparing.displayName),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.delivering.name, OrderStatus.delivering.displayName),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.completed.name, OrderStatus.completed.displayName),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.cancelled.name, OrderStatus.cancelled.displayName),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Orders List
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredOrders.isEmpty
                    ? const GlassCard(child: Center(child: Text('Không có đơn hàng nào.')))
                    : ListView.builder(
                        clipBehavior: Clip.none,
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(context, order, orderProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = value;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, OrderProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MÃ ĐƠN: ${order.id}', style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text('Ngày đặt: ${_dateFormat.format(order.createdAt)}', style: AppTextStyles.caption),
                  ],
                ),
                // Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _getStatusColor(order.status)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<OrderStatus>(
                      value: order.status,
                      style: AppTextStyles.labelSmall.copyWith(color: _getStatusColor(order.status)),
                      iconEnabledColor: _getStatusColor(order.status),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          provider.updateStatus(order.id, newStatus);
                        }
                      },
                      items: OrderStatus.values.map((status) {
                        return DropdownMenuItem<OrderStatus>(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Customer Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.person_outline_rounded, 'Khách hàng: ${order.customerName}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.phone_android_rounded, 'Số điện thoại: ${order.phone}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.location_on_outlined, 'Địa chỉ: ${order.address}'),
                      if (order.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow(Icons.note_alt_outlined, 'Ghi chú: ${order.note}', isItalic: true),
                      ],
                    ],
                  ),
                ),
                // Items Summary
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sản phẩm', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${item.productName} (x${item.quantity})',
                              style: AppTextStyles.bodySmall,
                            ),
                          )),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng tiền:', style: AppTextStyles.label),
                          Text(_currencyFormat.format(order.totalAmount), style: AppTextStyles.priceSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isItalic = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: isItalic
                ? AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)
                : AppTextStyles.bodySmall,
          ),
        ),
      ],
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
}
