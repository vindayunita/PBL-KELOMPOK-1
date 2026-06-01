import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'notification_repository.dart';

// ── Background Message Handler (harus top-level function) ────────────────────
/// Dipanggil oleh OS saat notifikasi masuk ketika aplikasi berada di background
/// atau sudah terminated (ditutup total). Harus top-level (di luar kelas).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase sudah di-init sebelumnya di main.dart, jadi tidak perlu init ulang.
  debugPrint(
    '[FCM Background] Notifikasi diterima: ${message.notification?.title}',
  );
}

// ── Notification Service ──────────────────────────────────────────────────────
/// Service singleton untuk mengelola seluruh siklus notifikasi FCM:
/// - Meminta izin ke pengguna
/// - Menyimpan dan memperbarui FCM Token di Firestore
/// - Menampilkan local notification (banner melayang) saat app di foreground
/// - Menangani klik notifikasi untuk navigasi
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Channel ID harus sama dengan yang ada di AndroidManifest.xml
  static const _channelId   = 'high_importance_channel';
  static const _channelName = 'EcoTrade Notifikasi';
  static const _channelDesc = 'Notifikasi penting dari EcoTrade';

  bool _isInitialized = false;

  /// Inisialisasi service. Panggil di main.dart setelah Firebase.initializeApp().
  Future<void> initialize({
    required NotificationRepository repository,
    required String? userId,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Inisialisasi flutter_local_notifications
    await _setupLocalNotifications(navigatorKey);

    // 3. Minta izin notifikasi ke pengguna (Android 13+, iOS)
    await _requestPermission();

    // 4. Setup foreground notification options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Ambil & simpan token ke Firestore jika user sudah login
    if (userId != null) {
      await _saveToken(repository, userId);
      // Pantau perubahan token (misal setelah reinstall)
      _messaging.onTokenRefresh.listen((newToken) {
        repository.saveFcmToken(userId, newToken);
      });
    }

    // 6. Handle pesan saat app di FOREGROUND → tampilkan local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 7. Handle klik notifikasi saat app di BACKGROUND (sudah berjalan)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data, navigatorKey);
    });

    // 8. Handle klik notifikasi saat app di TERMINATED (dibuka dari nol)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Tunda sebentar agar Navigator sudah siap
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data, navigatorKey);
      });
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert:         true,
      announcement:  false,
      badge:         true,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
      sound:         true,
    );
    debugPrint(
      '[FCM] Status izin notifikasi: ${settings.authorizationStatus}',
    );
  }

  Future<void> _saveToken(
    NotificationRepository repository,
    String userId,
  ) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token perangkat: $token');
        await repository.saveFcmToken(userId, token);
      }
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
    }
  }

  Future<void> _setupLocalNotifications(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    // Konfigurasi Android: ikon notifikasi menggunakan @mipmap/ic_launcher
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfigurasi Darwin (iOS/macOS)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission:  false, // kita minta sendiri via FirebaseMessaging
      requestBadgePermission:  false,
      requestSoundPermission:  false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS:     darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle klik local notification (saat app di foreground)
        if (response.payload != null) {
          // payload berisi "type|relatedId"
          final parts = response.payload!.split('|');
          final type      = parts.isNotEmpty ? parts[0] : 'general';
          final relatedId = parts.length > 1 ? parts[1] : '';
          _navigateFromNotification(
            navigatorKey,
            type: type,
            relatedId: relatedId,
          );
        }
      },
    );

    // Buat channel prioritas tinggi (Android 8.0+) untuk Heads-up notification
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description:        _channelDesc,
        importance:         Importance.max,
        playSound:          true,
        enableVibration:    true,
        showBadge:          true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type      = message.data['type']      ?? 'general';
    final relatedId = message.data['relatedId'] ?? '';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance:         Importance.max,
      priority:           Priority.high,
      showWhen:           true,
      enableVibration:    true,
      playSound:          true,
      icon:               '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS:     DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notifDetails,
      payload: '$type|$relatedId',
    );
  }

  /// Navigasi ke halaman yang sesuai berdasarkan tipe & relatedId notifikasi.
  void _handleNotificationTap(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final type      = data['type']      as String? ?? 'general';
    final relatedId = data['relatedId'] as String? ?? '';
    _navigateFromNotification(
      navigatorKey,
      type: type,
      relatedId: relatedId,
    );
  }

  void _navigateFromNotification(
    GlobalKey<NavigatorState> navigatorKey, {
    required String type,
    required String relatedId,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    debugPrint('[FCM] Navigasi dari notifikasi: type=$type, relatedId=$relatedId');

    // Navigasi ke halaman Notifikasi (inbox) via GoRouter.
    // Anda bisa memperluas logika ini untuk langsung ke detail order/retur.
    GoRouter.of(context).push('/notifications');
  }
}
