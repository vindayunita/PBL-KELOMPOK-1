import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/user/data/user_repository.dart';
import 'notification_model.dart';

part 'notification_repository.g.dart';

@riverpod
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(ref.watch(firestoreProvider));

class NotificationRepository {
  NotificationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // ── Kirim notifikasi baru ─────────────────────────────────────────────────
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await _notifications.add({
      'recipientId': recipientId,
      'title':       title,
      'body':        body,
      'type':        type,
      'isRead':      false,
      'relatedId':   relatedId,
      'createdAt':   FieldValue.serverTimestamp(),
    });
  }

  // ── Stream notifikasi real-time milik user (belum dibaca & semua) ─────────
  Stream<List<NotificationModel>> watchNotifications(String userId, {bool isAdmin = false}) {
    print('watchNotifications called with userId: $userId, isAdmin: $isAdmin');
    return _notifications
        .where('recipientId', whereIn: [userId, if (isAdmin) 'ADMIN_ALL'])
        .snapshots()
        .map((snap) {
      print('watchNotifications received ${snap.docs.length} docs for userId: $userId, isAdmin: $isAdmin');
      final list = snap.docs.map(NotificationModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length > 50) return list.sublist(0, 50);
      return list;
    });
  }

  // ── Hitung notifikasi yang belum dibaca ───────────────────────────────────
  Stream<int> watchUnreadCount(String userId, {bool isAdmin = false}) {
    return _notifications
        .where('recipientId', whereIn: [userId, if (isAdmin) 'ADMIN_ALL'])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Tandai satu notifikasi sebagai sudah dibaca ───────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  // ── Tandai semua notifikasi user sebagai sudah dibaca ─────────────────────
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Simpan / update FCM token perangkat untuk user ini ───────────────────
  Future<void> saveFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  // ── Hapus FCM token saat user logout ─────────────────────────────────────
  Future<void> removeFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}
