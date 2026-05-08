/// Lightweight item snapshot stored inside an order document.
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.purchaseType,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.sellerId,
    required this.sellerName,
  });

  final String productId;
  final String productTitle;
  final String productImageUrl;
  final String purchaseType; // 'standard' | 'sample'
  final double unitPrice;    // effective price (after 30% for sample)
  final int quantity;
  final String unit;
  final String sellerId;
  final String sellerName;

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'purchaseType': purchaseType,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'unit': unit,
        'sellerId': sellerId,
        'sellerName': sellerName,
      };
}
