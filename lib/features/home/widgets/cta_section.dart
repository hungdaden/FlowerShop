import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_button.dart';

/// Call-to-action section at the bottom of home page.
class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: AppTheme.spacing96,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.3),
            AppColors.background,
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxTextWidth),
          child: Column(
            children: [
              Text(
                '🌸',
                style: TextStyle(fontSize: isMobile ? 48 : 64),
              ),
              const SizedBox(height: 24),
              Text(
                'Đặt hoa ngay hôm nay',
                style: isMobile ? AppTextStyles.h3 : AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Hãy để Flower Shop giúp bạn truyền tải thông điệp yêu thương qua những bông hoa tươi đẹp nhất.',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              GlassButton(
                label: 'Đặt hoa ngay',
                icon: Icons.local_florist_rounded,
                onPressed: () => context.go('/products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
