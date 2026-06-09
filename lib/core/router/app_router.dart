import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/products/pages/product_detail_page.dart';
import '../../features/collections/pages/collections_page.dart';
import '../../features/collections/pages/collection_detail_page.dart';
import '../../features/orders/pages/order_page.dart';
import '../../features/orders/pages/order_tracking_page.dart';
import '../../features/chat/pages/chat_page.dart';
import '../../features/auth/pages/admin_login_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/dashboard/pages/admin_products_page.dart';
import '../../features/dashboard/pages/admin_collections_page.dart';
import '../../features/dashboard/pages/admin_orders_page.dart';
import '../../features/dashboard/pages/admin_chat_page.dart';
import '../widgets/app_scaffold.dart';

/// Custom fade+scale page transition (replaces default Material transition).
CustomTransitionPage<void> _buildPageTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

bool get isAdminSubdomain {
  if (kIsWeb) {
    final host = Uri.base.host;
    return host.startsWith('admin.') || 
           host.startsWith('admin-') || 
           host.startsWith('adminflower');
  }
  return false;
}

final GoRouter appRouter = GoRouter(
  initialLocation: isAdminSubdomain ? '/admin' : '/',
  redirect: (context, state) {
    final path = state.uri.path;
    final isSub = isAdminSubdomain;

    if (isSub) {
      // Trên subdomain admin, tất cả đường dẫn không phải /admin/* đều chuyển về /admin
      if (!path.startsWith('/admin')) {
        return '/admin';
      }
    } else {
      // Trên domain chính (user), không cho phép truy cập đường dẫn quản trị
      if (path.startsWith('/admin')) {
        return '/';
      }
    }
    return null;
  },
  routes: [
    // ─── User Routes ──────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(
          currentPath: state.uri.path,
          body: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/collections',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const CollectionsPage(),
          ),
        ),
        GoRoute(
          path: '/collections/:id',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: CollectionDetailPage(
              collectionId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const ProductsPage(),
          ),
        ),
        GoRoute(
          path: '/products/:id',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: ProductDetailPage(
              productId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/order',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const OrderPage(),
          ),
        ),
        GoRoute(
          path: '/order-tracking',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const OrderTrackingPage(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => _buildPageTransition(
            state: state,
            child: const ChatPage(),
          ),
        ),
      ],
    ),

    // ─── Admin Routes ──────────────────────────
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const AdminLoginPage(),
      ),
    ),
    GoRoute(
      path: '/admin/dashboard',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const DashboardPage(),
      ),
    ),
    GoRoute(
      path: '/admin/products',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const AdminProductsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/collections',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const AdminCollectionsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/orders',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const AdminOrdersPage(),
      ),
    ),
    GoRoute(
      path: '/admin/chat',
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const AdminChatPage(),
      ),
    ),
  ],
);
