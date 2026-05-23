import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/orders/domain/order_model.dart';
import '../../../../features/orders/domain/order_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierRiwayatScreen extends ConsumerStatefulWidget {
  const CourierRiwayatScreen({super.key});

  @override
  ConsumerState<CourierRiwayatScreen> createState() => _CourierRiwayatScreenState();
}

class _CourierRiwayatScreenState extends ConsumerState<CourierRiwayatScreen> {
  int _filterIndex = 0; // 0=Semua, 1=Selesai, 2=Retur

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(myCourierTasksProvider);
    final historyReturnsAsync = ref.watch(myCourierHistoryReturnTasksProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1C1C1E),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoTrade',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat\nTugas',
                  style: tt.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rekapitulasi pengiriman dan status\npengembalian bahan baku organik.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter Pills ──────────────────────────────────────────
                _FilterPills(
                  selected: _filterIndex,
                  onSelect: (i) => setState(() => _filterIndex = i),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allTasks) {
                final historyReturns = historyReturnsAsync.value ?? [];
                // Riwayat menampilkan yang sudah delivered, completed, returnRequested, atau returnCompleted
                final historyTasksMap = <String, OrderModel>{};
                for (final t in allTasks) {
                  if (t.isDelivered || t.isCompleted || t.isReturnRequested || t.isReturnCompleted) {
                    historyTasksMap[t.orderId] = t;
                  }
                }
                for (final t in historyReturns) {
                  historyTasksMap[t.orderId] = t;
                }
                final historyTasks = historyTasksMap.values.toList()
                  ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
                
                // Apply filter
                List<OrderModel> filtered = [];
                if (_filterIndex == 1) { // Selesai
                  filtered = historyTasks.where((t) => t.isDelivered || t.isCompleted).toList();
                } else if (_filterIndex == 2) { // Retur
                  filtered = historyTasks.where((t) => t.isReturnRequested || t.isReturnCompleted).toList();
                } else {
                  filtered = historyTasks;
                }

                if (filtered.isEmpty) return _EmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    return _CardSelesai(task: filtered[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Pills
// ─────────────────────────────────────────────────────────────────────────────
class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _labels = ['Semua', 'Selesai', 'Retur'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: List.generate(_labels.length, (i) {
        final active = selected == i;
        return Padding(
          padding: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _labels[i],
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : cs.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge helper
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Color bg = const Color(0xFF16A34A);
    Color fg = Colors.white;
    String label = status == OrderStatus.delivered ? 'Selesai' : status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail helper
// ─────────────────────────────────────────────────────────────────────────────
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.icon, this.bgColor});
  final IconData icon;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white70, size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card: Selesai
// ─────────────────────────────────────────────────────────────────────────────
class _CardSelesai extends StatelessWidget {
  const _CardSelesai({required this.task});
  final OrderModel task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String dateStr = '';
    if (task.updatedAt != null) {
      dateStr = DateFormat('dd MMM yyyy • HH:mm').format(task.updatedAt!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID TUGAS ${task.orderId.substring(0, 8).toUpperCase()}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.productName.isNotEmpty ? task.productName : 'Produk',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 14),

          // Content row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Thumbnail(
                icon: Icons.inventory_2_outlined,
                bgColor: Color(0xFF1C1C1E),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telah diantar ke Buyer:',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.buyerName.isNotEmpty ? task.buyerName : 'Pembeli',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),
          const SizedBox(height: 10),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Berhasil Terkirim',
                style: tt.bodySmall?.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: navigate ke detail tugas
                },
                child: Row(
                  children: [
                    Text(
                      'Detail',
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: cs.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 52, color: cs.onSurface.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: tt.titleSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
