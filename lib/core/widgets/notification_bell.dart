import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/app_providers.dart';
import '../models/notification_model.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Clear overlay tap area to close the dropdown
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeDropdown,
            child: const SizedBox.expand(),
          ),
          Positioned(
            width: 340,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(-340 + size.width, size.height + 12),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (context, provider, child) {
                          final recentNotifications = provider.notifications.take(5).toList();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Thông báo',
                                      style: AppTextStyles.h5.copyWith(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (provider.unreadCount > 0)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          provider.markAllAsRead();
                                        },
                                        child: Text(
                                          'Đọc tất cả',
                                          style: AppTextStyles.buttonSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              // Body / List
                              if (recentNotifications.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: 40,
                                        color: AppColors.textLight.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Chưa có thông báo nào',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 320),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: recentNotifications.length,
                                    itemBuilder: (context, index) {
                                      final item = recentNotifications[index];
                                      return InkWell(
                                        onTap: () {
                                          if (!item.isRead) {
                                            provider.markAsRead(item.id);
                                          }
                                          _closeDropdown();

                                          // Route based on type
                                          if (item.type == NotificationType.orderUpdate && item.orderId != null) {
                                            context.go('/order-tracking?id=${item.orderId}');
                                          } else if (item.type == NotificationType.chat) {
                                            context.go('/chat');
                                          }
                                        },
                                        child: Container(
                                          color: item.isRead
                                              ? Colors.transparent
                                              : AppColors.primary.withValues(alpha: 0.05),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Icon type
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: item.isRead
                                                      ? AppColors.background
                                                      : AppColors.primaryLight.withValues(alpha: 0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _getIconForType(item.type),
                                                  size: 18,
                                                  color: item.isRead
                                                      ? AppColors.textSecondary
                                                      : AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: AppTextStyles.labelSmall.copyWith(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: item.isRead
                                                            ? FontWeight.normal
                                                            : FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.body,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: AppColors.textSecondary,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _formatTimeAgo(item.createdAt),
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: AppColors.textLight,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!item.isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4, left: 8),
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _toggleDropdown,
                icon: Icon(
                  _isOpen ? Icons.notifications : Icons.notifications_outlined,
                  color: _isOpen ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (provider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        provider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
