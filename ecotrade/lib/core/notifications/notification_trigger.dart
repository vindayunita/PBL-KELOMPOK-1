import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper statis untuk menulis dokumen notifikasi ke Firestore.
///
/// Cloud Function `sendPushNotification` akan otomatis terpicu setiap kali
/// sebuah dokumen baru dibuat di koleksi `notifications`.
///
/// Semua method di sini adalah fire-and-forget (tidak menunggu response)
/// agar tidak memblokir alur utama bisnis.
abstract class NotificationTrigger {
  static final _db = FirebaseFirestore.instance;

  // ── Buyer ──────────────────────────────────────────────────────────────────

  /// Notifikasi ke Buyer: order baru diterima dan sedang diproses.
  static Future<void> orderProcessing({
    required String buyerId,
    required String orderId,
    required String productTitle,
  }) => _send(
        recipientId: buyerId,
        title: '📦 Pesananmu Diproses!',
        body: 'Penjual mulai memproses pesanan "$productTitle". '
            'Estimasi pengiriman dalam 1-2 hari.',
        type: 'order_processing',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: kurir sudah ditugaskan.
  static Future<void> courierAssigned({
    required String buyerId,
    required String orderId,
    required String courierName,
  }) => _send(
        recipientId: buyerId,
        title: '🚚 Kurir Ditugaskan!',
        body: '$courierName akan segera menjemput pesananmu '
            'dari penjual.',
        type: 'courier_assigned',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: pesanan sedang dalam perjalanan.
  static Future<void> orderPickedUp({
    required String buyerId,
    required String orderId,
    required String courierName,
  }) => _send(
        recipientId: buyerId,
        title: '🛵 Pesanan Dalam Perjalanan!',
        body: '$courierName sedang mengantar pesananmu. '
            'Harap siapkan diri untuk menerimanya.',
        type: 'order_picked_up',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: pesanan sudah terkirim.
  static Future<void> orderDelivered({
    required String buyerId,
    required String orderId,
  }) => _send(
        recipientId: buyerId,
        title: '✅ Pesanan Tiba!',
        body: 'Pesananmu sudah sampai. '
            'Konfirmasi penerimaan di halaman Pesanan.',
        type: 'order_delivered',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: retur diterima oleh seller.
  static Future<void> returnApproved({
    required String buyerId,
    required String orderId,
  }) => _send(
        recipientId: buyerId,
        title: '✅ Retur Disetujui',
        body: 'Penjual menyetujui retur pesananmu. '
            'Kurir akan segera menjemput barang.',
        type: 'return_approved',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: retur ditolak oleh seller.
  static Future<void> returnRejected({
    required String buyerId,
    required String orderId,
    required String reason,
  }) => _send(
        recipientId: buyerId,
        title: '❌ Retur Ditolak',
        body: 'Penjual menolak retur: "$reason".',
        type: 'return_rejected',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: pembayaran diverifikasi admin, order mulai diproses.
  static Future<void> paymentVerified({
    required String buyerId,
    required String orderId,
    required String productTitle,
  }) => _send(
        recipientId: buyerId,
        title: '✅ Pembayaran Dikonfirmasi!',
        body: 'Pembayaranmu untuk "$productTitle" sudah diverifikasi. '
            'Penjual akan segera memproses pesananmu.',
        type: 'payment_verified',
        referenceId: orderId,
      );

  /// Notifikasi ke Buyer: pembayaran ditolak admin.
  static Future<void> paymentRejected({
    required String buyerId,
    required String orderId,
    required String reason,
  }) => _send(
        recipientId: buyerId,
        title: '❌ Pembayaran Ditolak',
        body: 'Pembayaranmu tidak dapat diverifikasi: "$reason". '
            'Silakan hubungi admin untuk informasi lebih lanjut.',
        type: 'payment_rejected',
        referenceId: orderId,
      );

  // ── Seller ─────────────────────────────────────────────────────────────────

  /// Notifikasi ke Seller: ada order masuk baru (setelah admin verifikasi).
  static Future<void> newOrderForSeller({
    required String sellerId,
    required String orderId,
    required String productTitle,
    required String buyerName,
  }) => _send(
        recipientId: sellerId,
        title: '🛒 Pesanan Baru Masuk!',
        body: '$buyerName memesan "$productTitle". '
            'Segera konfirmasi dan proses.',
        type: 'new_order',
        referenceId: orderId,
      );

  /// Notifikasi ke Seller: ada permintaan retur dari buyer.
  static Future<void> returnRequested({
    required String sellerId,
    required String orderId,
    required String productTitle,
    required String buyerName,
  }) => _send(
        recipientId: sellerId,
        title: '⚠️ Permintaan Retur Baru',
        body: '$buyerName mengajukan retur untuk "$productTitle". '
            'Silakan cek detail dan berikan keputusan.',
        type: 'return_requested',
        referenceId: orderId,
      );

  /// Notifikasi ke Seller: retur selesai, barang sudah kembali.
  static Future<void> returnCompleted({
    required String sellerId,
    required String orderId,
  }) => _send(
        recipientId: sellerId,
        title: '📦 Retur Selesai',
        body: 'Barang retur sudah dikembalikan oleh kurir.',
        type: 'return_completed',
        referenceId: orderId,
      );

  // ── Kurir ──────────────────────────────────────────────────────────────────

  /// Notifikasi ke Kurir: ada tugas pengantaran baru.
  static Future<void> courierTaskAssigned({
    required String courierId,
    required String orderId,
    required String sellerCity,
    required String buyerAddress,
  }) => _send(
        recipientId: courierId,
        title: '📋 Tugas Pengantaran Baru!',
        body: 'Jemput dari $sellerCity → antar ke $buyerAddress. '
            'Buka tab Tugas untuk detail.',
        type: 'courier_task',
        referenceId: orderId,
      );

  /// Notifikasi ke Kurir: ada tugas retur baru.
  static Future<void> returnTaskAssigned({
    required String courierId,
    required String orderId,
    required String buyerAddress,
  }) => _send(
        recipientId: courierId,
        title: '🔄 Tugas Retur Baru!',
        body: 'Jemput barang retur dari $buyerAddress. '
            'Buka tab Tugas → Retur untuk detail.',
        type: 'courier_return_task',
        referenceId: orderId,
      );

  // ── Saldo & Penarikan (Refund / Payout) ────────────────────────────────────

  /// Notifikasi ke Buyer: Dana refund telah ditambahkan ke saldo.
  static Future<void> refundBalanceAdded({
    required String buyerId,
    required double amount,
  }) {
    // Format nominal ke ribuan, misal Rp 50.000 (secara sederhana)
    final amtStr = 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (m) => '.')}';
    return _send(
      recipientId: buyerId,
      title: '💰 Dana Refund Masuk!',
      body: 'Dana refund sebesar $amtStr telah ditambahkan ke Saldo Refund Anda.',
      type: 'refund_balance_added',
      referenceId: buyerId,
    );
  }

  /// Notifikasi ke User (Buyer/Seller): Penarikan dana berhasil diproses admin.
  static Future<void> payoutApproved({
    required String userId,
    required double amount,
    required String bankName,
  }) {
    final amtStr = 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (m) => '.')}';
    return _send(
      recipientId: userId,
      title: '💸 Penarikan Berhasil',
      body: 'Penarikan dana Anda sebesar $amtStr ke rekening $bankName telah berhasil diproses oleh Admin.',
      type: 'payout_approved',
      referenceId: userId,
    );
  }

  /// Notifikasi ke User (Buyer/Seller): Penarikan dana ditolak admin.
  static Future<void> payoutRejected({
    required String userId,
    required double amount,
    required String reason,
  }) {
    final amtStr = 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (m) => '.')}';
    return _send(
      recipientId: userId,
      title: '❌ Penarikan Ditolak',
      body: 'Permintaan penarikan dana sebesar $amtStr ditolak: "$reason". Saldo Anda telah dikembalikan.',
      type: 'payout_rejected',
      referenceId: userId,
    );
  }

