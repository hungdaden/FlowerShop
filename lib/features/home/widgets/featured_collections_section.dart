import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Featured Collections section: Apple Photos style cards.
class FeaturedCollectionsSection extends StatelessWidget {
  const FeaturedCollectionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: AppTheme.spacing96,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            children: [
              // Section header
              _SectionHeader(
                title: 'Bộ sưu tập',
                subtitle: 'Khám phá những bộ sưu tập được thiết kế riêng cho từng dịp đặc biệt',
              ),
              const SizedBox(height: 48),
              // Collection cards
              if (provider.isLoading)
                _buildSkeletonGrid(isMobile)
              else if (provider.activeCollections.isEmpty)
                _buildEmpty()
              else
                _buildGrid(context, provider, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, CollectionProvider provider, bool isMobile) {
    final collections = provider.activeCollections.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.85 : 0.9,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final col = collections[index];
        return _CollectionCard(
          name: col.name,
          imageUrl: col.imageUrl,
          onTap: () => context.go('/collections/${col.id}'),
        );
      },
    );
  }

  Widget _buildSkeletonGrid(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.85 : 0.9,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const LoadingSkeleton.card(height: 250),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(Icons.collections_rounded,
            size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          'Chưa có bộ sưu tập nào',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
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
          duration: AppTheme.animNormal,
          curve: AppTheme.animCurve,
          transform: Matrix4.diagonal3Values(_isHovered ? 1.03 : 1.0, _isHovered ? 1.03 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: _isHovered ? AppTheme.shadowMedium : AppTheme.shadowSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with zoom on hover
                AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: AppTheme.animSlow,
                  curve: AppTheme.animCurve,
                  child: widget.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          errorWidget: (_, __, ___) => _placeholderBg(),
                        )
                      : _placeholderBg(),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Name
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    widget.name,
                    style: AppTextStyles.h5.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_florist, color: Colors.white, size: 48),
      ),
    );
  }
}

/// Reusable section header with title + subtitle.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxTextWidth),
          child: Text(
            subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
