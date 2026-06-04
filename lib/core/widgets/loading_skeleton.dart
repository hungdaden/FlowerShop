import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shimmer skeleton loading widget.
/// Replaces default CircularProgressIndicator as per DESIGN_SYSTEM.md.
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppTheme.radiusSmall,
  });

  /// Creates a circular skeleton (e.g., for avatars).
  const LoadingSkeleton.circle({
    super.key,
    double size = 48,
  })  : width = size,
        height = size,
        borderRadius = 999;

  /// Creates a card-shaped skeleton.
  const LoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 200,
  }) : borderRadius = AppTheme.radiusLarge;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFF5EEF0),
                Color(0xFFFFF0F5),
                Color(0xFFF5EEF0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Product card skeleton.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton.card(height: 180),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(height: 16, width: 140),
                const SizedBox(height: 8),
                const LoadingSkeleton(height: 14, width: 100),
                const SizedBox(height: 12),
                const LoadingSkeleton(height: 20, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
