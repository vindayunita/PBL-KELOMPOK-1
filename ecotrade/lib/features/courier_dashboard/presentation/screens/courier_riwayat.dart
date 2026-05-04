import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
enum RiwayatStatus { selesai, sedangDikirim, dibatalkan }

class RiwayatTask {
  const RiwayatTask({
    required this.idTugas,
    required this.namaBarang,
    required this.status,
    this.sellerName,
    this.sellerLocation,
    this.timestamp,
    this.kualitas,
    this.tujuanNama,
    this.tujuanLocation,
    this.estimasiMenit,
    this.alasanDibatalkan,
    this.catatanDibatalkan,
    this.thumbnailIcon,
  });

  final String idTugas;
  final String namaBarang;
  final RiwayatStatus status;

  // Selesai
  final String? sellerName;
  final String? sellerLocation;
  final String? timestamp;
  final String? kualitas;

  // Sedang Dikirim
  final String? tujuanNama;
  final String? tujuanLocation;
  final int? estimasiMenit;

  // Dibatalkan
  final String? alasanDibatalkan;
  final String? catatanDibatalkan;

  // UI
  final IconData? thumbnailIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data (swap dengan Firestore nantinya)
// ─────────────────────────────────────────────────────────────────────────────
final _dummyRiwayat = [
  const RiwayatTask(
    idTugas: '#ECO-9821',
    namaBarang: 'Sabut Kelapa',
    status: RiwayatStatus.selesai,
    sellerName: 'GreenLife Jakarta',
    timestamp: '12 OKT 2023 • 14:20 WIB',
    thumbnailIcon: Icons.eco_rounded,
  ),
  const RiwayatTask(
    idTugas: '#ECO-9835',
    namaBarang: 'Serat Nanas',
    status: RiwayatStatus.sedangDikirim,
    tujuanNama: 'BioTextile Bandung',
    tujuanLocation: 'Kurir sedang menuju lokasi',
    estimasiMenit: 30,
    thumbnailIcon: Icons.grass_rounded,
  ),
  const RiwayatTask(
    idTugas: '#ECO-9799',
    namaBarang: 'Tempurung Kelapa',
    status: RiwayatStatus.dibatalkan,
    alasanDibatalkan: 'Kadar air terlalu tinggi\n(>20%)',
    timestamp: '11 OKT 2023 • 09:15 WIB',
    catatanDibatalkan: 'Mohon kembalikan ke Drop Point terdekat.',
    thumbnailIcon: Icons.spa_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierRiwayatScreen extends StatefulWidget {
  const CourierRiwayatScreen({super.key});

  @override
  State<CourierRiwayatScreen> createState() => _CourierRiwayatScreenState();
}

class _CourierRiwayatScreenState extends State<CourierRiwayatScreen> {
  int _filterIndex = 0; // 0=Semua, 1=Selesai, 2=Retur

  List<RiwayatTask> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _dummyRiwayat
            .where((t) => t.status == RiwayatStatus.selesai)
            .toList();
      case 2:
        return _dummyRiwayat
            .where((t) => t.status == RiwayatStatus.dibatalkan)
            .toList();
      default:
        return _dummyRiwayat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 22),
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
            child: _filtered.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final task = _filtered[i];
                      switch (task.status) {
                        case RiwayatStatus.selesai:
                          return _CardSelesai(task: task);
                        case RiwayatStatus.sedangDikirim:
                          return _CardSedangDikirim(task: task);
                        case RiwayatStatus.dibatalkan:
                          return _CardDibatalkan(task: task);
                      }
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
  final RiwayatStatus status;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Color bg;
    Color fg;
    String label;

    switch (status) {
      case RiwayatStatus.selesai:
        bg = const Color(0xFF16A34A);
        fg = Colors.white;
        label = 'Selesai';
        break;
      case RiwayatStatus.sedangDikirim:
        bg = const Color(0xFF3B82F6);
        fg = Colors.white;
        label = 'Sedang Dikirim';
        break;
      case RiwayatStatus.dibatalkan:
        bg = const Color(0xFFEF4444);
        fg = Colors.white;
        label = 'Dibatalkan';
        break;
    }

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
  final RiwayatTask task;

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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID TUGAS ${task.idTugas}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.42),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.namaBarang,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 14),

          // Content row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                icon: task.thumbnailIcon ?? Icons.inventory_2_outlined,
                bgColor: const Color(0xFF1C1C1E),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telah sampai di Seller:',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.sellerName ?? '-',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.timestamp ?? '',
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
              Row(
                children: [
                  Text(
                    task.kualitas ?? '',
                    style: tt.bodySmall?.copyWith(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
// Card: Sedang Dikirim
// ─────────────────────────────────────────────────────────────────────────────
class _CardSedangDikirim extends StatelessWidget {
  const _CardSedangDikirim({required this.task});
  final RiwayatTask task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: const Color(0xFF3B82F6), width: 3),
        ),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID TUGAS ${task.idTugas}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.42),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.namaBarang,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 14),

          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                icon: task.thumbnailIcon ?? Icons.inventory_2_outlined,
                bgColor: const Color(0xFFFF7849),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tujuan pengiriman:',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.tujuanNama ?? '-',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.tujuanLocation ?? '',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
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
          Text(
            'ESTIMASI TIBA: ${task.estimasiMenit ?? '-'} MENIT',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card: Dibatalkan
// ─────────────────────────────────────────────────────────────────────────────
class _CardDibatalkan extends StatelessWidget {
  const _CardDibatalkan({required this.task});
  final RiwayatTask task;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID TUGAS ${task.idTugas}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.42),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.namaBarang,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 14),

          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                icon: task.thumbnailIcon ?? Icons.inventory_2_outlined,
                bgColor: const Color(0xFF4B3728),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ditolak oleh sistem:',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.alasanDibatalkan ?? '-',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.timestamp ?? '',
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
              Expanded(
                child: Text(
                  task.catatanDibatalkan ?? '',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // TODO: buka halaman bantuan
                },
                child: Row(
                  children: [
                    Text(
                      'Bantuan',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: cs.onSurface.withOpacity(0.5),
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
          Icon(Icons.history_rounded,
              size: 52, color: cs.onSurface.withOpacity(0.2)),
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
