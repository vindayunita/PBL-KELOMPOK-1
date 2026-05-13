import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/auth_providers.dart';
import '../../data/courier_application_repository.dart';
import 'courier_status_verif.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model placeholder for activity history
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_field
enum _ActivityStatus { selesai, dibatalkan }

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
  });
  final String title;
  final String date;
  final String amount;
  final _ActivityStatus status;
}

// ─────────────────────────────────────────────────────────────────────────────
// Courier Profile Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierProfilScreen extends ConsumerStatefulWidget {
  const CourierProfilScreen({super.key});

  @override
  ConsumerState<CourierProfilScreen> createState() =>
      _CourierProfilScreenState();
}

class _CourierProfilScreenState extends ConsumerState<CourierProfilScreen> {
  // Empty list — ganti dengan data Firestore nantinya
  static const List<_ActivityItem> _activities = [];

  @override
  Widget build(BuildContext context) {
    // Gunakan AsyncValue agar tidak null saat loading awal auth
    final authAsync = ref.watch(authStateChangesProvider);
    final user      = ref.watch(currentUserProvider);
    final cs        = Theme.of(context).colorScheme;
    final tt        = Theme.of(context).textTheme;
    final name      = user?.displayName ?? user?.email ?? 'Kurir';
    final initials  = name.isNotEmpty ? name[0].toUpperCase() : 'K';

    // Ambil UID dari AsyncValue — null hanya jika benar-benar belum login
    final uid = authAsync.when(
      data:    (u) => u?.uid ?? '',
      loading: () => null,   // null = masih loading
      error:   (_, __) => '',
    );

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: cs.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  initials,
                  style: tt.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            title: Text(
              'EcoTrade',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: cs.onSurface),
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
                  const SizedBox(height: 8),

                  // ── Hero Identity Card ────────────────────────────────────
                  _HeroCard(name: name),

                  const SizedBox(height: 14),

                  // ── Status Aktif Toggle ───────────────────────────────────
                  // uid null  = auth masih loading
                  // uid ''    = tidak login
                  // uid valid = kurir sudah login
                  uid == null
                      ? const SizedBox(
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _StatusAktifCard(uid: uid),

                  const SizedBox(height: 14),

                  // ── Tugas Selesai Card ────────────────────────────────────
                  _TasksDoneCard(count: 0),

                  const SizedBox(height: 24),

                  // ── Riwayat Aktivitas ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Aktivitas',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Lihat Semua',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  _activities.isEmpty
                      ? _EmptyActivity()
                      : Column(
                          children: _activities
                              .map((a) => _ActivityRow(item: a))
                              .toList(),
                        ),

                  const SizedBox(height: 24),

                  // ── Pengaturan Akun ────────────────────────────────────────
                  Text(
                    'Pengaturan Akun',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.security_outlined,
                        iconColor: cs.primary,
                        title: 'Keamanan Akun',
                        onTap: () {},
                      ),
                      _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        iconColor: cs.primary,
                        title: 'Notifikasi',
                        onTap: () {},
                      ),
                      _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: cs.primary,
                        title: 'Bantuan & FAQ',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Cek Status Verifikasi ─────────────────────────────────
                  _CekStatusButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CourierStatusVerifScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Kembali ke Akun Buyer ─────────────────────────────────
                  _KembaliButton(
                    onTap: () => context.go('/dashboard'),
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
// Status Aktif Toggle Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatusAktifCard extends ConsumerStatefulWidget {
  const _StatusAktifCard({required this.uid});
  final String uid;

  @override
  ConsumerState<_StatusAktifCard> createState() => _StatusAktifCardState();
}

class _StatusAktifCardState extends ConsumerState<_StatusAktifCard>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool newValue) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(courierApplicationRepositoryProvider)
          .toggleActiveStatus(widget.uid, newValue);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika UID kosong, tampilkan pesan agar user login
    if (widget.uid.isEmpty) {
      return _StatusUidEmptyCard();
    }

    final appAsync =
        ref.watch(courierApplicationByUidProvider(widget.uid));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Debug log
    dev.log('[StatusAktif] uid=${widget.uid} state=${appAsync.runtimeType}',
        name: 'CourierProfil');
    appAsync.whenOrNull(
      error: (err, st) => dev.log('[StatusAktif] ERROR: $err', name: 'CourierProfil', error: err, stackTrace: st),
      data: (app) => dev.log('[StatusAktif] data=${app?.isActive} status=${app?.status}', name: 'CourierProfil'),
    );

