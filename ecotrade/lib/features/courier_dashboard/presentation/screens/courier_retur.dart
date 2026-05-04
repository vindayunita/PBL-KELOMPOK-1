import 'package:flutter/material.dart';

import 'courier_cek_barang.dart';
import 'courier_konfir_retur.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model data retur (placeholder — swap dengan Firestore nantinya)
// ─────────────────────────────────────────────────────────────────────────────
class ReturTask {
  const ReturTask({
    required this.itemName,
    required this.itemSku,
    required this.itemPackaging,
    required this.pickupAddress,
    required this.pickupContact,
    required this.destinationName,
    required this.destinationAddress,
    this.itemPhotoUrl,
  });

  final String itemName;
  final String itemSku;
  final String itemPackaging;
  final String pickupAddress;   // Alamat penjemputan (customer)
  final String pickupContact;
  final String destinationName;    // Tujuan (seller / hub)
  final String destinationAddress;
  final String? itemPhotoUrl;
}

// ─────────────────────────────────────────────────────────────────────────────
// Status retur
// ─────────────────────────────────────────────────────────────────────────────
enum ReturStatus {
  menungguPenjemputan,
  sedangDiambil,
  selesai,
}

extension ReturStatusExt on ReturStatus {
  String get label {
    switch (this) {
      case ReturStatus.menungguPenjemputan:
        return 'MENUNGGU PENJEMPUTAN';
      case ReturStatus.sedangDiambil:
        return 'SEDANG DIAMBIL';
      case ReturStatus.selesai:
        return 'SELESAI';
    }
  }

