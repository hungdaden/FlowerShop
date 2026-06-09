import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A glassmorphism card component used throughout the app.
/// Provides backdrop blur, semi-transparent background, and subtle border.
class GlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableHover;
  final VoidCallback? onTap;
  final double hoverScale;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.radiusLarge,
    this.blur = 30,
    this.opacity = 0.15,
    this.borderOpacity = 0.3,
    this.padding,
    this.margin,
    this.enableHover = true,
    this.onTap,
    this.hoverScale = 1.02,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animNormal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(CurvedAnimation(parent: _controller, curve: AppTheme.animCurve));
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: AppTheme.animCurve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            cursor: widget.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => _onHoverChange(true),
            onExit: (_) => _onHoverChange(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _isHovered
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.border.withValues(alpha: widget.borderOpacity),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight.withValues(
                        alpha: 0.04 + (_shadowAnimation.value * 0.06),
                      ),
                      blurRadius: 20 + (_shadowAnimation.value * 20),
                      offset: Offset(0, 4 + (_shadowAnimation.value * 4)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius > 1.2 ? widget.borderRadius - 1.2 : widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blur,
                      sigmaY: widget.blur,
                    ),
                    child: Container(
                      padding: widget.padding,
                      color: Colors.white.withValues(
                        alpha: widget.opacity + (_shadowAnimation.value * 0.05),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
