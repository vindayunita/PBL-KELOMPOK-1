import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/auth_providers.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

part 'notification_providers.g.dart';

// ── Stream semua notifikasi milik user saat ini ───────────────────────────────
@riverpod
Stream<List<NotificationModel>> notificationStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(user.uid);
}

// ── Jumlah notifikasi yang belum dibaca (untuk badge) ────────────────────────
@riverpod
Stream<int> unreadNotificationCount(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref
      .watch(notificationRepositoryProvider)
      .watchUnreadCount(user.uid);
}