  Color get color {
    switch (this) {
      case ReturStatus.menungguPenjemputan:
        return const Color(0xFF3B82F6); // biru
      case ReturStatus.sedangDiambil:
        return const Color(0xFFF59E0B); // kuning
      case ReturStatus.selesai:
        return const Color(0xFF22C55E); // hijau
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierReturScreen extends StatefulWidget {
  const CourierReturScreen({
    super.key,
    this.returTask,
    this.status = ReturStatus.menungguPenjemputan,
  });

  /// Pass null untuk tampilkan empty state
  final ReturTask? returTask;
  final ReturStatus status;

  @override
  State<CourierReturScreen> createState() => _CourierReturScreenState();
}

class _CourierReturScreenState extends State<CourierReturScreen> {
  // Checklist items — expand sesuai kebutuhan backend
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem(
      title: 'Cek Kondisi Barang',
      subtitle: 'Barang sesuai dengan foto laporan awal',
    ),
  ];

  bool get _allChecked => _checklist.every((e) => e.checked);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final task = widget.returTask; // null → empty state

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
            child: Padding(
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
                      // Status badge
                      if (task != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                widget.status.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.status.color.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            widget.status.label,
                            style: tt.labelSmall?.copyWith(
                              color: widget.status.color,
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
                  task == null
                      ? _SectionCard(
                          label: 'DETAIL BARANG',
                          child: _EmptyCardContent(
                            icon: Icons.inventory_2_outlined,
                            message: 'Belum ada barang retur',
                          ),
                        )
                      : _ItemCard(task: task),

                  const SizedBox(height: 16),

                  // ── Rute Card (pickup → destination) ─────────────────────────
                  task == null
                      ? _SectionCard(
                          label: 'RUTE PENJEMPUTAN',
                          child: _EmptyCardContent(
                            icon: Icons.route_rounded,
                            message: 'Belum ada rute',
                          ),
                        )
                      : _RouteCard(task: task),

                  const SizedBox(height: 16),

                  // ── Checklist Validasi ────────────────────────────────────────
                  _SectionCard(
                    label: 'CHECKLIST VALIDASI',
                    child: Column(
                      children: _checklist.asMap().entries.map((e) {
                        final idx = e.key;
                        final item = e.value;
                        return _ChecklistTile(
                          item: item,
                          onTap: () async {
                            final confirmed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const CourierCekBarangScreen(),
                              ),
                            );
                            if (confirmed == true) {
                              setState(() => _checklist[idx].checked = true);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Ambil Barang Retur button ─────────────────────────────────
                  _PrimaryButton(
                    label: 'Ambil Barang Retur',
                    icon: Icons.inventory_rounded,
                    onPressed: () {
                      // TODO: update status retur ke Firestore
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Konfirmasi diserahkan button ──────────────────────────────
                  _ConfirmButton(
                    enabled: _allChecked,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CourierKonfirReturScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CourierReturBody — konten retur tanpa AppBar, untuk di-embed di tab Tugas
// ─────────────────────────────────────────────────────────────────────────────
class CourierReturBody extends StatefulWidget {
  const CourierReturBody({
    super.key,
    this.returTask,
    this.status = ReturStatus.menungguPenjemputan,
  });

  final ReturTask? returTask;
  final ReturStatus status;

  @override
  State<CourierReturBody> createState() => _CourierReturBodyState();
}

class _CourierReturBodyState extends State<CourierReturBody> {
  final List<_ChecklistItem> _checklist = [
    _ChecklistItem(
      title: 'Cek Kondisi Barang',
      subtitle: 'Barang sesuai dengan foto laporan awal',
    ),
  ];

  bool get _allChecked => _checklist.every((e) => e.checked);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final task = widget.returTask;

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
              if (task != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.status.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.status.color.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    widget.status.label,
                    style: tt.labelSmall?.copyWith(
                      color: widget.status.color,
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
          task == null
              ? _SectionCard(
                  label: 'DETAIL BARANG',
                  child: _EmptyCardContent(
                    icon: Icons.inventory_2_outlined,
                    message: 'Belum ada barang retur',
                  ),
                )
              : _ItemCard(task: task),

          const SizedBox(height: 16),

          // ── Rute Card ──────────────────────────────────────────────────
          task == null
              ? _SectionCard(
                  label: 'RUTE PENJEMPUTAN',
                  child: _EmptyCardContent(
                    icon: Icons.route_rounded,
                    message: 'Belum ada rute',
                  ),
                )
              : _RouteCard(task: task),

          const SizedBox(height: 16),

          // ── Checklist Validasi ─────────────────────────────────────────
          _SectionCard(
            label: 'CHECKLIST VALIDASI',
            child: Column(
              children: _checklist.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                return _ChecklistTile(
                  item: item,
                  onTap: () async {
                    final confirmed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CourierCekBarangScreen(),
                      ),
                    );
                    if (confirmed == true) {
                      setState(() => _checklist[idx].checked = true);
                    }
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ── Ambil Barang Retur ─────────────────────────────────────────
          _PrimaryButton(
            label: 'Ambil Barang Retur',
            icon: Icons.inventory_rounded,
            onPressed: () {
              // TODO: update status retur ke Firestore
            },
          ),

          const SizedBox(height: 12),

          // ── Konfirmasi diserahkan ──────────────────────────────────────
          _ConfirmButton(
            enabled: _allChecked,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CourierKonfirReturScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.task});

  final ReturTask task;

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
                child: task.itemPhotoUrl != null
                    ? Image.network(
                        task.itemPhotoUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 30,
                          color: cs.onSurface.withOpacity(0.3),
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
                      task.itemName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${task.itemSku}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Packaging badge
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
                            task.itemPackaging.toUpperCase(),
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
                      'ALAMAT PENJEMPUTAN',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.42),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.pickupAddress,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      task.pickupContact,
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
// Route Card — penjemputan (customer) → tujuan (seller/hub)
// ─────────────────────────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.task});

  final ReturTask task;

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
        children: [
          // Penjemputan (Customer)
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
            label: 'PENJEMPUTAN (CUSTOMER)',
            name: task.pickupAddress,
            contact: task.pickupContact,
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

          // Tujuan (Seller / Hub)
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
            name: task.destinationName,
            contact: task.destinationAddress,
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
// Section Card wrapper (reused from tugas pattern)
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
  _ChecklistItem({required this.title, required this.subtitle, this.checked = false});

  final String title;
  final String subtitle;
  bool checked;
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
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
                    ? cs.primary
                    : Colors.transparent,
                border: Border.all(
                  color: item.checked
                      ? cs.primary
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
                      color: cs.onSurface,
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

            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.35),
              size: 20,
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