  // ── Admin (Multicast Push via ADMIN_ALL) ───────────────────────────────────

  static Future<void> adminNewCourierApplication(String uid, String name) {
    return _send(
      recipientId: 'ADMIN_ALL',
      title: 'Pendaftaran Kurir Baru',
      body: 'Kurir baru ($name) mendaftar dan menunggu verifikasi Anda.',
      type: 'admin_verify_courier',
      referenceId: uid,
    );
  }

  static Future<void> adminNewSellerApplication(String uid, String name) {
    return _send(
      recipientId: 'ADMIN_ALL',
      title: 'Pendaftaran Seller Baru',
      body: 'Seller baru ($name) mendaftar dan menunggu verifikasi Anda.',
      type: 'admin_verify_seller',
      referenceId: uid,
    );
  }

  static Future<void> adminNewPaymentVerification(String orderId) {
    return _send(
      recipientId: 'ADMIN_ALL',
      title: 'Verifikasi Pembayaran Baru',
      body: 'Pesanan baru ($orderId) telah dibayar. Silakan cek bukti transfer.',
      type: 'admin_verify_payment',
      referenceId: orderId,
    );
  }

  static Future<void> adminNewRefundRequest(String payoutId) {
    return _send(
      recipientId: 'ADMIN_ALL',
      title: 'Permintaan Pencairan Refund',
      body: 'Ada permintaan pencairan dana refund baru dari Buyer.',
      type: 'admin_payout_refund',
      referenceId: payoutId,
    );
  }

  static Future<void> adminNewPayoutRequest(String payoutId) {
    return _send(
      recipientId: 'ADMIN_ALL',
      title: 'Permintaan Pencairan Pendapatan',
      body: 'Ada permintaan pencairan pendapatan baru dari Seller.',
      type: 'admin_payout_seller',
      referenceId: payoutId,
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _send({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    required String referenceId,
  }) async {
    if (recipientId.isEmpty) return;
    try {
      await _db.collection('notifications').add({
        'recipientId': recipientId,
        'title':       title,
        'body':        body,
        'type':        type,
        'referenceId': referenceId,
        'isRead':      false,
        'createdAt':   FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Notifikasi bersifat opsional — jangan sampai merusak alur utama
      // ignore: avoid_print
      print('[NotificationTrigger] Gagal kirim notifikasi: $e');
    }
  }
}
