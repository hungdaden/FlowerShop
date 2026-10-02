import 'package:flutter/material.dart' show Widget;
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

NoTransitionPage<void> _noTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return NoTransitionPage(
    key: state.pageKey,
    child: child,
  );
}

bool get isAdminSubdomain {
  if (kIsWeb) {
    final host = Uri.base.host.toLowerCase();
    return host.startsWith('admin') || host.contains('.admin');
  }
  return false;
}

final GoRouter appRouter = GoRouter(
  initialLocation: isAdminSubdomain ? '/admin' : '/',
  redirect: (context, state) {
    final path = state.uri.path;
    
    // Nếu đang chạy ở môi trường local (localhost hoặc 127.0.0.1), cho phép truy cập trực tiếp cả 2 giao diện
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.')) {
        return null; // Bỏ qua bộ lọc chuyển hướng ở local
      }
    }

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
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/collections',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const CollectionsPage(),
          ),
        ),
        GoRoute(
          path: '/collections/:id',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: CollectionDetailPage(
              collectionId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const ProductsPage(),
          ),
        ),
        GoRoute(
          path: '/products/:id',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: ProductDetailPage(
              productId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/order',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const OrderPage(),
          ),
        ),
        GoRoute(
          path: '/order-tracking',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const OrderTrackingPage(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => _noTransition(
            state: state,
            child: const ChatPage(),
          ),
        ),
      ],
    ),

    // ─── Admin Routes ──────────────────────────
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const AdminLoginPage(),
      ),
    ),
    GoRoute(
      path: '/admin/dashboard',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const DashboardPage(),
      ),
    ),
    GoRoute(
      path: '/admin/products',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const AdminProductsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/collections',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const AdminCollectionsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/orders',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const AdminOrdersPage(),
      ),
    ),
    GoRoute(
      path: '/admin/chat',
      pageBuilder: (context, state) => _noTransition(
        state: state,
        child: const AdminChatPage(),
      ),
    ),
  ],
);
