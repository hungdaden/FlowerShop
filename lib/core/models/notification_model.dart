import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  chat,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Cập nhật đơn hàng';
      case NotificationType.chat:
        return 'Tin nhắn';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  static NotificationType fromString(String val) {
    return NotificationType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationModel {
  final String id;
  final String conversationId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;

  NotificationModel({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String docId) {
    DateTime createdDate;
    if (json['createdAt'] is Timestamp) {
      createdDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return NotificationModel(
      id: docId,
      conversationId: json['conversationId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'system'),
      isRead: json['isRead'] ?? false,
      createdAt: createdDate,
      orderId: json['orderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (orderId != null) 'orderId': orderId,
    };
  }
}
