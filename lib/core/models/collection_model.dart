import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  CollectionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CollectionModel.fromJson(Map<String, dynamic> json, String docId) {
    return CollectionModel(
      id: docId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CollectionModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return CollectionModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
