import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_providers.dart';

/// Widget ikon lonceng dengan badge angka merah untuk notifikasi yang belum dibaca.
/// Dapat diletakkan di AppBar actions atau NavigationBar setiap dashboard.
///
/// Contoh penggunaan di AppBar:
/// ```dart
/// appBar: AppBar(
///   actions: [
///     const NotificationBadge(),
///   ],
/// ),
/// ```
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: () => context.push('/notifications'),
      icon: unreadCountAsync.when(
        loading: () => const Icon(Icons.notifications_outlined),
        error: (_, __) => const Icon(Icons.notifications_outlined),
        data: (count) => Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
