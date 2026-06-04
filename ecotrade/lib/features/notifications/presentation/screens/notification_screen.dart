import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/notification_model.dart';
import '../../../../core/notifications/notification_providers.dart';
import '../../../../core/notifications/notification_repository.dart';
import '../../../../features/auth/domain/auth_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Tombol "Tandai Semua Dibaca"
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _markAllAsRead(ref),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Semua Dibaca'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Gagal memuat notifikasi\n$e',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyState(theme);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () => _onNotificationTap(context, ref, notif),
                );
              },
            );
          },
        ),
      ),
    );

  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Notifikasi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua aktivitas pesanan, retur, dan\npembayaran akan muncul di sini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(notificationRepositoryProvider);
    // Tandai notifikasi personal sebagai dibaca
    await repo.markAllAsRead(user.uid);
    // Jika admin, tandai juga notifikasi ADMIN_ALL sebagai dibaca
    await repo.markAllAsRead('ADMIN_ALL');
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) async {
    // Tandai sebagai sudah dibaca
    if (!notif.isRead) {
      await ref
          .read(notificationRepositoryProvider)
          .markAsRead(notif.id);
    }
    // TODO: Tambahkan navigasi ke detail order/retur berdasarkan notif.type & notif.relatedId
  }
}

// ── Tile Widget ───────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isUnread
            ? theme.colorScheme.primaryContainer.withAlpha(60)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon berdasarkan tipe notifikasi
            _NotifIcon(type: notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari yang lalu';
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(date);
  }
}

// ── Notification Icon ─────────────────────────────────────────────────────────
class _NotifIcon extends StatelessWidget {
  const _NotifIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconData(type);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  (IconData, Color) _getIconData(String type) {
    switch (type) {
      // ── Buyer ──────────────────────────────────────────────────────────────
      case 'payment_verified':
        return (Icons.account_balance_wallet_rounded, Colors.green);
      case 'payment_rejected':
        return (Icons.money_off_rounded, Colors.red);
      case 'order_new':
      case 'order_processing':
        return (Icons.inventory_2_outlined, Colors.teal);
      case 'courier_assigned':
        return (Icons.local_shipping_outlined, Colors.orange);
      case 'order_picked_up':
        return (Icons.directions_bike_outlined, Colors.blue);
      case 'order_delivered':
        return (Icons.verified_outlined, Colors.green);
      case 'return_approved':
        return (Icons.approval_outlined, Colors.blue);
      case 'return_rejected':
        return (Icons.cancel_outlined, Colors.red);
      case 'refund_balance_added':
        return (Icons.account_balance_wallet_rounded, Colors.teal);
      case 'payout_approved':
        return (Icons.check_circle_outline_rounded, Colors.green);
      case 'payout_rejected':
        return (Icons.highlight_off_rounded, Colors.red);
      // ── Seller ─────────────────────────────────────────────────────────────
      case 'new_order':
        return (Icons.shopping_bag_outlined, Colors.blue);
      case 'return_requested':
        return (Icons.warning_amber_rounded, Colors.deepOrange);
      case 'return_completed':
        return (Icons.price_check_rounded, Colors.green);
      // ── Kurir ──────────────────────────────────────────────────────────────
      case 'courier_task':
        return (Icons.assignment_outlined, Colors.orange);
      case 'courier_return_task':
        return (Icons.assignment_return_outlined, Colors.deepOrange);
      // ── Admin ──────────────────────────────────────────────────────────────
      case 'admin_verify_payment':
        return (Icons.receipt_long_outlined, Colors.indigo);
      case 'admin_verify_seller':
        return (Icons.store_outlined, Colors.purple);
      case 'admin_verify_courier':
        return (Icons.delivery_dining_outlined, Colors.deepOrange);
      case 'admin_payout_seller':
        return (Icons.account_balance_outlined, Colors.green);
      case 'admin_payout_refund':
        return (Icons.currency_exchange_rounded, Colors.teal);
      // ── Fallback ───────────────────────────────────────────────────────────
      default:
        return (Icons.notifications_outlined, Colors.blueGrey);
    }
  }
}
