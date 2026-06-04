import 'package:flutter/material.dart';
import '../widgets/hero_section.dart';
import '../widgets/featured_collections_section.dart';
import '../widgets/featured_products_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/cta_section.dart';
import '../../../core/widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          HeroSection(),
          FeaturedCollectionsSection(),
          FeaturedProductsSection(),
          TestimonialsSection(),
          CTASection(),
          AppFooter(),
        ],
      ),
    );
  }
}
