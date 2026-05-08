import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one item inside a buyer's cart.
/// Stored at: carts/{userId}/items/{itemId}
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice, // original price per kg
    required this.unit,
    required this.purchaseType, // 'standard' | 'sample'
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    this.addedAt,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double productPrice;
  final String unit;
  final String purchaseType;
  final int quantity;
  final String sellerId;
  final String sellerName;
  final DateTime? addedAt;

  // Effective price depending on purchase type
  double get effectiveUnitPrice =>
      purchaseType == 'sample' ? productPrice * 0.30 : productPrice;

  // Display quantity label (both types use product unit)
  String get quantityLabel => '$quantity $unit';

  double get subtotal => effectiveUnitPrice * quantity;

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CartItemModel(
      id: doc.id,
      productId: d['productId'] as String? ?? '',
      productTitle: d['productTitle'] as String? ?? '',
      productImageUrl: d['productImageUrl'] as String? ?? '',
      productPrice: (d['productPrice'] as num?)?.toDouble() ?? 0,
      unit: d['unit'] as String? ?? 'kg',
      purchaseType: d['purchaseType'] as String? ?? 'standard',
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? '',
      addedAt: (d['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'productPrice': productPrice,
        'unit': unit,
        'purchaseType': purchaseType,
        'quantity': quantity,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'addedAt': FieldValue.serverTimestamp(),
      };

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        id: id,
        productId: productId,
        productTitle: productTitle,
        productImageUrl: productImageUrl,
        productPrice: productPrice,
        unit: unit,
        purchaseType: purchaseType,
        quantity: quantity ?? this.quantity,
        sellerId: sellerId,
        sellerName: sellerName,
        addedAt: addedAt,
      );
}
