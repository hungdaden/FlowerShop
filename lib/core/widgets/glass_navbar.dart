import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

/// Floating glass navigation bar.
/// Desktop: centered floating pill. Mobile: simplified with hamburger.
class GlassNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String currentPath;

  const GlassNavbar({super.key, required this.currentPath});

  static const _navItems = [
    _NavItem('Trang chủ', '/', Icons.home_rounded),
    _NavItem('Bộ sưu tập', '/collections', Icons.collections_rounded),
    _NavItem('Sản phẩm', '/products', Icons.local_florist_rounded),
    _NavItem('Theo dõi đơn hàng', '/order-tracking', Icons.local_shipping_rounded),
    _NavItem('Liên hệ', '/chat', Icons.chat_bubble_rounded),
  ];

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.navbarHeight);

  bool _isActive(String path) {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: AppTheme.navbarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: isMobile
              ? _buildMobileNav(context)
              : _buildDesktopNav(context),
        ),
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Logo
              _buildLogo(context),
              const Spacer(),
              // Nav items
              ..._navItems.map((item) => _NavItemWidget(
                    item: item,
                    isActive: _isActive(item.path),
                    onTap: () => context.go(item.path),
                  )),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildLogo(context),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.textPrimary,
                onPressed: () => _showMobileMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_florist,
                      color: AppColors.primary, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Flower Shop',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MobileDrawer(
        items: _navItems,
        currentPath: currentPath,
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String path;
  final IconData icon;
  const _NavItem(this.label, this.path, this.icon);
}

class _NavItemWidget extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          curve: AppTheme.animCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : _isHovered
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            widget.item.label,
            style: widget.isActive
                ? AppTextStyles.navItemActive
                : AppTextStyles.navItem.copyWith(
                    color: _isHovered
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final List<_NavItem> items;
  final String currentPath;

  const _MobileDrawer({
    required this.items,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final isActive = item.path == '/'
                ? currentPath == '/'
                : currentPath.startsWith(item.path);
            return ListTile(
              leading: Icon(
                item.icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                item.label,
                style: isActive
                    ? AppTextStyles.navItemActive
                    : AppTextStyles.navItem,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go(item.path);
              },
            );
          }),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
