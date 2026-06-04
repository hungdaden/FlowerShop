import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';

/// Common layout wrapper for all Admin Management pages.
/// Implements Auth checking, responsive sidebar/drawer, and branding.
class AdminLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;

    // Route Guard: redirect to admin login if not logged in
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/admin');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final sidebarItems = [
      _SidebarItem('Tổng quan', '/admin/dashboard', Icons.dashboard_rounded),
      _SidebarItem('Sản phẩm', '/admin/products', Icons.local_florist_rounded),
      _SidebarItem('Bộ sưu tập', '/admin/collections', Icons.collections_rounded),
      _SidebarItem('Đơn hàng', '/admin/orders', Icons.local_shipping_rounded),
      _SidebarItem('Hỗ trợ chat', '/admin/chat', Icons.chat_bubble_rounded),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          title: Text(title, style: AppTextStyles.h4),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.error),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSidebarHeader(context),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: sidebarItems
                        .map((item) => _buildSidebarTile(context, item))
                        .toList(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.arrow_back_rounded),
                  title: const Text('Xem User Web'),
                  onTap: () => context.go('/'),
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: AppColors.error),
                  title: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        body: SafeArea(child: child),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar Panel (Left)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(context),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    children: sidebarItems
                        .map((item) => _buildSidebarTile(context, item))
                        .toList(),
                  ),
                ),
                const Divider(height: 1),
                // Footer buttons in sidebar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSidebarActionTile(
                        icon: Icons.arrow_back_rounded,
                        label: 'Xem User Web',
                        onTap: () => context.go('/'),
                      ),
                      const SizedBox(height: 8),
                      _buildSidebarActionTile(
                        icon: Icons.exit_to_app_rounded,
                        label: 'Đăng xuất',
                        textColor: AppColors.error,
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Panel (Right)
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: AppTextStyles.h2),
                        // Admin badge
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              radius: 18,
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              authProvider.currentUser?.email ?? 'Admin',
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Child Page content
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 40,
                width: 40,
                color: AppColors.primaryLight,
                child: const Icon(Icons.local_florist, color: AppColors.primary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flower Shop', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
              Text('Hệ thống Quản lý', style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(BuildContext context, _SidebarItem item) {
    final isActive = currentPath == item.path;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: AppTextStyles.label.copyWith(
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isActive,
        selectedTileColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        onTap: () => context.go(item.path),
      ),
    );
  }

  Widget _buildSidebarActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor ?? AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
              context.go('/admin');
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final String label;
  final String path;
  final IconData icon;
  const _SidebarItem(this.label, this.path, this.icon);
}
