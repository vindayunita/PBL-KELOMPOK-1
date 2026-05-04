import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import 'courier_pendaftaran.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum status verifikasi
// ─────────────────────────────────────────────────────────────────────────────
enum VerifStatus { proses, ditolak, disetujui }

// ─────────────────────────────────────────────────────────────────────────────
// Model riwayat status
// ─────────────────────────────────────────────────────────────────────────────
class _StatusHistory {
  const _StatusHistory({
    required this.tanggal,
    required this.status,
    required this.keterangan,
  });
  final String tanggal;
  final VerifStatus status;
  final String keterangan;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierStatusVerifScreen extends ConsumerWidget {
  const CourierStatusVerifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appAsync = ref.watch(myCourierApplicationProvider);

    return appAsync.when(
      loading: () => Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: Center(child: Text('Error: $e')),
      ),
      data: (app) {
        // Tentukan status dari Firestore
        VerifStatus statusSaatIni;
        String? rejectionReason;
        String? reviewedAt;
        String submittedAt = '';

        if (app == null) {
          statusSaatIni = VerifStatus.proses;
        } else {
          submittedAt   = app.submittedAt;
          rejectionReason = app.rejectionReason;
          reviewedAt    = app.reviewedAt;
          statusSaatIni = app.isApproved
              ? VerifStatus.disetujui
              : app.isRejected
                  ? VerifStatus.ditolak
                  : VerifStatus.proses;
        }

        // Bangun riwayat dari data Firestore
        final List<_StatusHistory> riwayat = [];
        if (app != null) {
          riwayat.add(_StatusHistory(
            tanggal: _formatDate(submittedAt),
            status: VerifStatus.proses,
            keterangan: 'Pendaftaran kurir berhasil diajukan dan sedang menunggu review admin.',
          ));
          if (app.isApproved && reviewedAt != null) {
            riwayat.add(_StatusHistory(
              tanggal: _formatDate(reviewedAt),
              status: VerifStatus.disetujui,
              keterangan: 'Selamat! Pendaftaran kurir Anda telah disetujui oleh admin.',
            ));
          } else if (app.isRejected && reviewedAt != null) {
            riwayat.add(_StatusHistory(
              tanggal: _formatDate(reviewedAt),
              status: VerifStatus.ditolak,
              keterangan: rejectionReason != null
                  ? 'Alasan penolakan: $rejectionReason'
                  : 'Pendaftaran ditolak. Silakan hubungi admin untuk informasi lebih lanjut.',
            ));
          }
        }

        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          appBar: AppBar(
            backgroundColor: cs.surfaceContainerLowest,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.sync_rounded,
                      color: cs.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Verifikasi',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status utama ─────────────────────────────────────────
                  _MainStatusCard(status: statusSaatIni),

                  const SizedBox(height: 24),

                  // ── Riwayat ──────────────────────────────────────────────
                  Text(
                    'RIWAYAT STATUS TERAKHIR',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  riwayat.isEmpty
                      ? _EmptyHistory()
                      : Column(
                          children: riwayat
                              .map((h) => _HistoryCard(history: h))
                              .toList(),
                        ),

                  const SizedBox(height: 24),

                  // ── Apa Selanjutnya ───────────────────────────────────────
                  _NextStepsCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Main Status Card
// ─────────────────────────────────────────────────────────────────────────────
class _MainStatusCard extends StatelessWidget {
  const _MainStatusCard({required this.status});
  final VerifStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final config = _statusConfig(status, cs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon + badge
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: config.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.iconColor, size: 40),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.surface, width: 2),
                  ),
                  child: Text(
                    config.badgeLabel,
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            config.title,
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            config.subtitle,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          // Info pills
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: config.pills
                .map((p) => _InfoPill(icon: p.$1, label: p.$2))
                .toList(),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(VerifStatus s, ColorScheme cs) {
    switch (s) {
      case VerifStatus.proses:
        return _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          iconBg: cs.primaryContainer,
          iconColor: cs.primary,
          badgeColor: const Color(0xFF10B981),
          badgeLabel: 'PROSES',
          title: 'Data Sedang\nDiverifikasi oleh Admin',
          subtitle:
              'Mohon tunggu sebentar. Tim kurator kami sedang meninjau '
              'dokumen pendaftaran Anda untuk memastikan standar '
              'keberlanjutan EcoTrade tetap terjaga',
          pills: [
            (Icons.timer_outlined, 'ESTIMASI 24 JAM'),
            (Icons.verified_user_outlined, 'KEAMANAN TERJAMIN'),
          ],
        );
      case VerifStatus.ditolak:
        return _StatusConfig(
          icon: Icons.cancel_rounded,
          iconBg: cs.errorContainer.withValues(alpha: 0.5),
          iconColor: cs.error,
          badgeColor: cs.error,
          badgeLabel: 'DITOLAK',
          title: 'Verifikasi\nTidak Berhasil',
          subtitle:
              'Dokumen Anda belum memenuhi standar verifikasi. '
              'Silakan unggah ulang dokumen yang lebih jelas.',
          pills: [
            (Icons.refresh_rounded, 'UNGGAH ULANG'),
            (Icons.support_agent_outlined, 'HUBUNGI ADMIN'),
          ],
        );
      case VerifStatus.disetujui:
        return _StatusConfig(
          icon: Icons.check_circle_rounded,
          iconBg: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF10B981),
          badgeColor: const Color(0xFF10B981),
          badgeLabel: 'DISETUJUI',
          title: 'Selamat!\nAnda Resmi Menjadi Kurir',
          subtitle:
              'Akun kurir Anda telah aktif. Mulai terima tugas '
              'pengantaran dan raih penghasilan bersama EcoTrade.',
          pills: [
            (Icons.local_shipping_rounded, 'AKTIF SEKARANG'),
            (Icons.star_rounded, 'MITRA KURIR'),
          ],
        );
    }
  }
}

// Helper struct
class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badgeColor,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    required this.pills,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color badgeColor;
  final String badgeLabel;
  final String title;
  final String subtitle;
  final List<(IconData, String)> pills;
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Pill
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 6),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final _StatusHistory history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDitolak = history.status == VerifStatus.ditolak;
    final isSetujui = history.status == VerifStatus.disetujui;

    final Color accent = isDitolak
        ? cs.error
        : isSetujui
            ? const Color(0xFF10B981)
            : cs.primary;

    final IconData icon = isDitolak
        ? Icons.cancel_rounded
        : isSetujui
            ? Icons.check_circle_rounded
            : Icons.hourglass_top_rounded;

    final String statusLabel = isDitolak
        ? 'Data Ditolak'
        : isSetujui
            ? 'Data Disetujui'
            : 'Sedang Diproses';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: icon + tanggal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  history.tanggal,
                  style: tt.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            statusLabel,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            history.keterangan,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              height: 1.55,
            ),
          ),

          if (isDitolak) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final ctx = context;
                  Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CourierPendaftaranScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.refresh_rounded, size: 16, color: cs.error),
                label: Text(
                  'DAFTAR ULANG',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: cs.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty History
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded,
              size: 36,
              color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text(
            'Belum ada riwayat status',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}


class _NextStepsCard extends StatelessWidget {
  static const List<String> _steps = [
    'Admin memeriksa kelengkapan file pendukung.',
    'Pengecekan rekam jejak emisi kendaraan kurir.',
    'Notifikasi persetujuan dikirim ke email Anda.',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apa Selanjutnya?',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          ...List.generate(_steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _steps[i],
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          // Help link
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Butuh bantuan? Hubungi kurator kami melalui '),
                      TextSpan(
                        text: 'Pusat Dukungan',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
