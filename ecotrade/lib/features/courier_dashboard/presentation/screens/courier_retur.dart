import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/orders/data/order_repository.dart';
import '../../../../features/orders/domain/order_model.dart';
import '../../../../features/orders/domain/order_providers.dart';
import 'courier_konfir_retur.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen (standalone — dengan AppBar)
// ─────────────────────────────────────────────────────────────────────────────
class CourierReturScreen extends ConsumerStatefulWidget {
  const CourierReturScreen({super.key});

  @override
  ConsumerState<CourierReturScreen> createState() => _CourierReturScreenState();
}

class _CourierReturScreenState extends ConsumerState<CourierReturScreen> {
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem(
      title: 'Paket sudah dikemas dengan baik',
      subtitle: 'Pastikan kemasan rapi dan aman untuk dibawa.',
    ),
    _ChecklistItem(
      title: 'Kondisi paket tidak sobek, bocor, atau rusak parah',
      subtitle: 'Periksa fisik paket secara menyeluruh.',
    ),
    _ChecklistItem(
      title: 'Jumlah paket sesuai',
      subtitle: 'Cocokkan jumlah paket dengan data retur.',
    ),
    _ChecklistItem(
      title: 'Ukuran dan berat paket masih sesuai dengan pengiriman',
      subtitle: 'Pastikan dimensi dan berat tidak berubah signifikan.',
    ),
    _ChecklistItem(
      title: 'Foto bukti pickup diambil',
      subtitle: 'Dokumentasikan kondisi paket sebelum dibawa.',
    ),
  ];

  bool get _allChecked => _checklist.every((e) => e.checked);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(myCourierReturnTasksProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: cs.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer,
                  ),
                  child:
                      Icon(Icons.person_rounded, color: cs.primary, size: 22),
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
              ],
            ),
            actions: [
              IconButton(
                icon:
                    Icon(Icons.notifications_outlined, color: cs.onSurface),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: tasksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('Error: $e'),
              )),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyContent(cs, tt);
                }
                // Tampilkan tugas retur pertama (satu per satu)
                final task = tasks.first;
                return _buildTaskContent(context, cs, tt, task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Manajemen\nRetur',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada tugas retur yang ditugaskan.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            label: 'DETAIL BARANG',
            child: _EmptyCardContent(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada barang retur',
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            label: 'RUTE PENJEMPUTAN',
            child: _EmptyCardContent(
              icon: Icons.route_rounded,
              message: 'Belum ada rute',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, ColorScheme cs, TextTheme tt, OrderModel task) {
    final isAssigned  = task.status == OrderStatus.returnAssigned;
    final isPickedUp  = task.status == OrderStatus.returnPickedUp;
    final statusLabel = isPickedUp
        ? 'SEDANG DIANTAR KE SELLER'
        : isAssigned
            ? 'MENUNGGU KONFIRMASI KAMU'
            : 'MENUNGGU PENJEMPUTAN';
    final statusColor = isPickedUp
        ? const Color(0xFFF59E0B)
        : isAssigned
            ? const Color(0xFF4A90E2)
            : const Color(0xFF3B82F6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Header row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen\nRetur',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: tt.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Harap selesaikan proses pengambilan barang sesuai\ninstruksi di bawah.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // ── Item Card ────────────────────────────────────────────────
          _ItemCard(task: task),

          const SizedBox(height: 16),

          // ── Rute Card ────────────────────────────────────────────────
          _RouteCard(task: task),

          const SizedBox(height: 16),

          // ── Checklist Validasi ────────────────────────────────────────
          if (!isPickedUp)
            _SectionCard(
              label: 'CHECKLIST VALIDASI PICKUP',
              child: Column(
                children: _checklist.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return _ChecklistTile(
                    item: item,
                    onTap: () {
                      setState(() => _checklist[idx].checked = !_checklist[idx].checked);
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 28),

          // ── Terima / Tolak Retur (return_assigned) ─────────────────────
          if (isAssigned) _ReturnAcceptRejectButtons(
            task: task,
            onAccepted: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Tugas retur diterima!'),
                backgroundColor: Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
              ));
            },
            onRejected: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tugas retur ditolak. Seller akan cari kurir lain.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),

          // ── Ambil Barang Retur ─────────────────────────────────────────
          if (!isAssigned && !isPickedUp)
            _PrimaryButton(
              label: 'Barang Telah Diambil',
              icon: Icons.inventory_rounded,
              enabled: _allChecked,
              onPressed: () async {
                try {
                  await ref.read(orderRepositoryProvider).markReturnPickedUp(task.orderId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Barang retur berhasil diambil!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),

          if (isPickedUp) ...[
            _ConfirmButton(
              enabled: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourierKonfirReturScreen(
                      orderId: task.orderId,
                      itemName: task.productName,
                      itemCategory: task.productCategory,
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CourierReturBody — konten retur tanpa AppBar, untuk di-embed di tab Tugas
// ─────────────────────────────────────────────────────────────────────────────
class CourierReturBody extends ConsumerStatefulWidget {
  const CourierReturBody({super.key});

  @override
  ConsumerState<CourierReturBody> createState() => _CourierReturBodyState();
}

class _CourierReturBodyState extends ConsumerState<CourierReturBody> {
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem(
      title: 'Paket sudah dikemas dengan baik',
      subtitle: 'Pastikan kemasan rapi dan aman untuk dibawa.',
    ),
    _ChecklistItem(
      title: 'Kondisi paket tidak sobek, bocor, atau rusak parah',
      subtitle: 'Periksa fisik paket secara menyeluruh.',
    ),
    _ChecklistItem(
      title: 'Jumlah paket sesuai',
      subtitle: 'Cocokkan jumlah paket dengan data retur.',
    ),
    _ChecklistItem(
      title: 'Ukuran dan berat paket masih sesuai dengan pengiriman',
      subtitle: 'Pastikan dimensi dan berat tidak berubah signifikan.',
    ),
    _ChecklistItem(
      title: 'Foto bukti pickup diambil',
      subtitle: 'Dokumentasikan kondisi paket sebelum dibawa.',
    ),
  ];

  bool get _allChecked => _checklist.every((e) => e.checked);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(myCourierReturnTasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyBody(cs, tt);
        }
        final task = tasks.first;
        return _buildTaskBody(context, cs, tt, task);
      },
    );
  }

  Widget _buildEmptyBody(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Manajemen\nRetur',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada tugas retur yang ditugaskan.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            label: 'DETAIL BARANG',
            child: _EmptyCardContent(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada barang retur',
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            label: 'RUTE PENJEMPUTAN',
            child: _EmptyCardContent(
              icon: Icons.route_rounded,
              message: 'Belum ada rute',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTaskBody(BuildContext context, ColorScheme cs, TextTheme tt, OrderModel task) {
    final isAssigned  = task.status == OrderStatus.returnAssigned;
    final isPickedUp  = task.status == OrderStatus.returnPickedUp;
    final statusLabel = isPickedUp
        ? 'SEDANG DIANTAR KE SELLER'
        : isAssigned
            ? 'MENUNGGU KONFIRMASI KAMU'
            : 'MENUNGGU PENJEMPUTAN';
    final statusColor = isPickedUp
        ? const Color(0xFFF59E0B)
        : isAssigned
            ? const Color(0xFF4A90E2)
            : const Color(0xFF3B82F6);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Header row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen\nRetur',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: tt.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Harap selesaikan proses pengambilan barang sesuai\ninstruksi di bawah.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // ── Item Card ──────────────────────────────────────────────────
          _ItemCard(task: task),

          const SizedBox(height: 16),

          // ── Rute Card ──────────────────────────────────────────────────
          _RouteCard(task: task),

          const SizedBox(height: 16),

          // ── Checklist Validasi ─────────────────────────────────────────
          if (!isPickedUp)
            _SectionCard(
              label: 'CHECKLIST VALIDASI PICKUP',
              child: Column(
                children: _checklist.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return _ChecklistTile(
                    item: item,
                    onTap: () {
                      setState(() => _checklist[idx].checked = !_checklist[idx].checked);
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 28),

          // ── Terima / Tolak Retur (return_assigned) ─────────────────────
          if (isAssigned) _ReturnAcceptRejectButtons(
            task: task,
            onAccepted: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Tugas retur diterima!'),
                backgroundColor: Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
              ));
            },
            onRejected: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tugas retur ditolak. Seller akan cari kurir lain.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),

          // ── Ambil Barang Retur ─────────────────────────────────────────
          if (!isAssigned && !isPickedUp)
            _PrimaryButton(
              label: 'Barang Telah Diambil',
              icon: Icons.inventory_rounded,
              enabled: _allChecked,
              onPressed: () async {
                try {
                  await ref.read(orderRepositoryProvider).markReturnPickedUp(task.orderId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Barang retur berhasil diambil!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),

          if (isPickedUp) ...[
            _ConfirmButton(
              enabled: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourierKonfirReturScreen(
                      orderId: task.orderId,
                      itemName: task.productName,
                      itemCategory: task.productCategory,
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Card — menampilkan detail barang retur dari OrderModel
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.task});

  final OrderModel task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: task.productImageUrl.isNotEmpty
                      ? Image.network(
                          task.productImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CategoryIconWidget(
                            category: task.productCategory,
                            size: 72,
                          ),
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        )
                      : _CategoryIconWidget(
                          category: task.productCategory,
                          size: 72,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.productName.isNotEmpty ? task.productName : 'Produk',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${task.orderId.substring(0, 8).toUpperCase()}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category badge
                    if (task.productCategory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor(task.productCategory).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _categoryColor(task.productCategory).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(task.productCategory),
                              size: 12,
                              color: _categoryColor(task.productCategory),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.productCategory,
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _categoryColor(task.productCategory),
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Qty badge fallback
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.quantity} ${task.unit}'.toUpperCase(),
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withOpacity(0.65),
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),
          const SizedBox(height: 14),

          // Pickup address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: cs.primary.withOpacity(0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALAMAT PENJEMPUTAN (BUYER)',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.42),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.buyerAddress.isNotEmpty
                          ? task.buyerAddress
                          : task.buyerName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      task.buyerName,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
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
// Route Card — penjemputan (buyer) → tujuan (seller)
// ─────────────────────────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.task});

  final OrderModel task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        children: [
          // Penjemputan (Buyer)
          _RouteStopRow(
            iconWidget: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
            ),
            label: 'PENJEMPUTAN (BUYER)',
            name: task.buyerAddress.isNotEmpty
                ? task.buyerAddress
                : task.buyerName,
            contact: task.buyerName,
          ),

          // Dashed connector
          Padding(
            padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 1.5,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 3),
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // Tujuan (Seller)
          _RouteStopRow(
            iconWidget: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF22C55E).withOpacity(0.12),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 18,
                color: Color(0xFF16A34A),
              ),
            ),
            label: 'TUJUAN (SELLER)',
            name: task.sellerName.isNotEmpty ? task.sellerName : 'Seller',
            contact: task.sellerCity.isNotEmpty ? task.sellerCity : '',
          ),
        ],
      ),
    );
  }
}

class _RouteStopRow extends StatelessWidget {
  const _RouteStopRow({
    required this.iconWidget,
    required this.label,
    required this.name,
    required this.contact,
  });

  final Widget iconWidget;
  final String label;
  final String name;
  final String contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.42),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (contact.isNotEmpty)
                Text(
                  contact,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checklist item model
// ─────────────────────────────────────────────────────────────────────────────
class _ChecklistItem {
  _ChecklistItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
  bool checked = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Checklist Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.item, required this.onTap});

  final _ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: item.checked
              ? const Color(0xFF16A34A).withOpacity(0.05)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: item.checked
              ? Border.all(color: const Color(0xFF16A34A).withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Circle checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.checked
                    ? const Color(0xFF16A34A)
                    : Colors.transparent,
                border: Border.all(
                  color: item.checked
                      ? const Color(0xFF16A34A)
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: item.checked
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.checked
                          ? const Color(0xFF15803D)
                          : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(width: 10),
          Text(
            message,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary button — Ambil Barang Retur
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          disabledBackgroundColor: cs.primary.withOpacity(0.35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm button — Konfirmasi barang telah diserahkan (green)
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    const green = Color(0xFF16A34A);
    const greenDisabled = Color(0xFF86EFAC);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          disabledBackgroundColor: greenDisabled.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi barang telah diserahkan',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accept / Reject buttons — ditampilkan saat status return_assigned
// ─────────────────────────────────────────────────────────────────────────────
class _ReturnAcceptRejectButtons extends ConsumerWidget {
  const _ReturnAcceptRejectButtons({
    required this.task,
    required this.onAccepted,
    required this.onRejected,
  });

  final OrderModel task;
  final VoidCallback onAccepted;
  final VoidCallback onRejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        // ── Info banner ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4A90E2), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seller telah menugaskan kamu untuk menjemput barang retur ini. Terima atau tolak tugas.',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0xFF4A90E2),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Tombol Terima ─────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _onAccept(context, ref),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(
              'Terima Tugas Retur',
              style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Tombol Tolak ─────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _onReject(context, ref),
            icon: Icon(Icons.cancel_outlined, size: 20, color: cs.error),
            label: Text(
              'Tolak Tugas Retur',
              style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: cs.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.error.withOpacity(0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onAccept(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terima Tugas Retur',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Kamu yakin ingin menerima tugas penjemputan barang retur ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(orderRepositoryProvider).acceptReturn(task.orderId);
      onAccepted();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _onReject(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Tugas Retur',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Tolak tugas ini? Seller akan mendapat notifikasi dan dapat menugaskan kurir lain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(orderRepositoryProvider).rejectReturnTask(task.orderId);
      onRejected();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category helpers — icon & color berdasarkan commodityType
// ─────────────────────────────────────────────────────────────────────────────
IconData _categoryIcon(String type) {
  final t = type.toLowerCase();
  if (t.contains('serat'))                              return Icons.grass_rounded;
  if (t.contains('biomassa') || t.contains('energi'))  return Icons.local_fire_department_rounded;
  if (t.contains('pupuk') || t.contains('pertanian'))  return Icons.eco_rounded;
  if (t.contains('industri'))                          return Icons.factory_rounded;
  return Icons.inventory_2_rounded;
}

Color _categoryColor(String type) {
  final t = type.toLowerCase();
  if (t.contains('serat'))                              return const Color(0xFF8B6914);
  if (t.contains('biomassa') || t.contains('energi'))  return const Color(0xFF2E7D32);
  if (t.contains('pupuk') || t.contains('pertanian'))  return const Color(0xFF558B2F);
  if (t.contains('industri'))                          return const Color(0xFF1565C0);
  return const Color(0xFF005DA7);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget ikon kategori — thumbnail persegi berisi ikon sesuai kategori
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryIconWidget extends StatelessWidget {
  const _CategoryIconWidget({required this.category, this.size = 72});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final icon  = _categoryIcon(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.42,
      ),
    );
  }
}
