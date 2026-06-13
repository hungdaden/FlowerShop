import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/scroll_controllers.dart';
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
              : _buildDesktopFooter(context),
        ),
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
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
                  _footerLink(context, 'Trang chủ', '/'),
                  _footerLink(context, 'Bộ sưu tập', '/collections'),
                  _footerLink(context, 'Sản phẩm', '/products'),
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
                  _footerLink(context, 'Theo dõi đơn hàng', '/order-tracking'),
                  _footerLink(context, 'Liên hệ', '/chat'),
                  _footerLink(context, 'Chính sách', '/policy'),
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

  Widget _footerLink(BuildContext context, String text, String path) {
    return FooterLink(
      text: text,
      onTap: () {
        if (path == '/policy') {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Chính sách của chúng tôi hiện đang được cập nhật.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        } else {
          final currentPath = GoRouterState.of(context).uri.path;
          if (currentPath == path) {
            ScrollController? controller;
            if (path == '/') {
              controller = homeScrollController;
            } else if (path == '/collections') {
              controller = collectionsScrollController;
            } else if (path == '/products') {
              controller = productsScrollController;
            }

            if (controller != null && controller.hasClients) {
              controller.animateTo(
                0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
              );
            }
          } else {
            context.go(path);
          }
        }
      },
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

class FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const FooterLink({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  State<FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: AppTextStyles.bodySmall.copyWith(
              color: _isHovered ? AppColors.primary : AppColors.textSecondary,
              decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AppColors.primary,
            ),
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}

