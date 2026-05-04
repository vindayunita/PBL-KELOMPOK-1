import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model parameter kualitas
// ─────────────────────────────────────────────────────────────────────────────
class _QualityParam {
  _QualityParam({required this.title, required this.subtitle, this.isDiscrepancy = false});
  final String title;
  final String subtitle;
  final bool isDiscrepancy;
  bool checked = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierCekBarangScreen extends StatefulWidget {
  const CourierCekBarangScreen({super.key});

  @override
  State<CourierCekBarangScreen> createState() => _CourierCekBarangScreenState();
}

class _CourierCekBarangScreenState extends State<CourierCekBarangScreen> {
  final List<_QualityParam> _params = [
    _QualityParam(
      title: '-',
      subtitle: '-',
    ),
    _QualityParam(
      title: '-',
      subtitle: '-',
    ),
    _QualityParam(
      title: 'Barang tidak sesuai dengan data retur',
      subtitle: 'Centang jika fisik barang berbeda dengan manifes digital.',
      isDiscrepancy: true,
    ),
  ];

  final _noteController = TextEditingController();

  // Dummy: true = sudah ada foto
  bool _hasPhoto = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cek Kondisi Barang',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person_rounded, color: cs.primary, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ───────────────────────────────────────────────
            _StatusBanner(),
            const SizedBox(height: 16),

            // ── Item card ───────────────────────────────────────────────────
            _ItemCard(),
            const SizedBox(height: 20),

            // ── Parameter Kualitas ──────────────────────────────────────────
            _ParameterSection(params: _params, onToggle: (idx) {
              setState(() => _params[idx].checked = !_params[idx].checked);
            }),
            const SizedBox(height: 20),

            // ── Bukti Foto ──────────────────────────────────────────────────
            Text(
              'Bukti Foto Kondisi',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _PhotoSection(
              hasPhoto: _hasPhoto,
              onAdd: () => setState(() => _hasPhoto = true),
              onRemove: () => setState(() => _hasPhoto = false),
            ),
            const SizedBox(height: 14),

            // ── Catatan tambahan ─────────────────────────────────────────────
            Text(
              'CATATAN TAMBAHAN (OPSIONAL)',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Tambahkan keterangan jika ada ketidaksesuaian...',
                hintStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.35),
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Lanjutkan Pengiriman ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: update status & navigate
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  'LANJUTKAN PENGIRIMAN',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Laporkan Kendala ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: kirim laporan kendala ke admin
                },
                icon: Icon(Icons.warning_amber_rounded,
                    color: cs.onSurface.withOpacity(0.65), size: 20),
                label: Text(
                  'LAPORKAN KENDALA KE ADMIN',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Disclaimer ───────────────────────────────────────────────────
            Text(
              '*Dengan menekan tombol di atas, Kurir melaporkan ke sistem tidak ada kendala atau kondisi barang yang diperiksa secara luring.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time_rounded,
              color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem menunggu konfirmasi admin',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Laporan Anda sedang ditinjau. Anda akan menerima notifikasi segera setelah ada keputusan.',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Card
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
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
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EcoTrade badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EcoTrade',
                        style: tt.labelSmall?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '-',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '-',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Item image placeholder
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: const Color(0xFF1C1C1E),
                      child: const Icon(Icons.grass_rounded,
                          color: Colors.white54, size: 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stat badges
                  Row(
                    children: [
                      _StatBadge(label: 'BERAT/TARGET', value: '-'),
                      const SizedBox(width: 6),
                      _StatBadge(label: 'KEMASAN', value: '-'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              fontSize: 8,
              color: cs.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parameter Kualitas Section
// ─────────────────────────────────────────────────────────────────────────────
class _ParameterSection extends StatelessWidget {
  const _ParameterSection({
    required this.params,
    required this.onToggle,
  });

  final List<_QualityParam> params;
  final void Function(int idx) onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final required = params.where((p) => !p.isDiscrepancy).toList();
    final discrepancy = params.where((p) => p.isDiscrepancy).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Parameter Kualitas',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Required params
        ...required.map((p) {
          final idx = params.indexOf(p);
          return _ParamTile(
            param: p,
            onTap: () => onToggle(idx),
          );
        }),

        const SizedBox(height: 10),

        // KETIDAKSESUAIAN DATA label
        Text(
          'KETIDAKSESUAIAN DATA',
          style: tt.labelSmall?.copyWith(
            color: cs.error,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),

        // Discrepancy params
        ...discrepancy.map((p) {
          final idx = params.indexOf(p);
          return _ParamTile(
            param: p,
            onTap: () => onToggle(idx),
            isDiscrepancy: true,
          );
        }),
      ],
    );
  }
}

class _ParamTile extends StatelessWidget {
  const _ParamTile({
    required this.param,
    required this.onTap,
    this.isDiscrepancy = false,
  });

  final _QualityParam param;
  final VoidCallback onTap;
  final bool isDiscrepancy;

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
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: param.checked
              ? Border.all(
                  color: isDiscrepancy
                      ? cs.error.withOpacity(0.5)
                      : cs.primary.withOpacity(0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: param.checked
                    ? (isDiscrepancy ? cs.error : cs.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: param.checked
                      ? (isDiscrepancy ? cs.error : cs.primary)
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: param.checked
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    param.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDiscrepancy ? cs.error : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    param.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                      height: 1.4,
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
// Photo Section
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.hasPhoto,
    required this.onAdd,
    required this.onRemove,
  });

  final bool hasPhoto;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        // Add photo slot
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 30, color: cs.onSurface.withOpacity(0.35)),
                const SizedBox(height: 6),
                Text(
                  'AMBIL FOTO',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.45),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Photo preview (if exists)
        if (hasPhoto)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 110,
                  height: 110,
                  color: const Color(0xFF1C1C1E),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white54, size: 40),
                ),
              ),
              // Delete button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
