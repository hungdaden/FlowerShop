import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.navbarHeight + 40),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 64,
              vertical: 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                child: Column(
                  children: [
                    Text('Bộ sưu tập', style: AppTextStyles.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppTheme.maxTextWidth),
                      child: Text(
                        'Tìm kiếm những đóa hoa hoàn hảo cho mọi dịp kỷ niệm, ngày lễ hay lời nhắn gửi yêu thương.',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 64),
                    if (provider.isLoading)
                      _buildSkeletonGrid(isMobile)
                    else if (provider.collections.isEmpty)
                      _buildEmpty()
                    else
                      _buildGrid(context, provider, isMobile),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, CollectionProvider provider, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: isMobile ? 0.8 : 0.85,
      ),
      itemCount: provider.collections.length,
      itemBuilder: (context, index) {
        final col = provider.collections[index];
        return _CollectionCard(
          name: col.name,
          description: col.description,
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
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: isMobile ? 0.8 : 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const LoadingSkeleton.card(height: 300),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 64),
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
  final String description;
  final String imageUrl;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.name,
    required this.description,
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
          transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: _isHovered ? AppTheme.shadowMedium : AppTheme.shadowSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.06 : 1.0,
                  duration: AppTheme.animSlow,
                  curve: AppTheme.animCurve,
                  child: widget.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                          errorWidget: (_, __, ___) => _placeholderBg(),
                        )
                      : _placeholderBg(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
