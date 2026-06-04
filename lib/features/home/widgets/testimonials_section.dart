import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

/// Customer testimonials section.
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const _testimonials = [
    _Testimonial(
      name: 'Nguyễn Thị Mai',
      content: 'Hoa rất đẹp và tươi lâu. Dịch vụ giao hàng nhanh chóng, đúng hẹn. Rất hài lòng!',
      rating: 5,
    ),
    _Testimonial(
      name: 'Trần Văn Hùng',
      content: 'Đặt hoa sinh nhật cho vợ, cô ấy rất thích. Bó hoa được gói rất tinh tế và sang trọng.',
      rating: 5,
    ),
    _Testimonial(
      name: 'Lê Thị Hương',
      content: 'Đã đặt nhiều lần cho các sự kiện công ty. Chất lượng luôn đồng đều và dịch vụ tuyệt vời.',
      rating: 5,
    ),
  ];

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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            children: [
              Text('Khách hàng nói gì',
                  style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Niềm tin và sự hài lòng của khách hàng là động lực của chúng tôi',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              isMobile
                  ? Column(
                      children: _testimonials
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _TestimonialCard(testimonial: t),
                              ))
                          .toList(),
                    )
                  : Row(
                      children: _testimonials
                          .map((t) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: _TestimonialCard(testimonial: t),
                                ),
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Testimonial {
  final String name;
  final String content;
  final int rating;
  const _Testimonial(
      {required this.name, required this.content, required this.rating});
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      hoverScale: 1.01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(
              testimonial.rating,
              (_) => const Padding(
                padding: EdgeInsets.only(right: 2),
                child:
                    Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"${testimonial.content}"',
            style: AppTextStyles.body.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  testimonial.name[0],
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(testimonial.name, style: AppTextStyles.label),
            ],
          ),
        ],
      ),
    );
  }
}
