import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../models/order_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

/// Provider for products data.
class ProductProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = true;

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;

  ProductProvider() {
    _init();
  }

  void _init() {
    _service.streamProducts().listen((data) {
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
  bool get isLoading => _isLoading;

  CollectionProvider() {
    _service.streamCollections().listen((data) {
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
    _service.streamOrdersByPhone(phone).listen((data) {
      _searchResults = data;
      _isSearching = false;
      notifyListeners();
    });
  }

  Future<void> createOrder(OrderModel order) async {
    await _service.createOrder(order);
  }

  Future<void> updateStatus(String id, OrderStatus status) async {
    await _service.updateOrderStatus(id, status);
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
    _auth.authStateChanges().listen((user) {
      notifyListeners();
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
  final String _uuid = const Uuid().v4();

  String? _userConversationId;
  List<MessageModel> _messages = [];
  List<String> _adminConversations = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  List<String> get adminConversations => _adminConversations;
  bool get isLoading => _isLoading;

  /// Returns the current conversation ID (generates one if guest user doesn't have one).
  String get userConversationId {
    _userConversationId ??= 'chat_$_uuid';
    return _userConversationId!;
  }

  ChatProvider() {
    // For admin chat list
    _service.streamConversationIds().listen((conversations) {
      _adminConversations = conversations;
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
    });
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
  }
}

