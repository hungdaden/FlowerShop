import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_button.dart';
import 'package:go_router/go_router.dart';

/// Hero section: 90vh with floating flower, tagline, and CTA.
class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _float = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // Background decorative circles
          ..._buildDecoCircles(screenWidth, screenHeight),

          // Content
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isMobile ? 24 : 64,
                  right: isMobile ? 24 : 64,
                  top: AppTheme.navbarHeight + 20,
                ),
                child: isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context, isTablet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // Left: Text content
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _fadeIn,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tagline badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '🌸 Hoa tươi mỗi ngày',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mang vẻ đẹp\ncủa hoa đến\nmọi khoảnh khắc',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: isTablet ? 40 : 52,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    'Flower Shop mang đến những bó hoa tươi đẹp nhất, được chọn lọc kỹ càng cho những dịp đặc biệt trong cuộc sống.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    GlassButton(
                      label: 'Khám phá ngay',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go('/products'),
                    ),
                    const SizedBox(width: 16),
                    GlassButtonSecondary(
                      label: 'Bộ sưu tập',
                      icon: Icons.collections_rounded,
                      onPressed: () => context.go('/collections'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        // Right: Floating flower image
        Expanded(
          flex: 4,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fadeIn, _float]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _float.value),
                  child: child,
                ),
              );
            },
            child: _buildFlowerImage(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeIn,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeIn.value,
          child: Transform.translate(
            offset: Offset(0, _slideUp.value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating flower
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _float.value),
                child: child,
              );
            },
            child: SizedBox(
              height: 200,
              child: _buildFlowerImage(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Mang vẻ đẹp\ncủa hoa đến\nmọi khoảnh khắc',
            style: AppTextStyles.h2.copyWith(fontSize: 32),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Flower Shop mang đến những bó hoa tươi đẹp nhất cho những dịp đặc biệt.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GlassButton(
            label: 'Khám phá ngay',
            icon: Icons.arrow_forward_rounded,
            width: 220,
            onPressed: () => context.go('/products'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.local_florist,
              size: 120,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecoCircles(double w, double h) {
    return [
      Positioned(
        top: h * 0.1,
        right: -80,
        child: _circle(200, AppColors.primaryLight.withValues(alpha: 0.15)),
      ),
      Positioned(
        bottom: h * 0.1,
        left: -60,
        child: _circle(160, AppColors.secondary.withValues(alpha: 0.1)),
      ),
      Positioned(
        top: h * 0.4,
        left: w * 0.3,
        child: _circle(80, AppColors.primary.withValues(alpha: 0.06)),
      ),
    ];
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
