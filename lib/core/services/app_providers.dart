import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../models/order_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Provider for products data.
class ProductProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = true;

  List<ProductModel> get products => _products;
  List<ProductModel> get activeProducts => _products.where((p) => p.isActive).toList();
  List<ProductModel> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;

  ProductProvider() {
    _init();
  }

  void _init() {
    _service.streamProducts(activeOnly: false).listen((data) {
      _products = data;
      _isLoading = false;
      notifyListeners();
    });
    _service.streamFeaturedProducts().listen((data) {
      _featuredProducts = data;
      notifyListeners();
    });
  }

  Future<ProductModel?> getProduct(String id) async {
    return _service.getProduct(id);
  }

  Future<void> addProduct(ProductModel product) async {
    await _service.addProduct(product);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _service.updateProduct(id, data);
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }
}

/// Provider for collections data.
class CollectionProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<CollectionModel> _collections = [];
  bool _isLoading = true;

  List<CollectionModel> get collections => _collections;
  List<CollectionModel> get activeCollections => _collections.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;

  CollectionProvider() {
    _service.streamCollections(activeOnly: false).listen((data) {
      _collections = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<CollectionModel?> getCollection(String id) async {
    return _service.getCollection(id);
  }

  Future<void> addCollection(CollectionModel collection) async {
    await _service.addCollection(collection);
  }

  Future<void> updateCollection(String id, Map<String, dynamic> data) async {
    await _service.updateCollection(id, data);
  }

  Future<void> deleteCollection(String id) async {
    await _service.deleteCollection(id);
  }
}

/// Provider for orders data.
class OrderProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  List<OrderModel> _orders = [];
  List<OrderModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  OrderItem? _checkoutItem;
  String? _checkoutNote;

  OrderItem? get checkoutItem => _checkoutItem;
  String? get checkoutNote => _checkoutNote;

  void setCheckoutDetails(OrderItem item, String note) {
    _checkoutItem = item;
    _checkoutNote = note;
    notifyListeners();
  }

  OrderProvider() {
    _service.streamOrders().listen((data) {
      _orders = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  void searchByPhone(String phone) {
    _isSearching = true;
    notifyListeners();
    _ordersSubscription?.cancel();
    _ordersSubscription = _service.streamOrdersByPhone(phone).listen((data) {
      _searchResults = data;
      _isSearching = false;
      notifyListeners();
    }, onError: (error) {
      _isSearching = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> createOrder(OrderModel order) async {
    await _service.createOrder(order);
  }

  Future<void> updateStatus(String id, OrderStatus status) async {
    // Attempt to find order before updating status in db, or construct message based on existing fields
    OrderModel? order;
    try {
      order = _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      // Order not in local list, wait for update or fetch it directly
    }

    await _service.updateOrderStatus(id, status);

    if (order != null && order.conversationId.isNotEmpty) {
      try {
        await NotificationService().sendNotificationToUser(
          conversationId: order.conversationId,
          title: 'Cập nhật trạng thái đơn hàng',
          body: 'Đơn hàng #${order.id} của bạn đã được cập nhật sang: ${status.displayName}',
        );
        final notif = NotificationModel(
          id: '',
          conversationId: order.conversationId,
          title: 'Cập nhật trạng thái đơn hàng',
          body: 'Đơn hàng #${order.id} của bạn đã được cập nhật sang: ${status.displayName}',
          type: NotificationType.orderUpdate,
          createdAt: DateTime.now(),
          orderId: order.id,
        );
        await _service.createNotification(notif);
      } catch (e) {
        // Suppress debug print in production
      }
    }
  }

  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _orders.where((o) => o.createdAt.isAfter(startOfDay)).toList();
  }

  double get totalRevenue {
    return _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }
}

/// Provider for admin authentication.
class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  bool _isLoading = false;

  fb.User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      notifyListeners();
      if (user != null) {
        try {
          final token = await FirebaseMessaging.instance.getToken(
            vapidKey: "BI3jocSRLjO06h8S_WUUy-DDsENyw5quSRC7YiS7E-UZ11DCtfaolzs-powxcvzR2d9l49AkaXt-GzDJqNDniuk",
          );
          if (token != null) {
            await NotificationService().saveAdminToken(user.uid, token);
          }
        } catch (e) {
          // Suppress debug print in production
        }
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}

/// Provider for realtime chat support.
class ChatProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final String _userConversationId;

  List<MessageModel> _messages = [];
  List<String> _adminConversations = [];
  Map<String, String> _conversationNames = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  List<String> get adminConversations => _adminConversations;
  Map<String, String> get conversationNames => _conversationNames;
  Map<String, int> get unreadCounts => _unreadCounts;
  bool get isLoading => _isLoading;

  /// Returns the persisted conversation ID.
  String get userConversationId => _userConversationId;

  ChatProvider(this._userConversationId) {
    // For admin chat list
    _service.streamConversationIds().listen((conversations) {
      _adminConversations = conversations;
      notifyListeners();
    });
    // Stream custom conversation names
    _service.streamConversationNames().listen((names) {
      _conversationNames = names;
      notifyListeners();
    });
    // Stream all unread messages to count unread messages per conversation
    _service.streamAllUnreadMessages().listen((messages) {
      final Map<String, int> counts = {};
      for (final msg in messages) {
        if (msg.senderId != 'admin') {
          counts[msg.conversationId] = (counts[msg.conversationId] ?? 0) + 1;
        }
      }
      _unreadCounts = counts;
      notifyListeners();
    });
  }

  void listenToMessages(String conversationId) {
    _isLoading = true;
    notifyListeners();
    _service.streamMessages(conversationId).listen((data) {
      _messages = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String conversationId) async {
    await _service.markMessagesAsRead(conversationId);
  }

  Future<void> sendMessage(String conversationId, String senderId, String messageText) async {
    if (messageText.trim().isEmpty) return;

    final msg = MessageModel(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      message: messageText,
      createdAt: DateTime.now(),
    );

    await _service.sendMessage(msg);

    if (senderId != 'admin') {
      try {
        await NotificationService().sendNotificationToAdmin(
          title: 'Tin nhắn hỗ trợ mới',
          body: messageText,
        );
      } catch (e) {
        // Suppress debug print in production
      }
    } else {
      try {
        await NotificationService().sendNotificationToUser(
          conversationId: conversationId,
          title: 'Tin nhắn mới từ cửa hàng',
          body: messageText,
        );
        final notif = NotificationModel(
          id: '',
          conversationId: conversationId,
          title: 'Tin nhắn mới từ cửa hàng',
          body: messageText,
          type: NotificationType.chat,
          createdAt: DateTime.now(),
        );
        await _service.createNotification(notif);
      } catch (e) {
        // Suppress debug print in production
      }
    }
  }

  Future<void> renameConversation(String conversationId, String newName) async {
    await _service.renameConversation(conversationId, newName);
  }

  Future<void> deleteConversation(String conversationId) async {
    await _service.deleteConversation(conversationId);
  }
}

/// Provider for managing user in-app notifications
class NotificationProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final String _conversationId;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  NotificationProvider(this._conversationId) {
    _init();
  }

  void _init() {
    _subscription = _service.streamNotifications(_conversationId).listen((data) {
      _notifications = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllNotificationsAsRead(_conversationId);
  }
}


