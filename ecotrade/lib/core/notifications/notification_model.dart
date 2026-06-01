import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk satu dokumen notifikasi di koleksi /notifications Firestore.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  final String id;
  final String recipientId;
  final String title;
  final String body;

  /// Tipe notifikasi untuk menentukan ikon & aksi navigasi:
  /// - `order_new`        : Ada pesanan baru masuk (untuk Seller)
  /// - `order_confirmed`  : Pesanan dikonfirmasi oleh Seller (untuk Buyer)
  /// - `order_rejected`   : Pesanan ditolak oleh Seller (untuk Buyer)
  /// - `order_assigned`   : Kurir ditugaskan (untuk Buyer & Kurir)
  /// - `order_picked_up`  : Kurir sudah ambil barang (untuk Buyer)
  /// - `order_delivered`  : Pesanan selesai diantar (untuk Buyer)
  /// - `return_requested` : Buyer mengajukan retur (untuk Seller)
  /// - `return_approved`  : Retur disetujui (untuk Buyer & Kurir)
  /// - `return_picked_up` : Kurir sudah ambil retur (untuk Seller)
  /// - `return_completed` : Retur selesai, refund cair (untuk Buyer)
  /// - `payout_requested` : Seller mengajukan payout (untuk Admin)
  /// - `payout_processed` : Payout disetujui (untuk Seller)
  /// - `general`          : Notifikasi umum
  final String type;

  final bool isRead;
  final DateTime createdAt;

  /// ID entitas terkait (misal: orderId) untuk navigasi ke halaman detail.
  final String? relatedId;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id:          doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      title:       data['title']       as String? ?? '',
      body:        data['body']        as String? ?? '',
      type:        data['type']        as String? ?? 'general',
      isRead:      data['isRead']      as bool?   ?? false,
      relatedId:   data['relatedId']   as String?,
      createdAt:   (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'recipientId': recipientId,
    'title':       title,
    'body':        body,
    'type':        type,
    'isRead':      isRead,
    'relatedId':   relatedId,
    'createdAt':   FieldValue.serverTimestamp(),
  };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id:          id,
    recipientId: recipientId,
    title:       title,
    body:        body,
    type:        type,
    isRead:      isRead ?? this.isRead,
    createdAt:   createdAt,
    relatedId:   relatedId,
  );
}
