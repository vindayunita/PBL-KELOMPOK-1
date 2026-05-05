import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.commodityType,
    required this.price,
    required this.unit,
    required this.stock,
    required this.badge,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String commodityType;
  final double price;
  final String unit;
  final int stock;
  final String badge;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String status; // 'active' | 'inactive'
  final DateTime? createdAt;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      commodityType: data['commodityType'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'kg',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      badge: data['badge'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'commodityType': commodityType,
        'price': price,
        'unit': unit,
        'stock': stock,
        'badge': badge,
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };

  ProductModel copyWith({
    String? title,
    String? description,
    String? commodityType,
    double? price,
    String? unit,
    int? stock,
    String? badge,
    String? imageUrl,
    String? status,
  }) {
    return ProductModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      commodityType: commodityType ?? this.commodityType,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      badge: badge ?? this.badge,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId,
      sellerName: sellerName,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
