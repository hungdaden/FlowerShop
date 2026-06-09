import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../models/order_model.dart';
import '../models/message_model.dart';

/// Firestore service — single point of access to Firebase data.
/// Pattern: UI → Provider → Service → Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Products ──────────────────────────────────────────────

  Stream<List<ProductModel>> streamProducts({bool activeOnly = true}) {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final products =
          snap.docs.map((d) => ProductModel.fromJson(d.data(), d.id)).toList();
      if (!activeOnly) return products;
      return products.where((product) => product.isActive).toList();
    });
  }

  Stream<List<ProductModel>> streamFeaturedProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromJson(d.data(), d.id))
            .where((product) => product.isActive && product.isFeatured)
            .take(8)
            .toList());
  }

  Stream<List<ProductModel>> streamProductsByCollection(String collectionId) {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromJson(d.data(), d.id))
            .where((product) =>
                product.isActive && product.collectionId == collectionId)
            .toList());
  }

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromJson(doc.data()!, doc.id);
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ─── Collections ──────────────────────────────────────────

  Stream<List<CollectionModel>> streamCollections({bool activeOnly = true}) {
    return _db
        .collection('collections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final collections = snap.docs
          .map((d) => CollectionModel.fromJson(d.data(), d.id))
          .toList();
      if (!activeOnly) return collections;
      return collections.where((collection) => collection.isActive).toList();
    });
  }

  Future<CollectionModel?> getCollection(String id) async {
    final doc = await _db.collection('collections').doc(id).get();
    if (!doc.exists) return null;
    return CollectionModel.fromJson(doc.data()!, doc.id);
  }

  Future<void> addCollection(CollectionModel collection) async {
    await _db.collection('collections').add(collection.toJson());
  }

  Future<void> updateCollection(String id, Map<String, dynamic> data) async {
    await _db.collection('collections').doc(id).update(data);
  }

  Future<void> deleteCollection(String id) async {
    await _db.collection('collections').doc(id).delete();
  }

  // ─── Orders ──────────────────────────────────────────────

  Stream<List<OrderModel>> streamOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromJson(d.data(), d.id)).toList());
  }

  Stream<List<OrderModel>> streamOrdersByPhone(String phone) {
    return _db
        .collection('orders')
        .where('phone', isEqualTo: phone)
        .limit(50)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => OrderModel.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sắp xếp mới nhất lên đầu
      return list;
    });
  }

  Stream<List<OrderModel>> streamTodayOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromJson(d.data(), d.id)).toList());
  }

  Future<void> createOrder(OrderModel order) async {
    await _db.collection('orders').add(order.toJson());
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await _db.collection('orders').doc(id).update({'status': status.name});
  }

  // ─── Messages ──────────────────────────────────────────────

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => MessageModel.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> sendMessage(MessageModel message) async {
    await _db.collection('messages').add(message.toJson());
  }

  /// Stream all unread messages in the database.
  Stream<List<MessageModel>> streamAllUnreadMessages() {
    return _db
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromJson(d.data(), d.id)).toList());
  }

  /// Mark all unread user messages in a conversation as read.
  Future<void> markMessagesAsRead(String conversationId) async {
    final snap = await _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.data()['senderId'] != 'admin') {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  /// Get list of unique conversation IDs (for admin).
  Stream<List<String>> streamConversationIds() {
    return _db
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final ids = <String>{};
      for (final doc in snap.docs) {
        ids.add(doc.data()['conversationId'] ?? '');
      }
      return ids.toList();
    });
  }

  /// Stream conversation custom names (for admin).
  Stream<Map<String, String>> streamConversationNames() {
    return _db.collection('conversation_metadata').snapshots().map((snap) {
      final Map<String, String> names = {};
      for (final doc in snap.docs) {
        names[doc.id] = doc.data()['customName'] ?? '';
      }
      return names;
    });
  }

  /// Set or update the custom name of a conversation.
  Future<void> renameConversation(String conversationId, String newName) async {
    await _db.collection('conversation_metadata').doc(conversationId).set({
      'customName': newName,
    }, SetOptions(merge: true));
  }

  /// Delete a conversation and all its messages.
  Future<void> deleteConversation(String conversationId) async {
    // Delete metadata
    await _db.collection('conversation_metadata').doc(conversationId).delete();

    // Delete all messages belonging to this conversation
    final messagesSnap = await _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .get();

    final batch = _db.batch();
    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Dashboard Stats ──────────────────────────────────────

  Future<int> getProductCount() async {
    final snap = await _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getOrderCount() async {
    final snap = await _db.collection('orders').count().get();
    return snap.count ?? 0;
  }
}