    return appAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => _StatusErrorCard(uid: widget.uid, error: err.toString()),
      data: (app) {
        if (app == null) return _StatusNotFoundCard(uid: widget.uid);
        final isActive = app.isActive;
        final activeColor  = const Color(0xFF10B981);
        final inactiveColor = cs.onSurface.withValues(alpha: 0.38);
        final cardColor    = isActive
            ? activeColor.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5);
        final borderColor  = isActive
            ? activeColor.withValues(alpha: 0.35)
            : cs.outlineVariant.withValues(alpha: 0.4);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Animated dot
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Opacity(
                    opacity: isActive ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? activeColor : inactiveColor,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Siap Menerima Pesanan' : 'Tidak Aktif',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive ? activeColor : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Kamu akan mendapat notifikasi tugas baru'
                          : 'Aktifkan untuk mulai menerima tugas pengantaran',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Toggle switch
              _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: activeColor,
                        onChanged: _toggle,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status UID Empty Card – shown when user is not logged in
// ─────────────────────────────────────────────────────────────────────────────
class _StatusUidEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle_outlined,
              color: cs.onSurface.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 10),
          Text(
            'Silakan login untuk melihat status aktif',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Error Card – shown when Firestore fails to load
// ─────────────────────────────────────────────────────────────────────────────
class _StatusErrorCard extends ConsumerWidget {
  const _StatusErrorCard({required this.uid, required this.error});
  final String uid;
  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gagal Memuat Status',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Periksa koneksi internet atau pastikan akun kurir sudah diverifikasi.\n\nDetail: $error',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.invalidate(courierApplicationByUidProvider(uid)),
              icon: Icon(Icons.refresh_rounded, size: 16, color: cs.error),
              label: Text(
                'Coba Lagi',
                style: tt.labelMedium?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Not Found Card – shown when courier doc doesn't exist in Firestore
// ─────────────────────────────────────────────────────────────────────────────
class _StatusNotFoundCard extends ConsumerWidget {
  const _StatusNotFoundCard({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final warnColor = const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: warnColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warnColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: warnColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Belum Tersedia',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: warnColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Profil kurir tidak ditemukan. Pastikan pendaftaran sudah disetujui oleh admin.',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => ref.invalidate(courierApplicationByUidProvider(uid)),
            icon: Icon(Icons.refresh_rounded,
                size: 20, color: warnColor.withValues(alpha: 0.7)),
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Identity Card (blue gradient)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            Color.lerp(cs.primary, Colors.blue.shade300, 0.5) ?? cs.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'MITRA KURIR',
              style: tt.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Name
          Text(
            name,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 16),

          // Rating + Pendapatan
          Row(
            children: [
              // Rating Pelanggan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Pelanggan',
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '-',
                          style: tt.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.25),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              // Total Pendapatan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp 0',
                      style: tt.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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
// Tugas Selesai Card
// ─────────────────────────────────────────────────────────────────────────────
class _TasksDoneCard extends StatelessWidget {
  const _TasksDoneCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TUGAS SELESAI',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count == 0 ? '0' : '$count',
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Activity State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 26,
              color: cs.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Aktivitas',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Riwayat pengantaranmu akan\nmuncul di sini.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Row Item
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSelesai = item.status == _ActivityStatus.selesai;
    final badgeColor =
        isSelesai ? const Color(0xFF10B981) : cs.error;
    final badgeLabel = isSelesai ? 'SELESAI' : 'DIBATALKAN';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelesai
                  ? const Color(0xFFD1FAE5)
                  : cs.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelesai
                  ? Icons.local_shipping_rounded
                  : Icons.cancel_outlined,
              color: isSelesai ? const Color(0xFF10B981) : cs.error,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.date,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Badge + Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: tt.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.amount,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
// Settings Card container
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 16,
      color: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Cek Status Verifikasi Button
// ─────────────────────────────────────────────────────────────────────────────
class _CekStatusButton extends StatelessWidget {
  const _CekStatusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.verified_user_outlined, size: 20),
        label: const Text(
          'Cek Status Verifikasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kembali ke Akun Buyer Button (sama persis dengan seller)
// ─────────────────────────────────────────────────────────────────────────────
class _KembaliButton extends StatelessWidget {
  const _KembaliButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.person_outline,
            size: 20, color: Color(0xFF3B6934)),
        label: const Text(
          'Kembali ke Akun Buyer',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B6934)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3B6934), width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
