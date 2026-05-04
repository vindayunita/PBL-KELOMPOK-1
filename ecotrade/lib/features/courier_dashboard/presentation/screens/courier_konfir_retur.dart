import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen konfirmasi retur — muncul setelah kurir klik "Konfirmasi Barang
// Diserahkan" di halaman Retur.
// ─────────────────────────────────────────────────────────────────────────────
class CourierKonfirReturScreen extends StatelessWidget {
  const CourierKonfirReturScreen({
    super.key,
    this.itemName = '-',
    this.itemCategory = '-',
    this.ecoGrade = '-',
  });

  /// Data produk — isi dari backend nantinya
  final String itemName;
  final String itemCategory;
  final String ecoGrade;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1C1C1E),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
                    icon: Icon(Icons.notifications_outlined,
                        color: cs.onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Success Banner ─────────────────────────────────────
                    _SuccessBanner(),
                    const SizedBox(height: 20),

                    // ── Detail Barang Card ─────────────────────────────────
                    _DetailBarangCard(
                      itemName: itemName,
                      itemCategory: itemCategory,
                      ecoGrade: ecoGrade,
                    ),
                    const SizedBox(height: 16),

                    // ── Status Pengiriman Card ─────────────────────────────
                    _StatusPengirimanCard(),
                    const SizedBox(height: 32),

                    // ── Tombol Barang Telah Diserahkan ─────────────────────
                    _SerahkanButton(
                      onPressed: () {
                        // TODO: update status retur ke Firestore → selesai
                        Navigator.of(context).pop(true);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success Banner  (hijau — "Berhasil Diambil!")
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7D55), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Lingkaran centang
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Berhasil Diambil!',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Barang telah berhasil diproses dari lokasi Buyer.',
            style: tt.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Barang Card  (dengan aksen border kiri biru)
// ─────────────────────────────────────────────────────────────────────────────
class _DetailBarangCard extends StatelessWidget {
  const _DetailBarangCard({
    required this.itemName,
    required this.itemCategory,
    required this.ecoGrade,
  });

  final String itemName;
  final String itemCategory;
  final String ecoGrade;

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
          // Label section
          Text(
            'DETAIL BARANG',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),

          // Konten
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aksen garis kiri biru
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // Thumbnail item
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF92400E),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),

                // Info teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        itemName,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kategori: $itemCategory',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ECO grade badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 12,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ecoGrade,
                              style: tt.labelSmall?.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 11,
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Pengiriman Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPengirimanCard extends StatelessWidget {
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
          Text(
            'STATUS PENGIRIMAN',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Ikon truk dalam lingkaran biru
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Dalam Perjalanan ke Seller',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
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
// Tombol "Barang Telah Diserahkan"
// ─────────────────────────────────────────────────────────────────────────────
class _SerahkanButton extends StatelessWidget {
  const _SerahkanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.verified_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Barang Telah Diserahkan',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
