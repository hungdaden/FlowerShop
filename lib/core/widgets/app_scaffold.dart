import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'glass_navbar.dart';

/// Main scaffold wrapper for User pages.
/// Includes GlassNavbar (sticky) and Footer.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String currentPath;
  final bool showNavbar;
  final bool showFooter;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentPath,
    this.showNavbar = true,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          body,
          // Floating navbar on top
          if (showNavbar)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: SafeArea(
                child: GlassNavbar(currentPath: currentPath),
              ),
            ),
        ],
      ),
    );
  }
}

/// Minimal footer with whitespace.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: isMobile
              ? _buildMobileFooter()
              : _buildDesktopFooter(),
        ),
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flower Shop',
                      style: AppTextStyles.h4
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text(
                    'Mang vẻ đẹp của hoa đến mọi khoảnh khắc đặc biệt trong cuộc sống.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 64),
            // Quick links
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Liên kết', style: AppTextStyles.label),
                  const SizedBox(height: 16),
                  _footerLink('Trang chủ'),
                  _footerLink('Bộ sưu tập'),
                  _footerLink('Sản phẩm'),
                ],
              ),
            ),
            // Support
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hỗ trợ', style: AppTextStyles.label),
                  const SizedBox(height: 16),
                  _footerLink('Theo dõi đơn hàng'),
                  _footerLink('Liên hệ'),
                  _footerLink('Chính sách'),
                ],
              ),
            ),
            // Contact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Liên hệ', style: AppTextStyles.label),
                  const SizedBox(height: 16),
                  _footerInfo(Icons.phone_rounded, '0123 456 789'),
                  _footerInfo(Icons.email_rounded, 'flowershop@floral.vn'),
                  _footerInfo(
                      Icons.location_on_rounded, 'Hà Nội'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Divider(color: AppColors.border.withValues(alpha: 0.3)),
        const SizedBox(height: 24),
        Text(
          '© 2026 Flower Shop. Tất cả quyền được bảo lưu.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      children: [
        Text('Flower Shop',
            style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        Text(
          'Mang vẻ đẹp của hoa đến mọi khoảnh khắc đặc biệt.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _footerInfo(Icons.phone_rounded, '0123 456 789'),
        _footerInfo(Icons.email_rounded, 'flowershop@floral.vn'),
        const SizedBox(height: 24),
        Divider(color: AppColors.border.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          '© 2026 Flower Shop.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(text, style: AppTextStyles.bodySmall),
      ),
    );
  }

  Widget _footerInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
