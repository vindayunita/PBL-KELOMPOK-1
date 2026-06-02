import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/product_repository.dart';
import '../../data/seller_order_repository.dart';
import 'package:intl/intl.dart';
import 'seller_unggah_komoditi_screen.dart';
import 'seller_withdrawal_screen.dart';
import 'seller_bank_edit_screen.dart';
import 'seller_kyc_completion_screen.dart';
import '../../../../features/admin_dashboard/data/payout_repository.dart';
import '../../../../features/user/domain/user_providers.dart';
import '../../../../core/notifications/notification_providers.dart';

class SellerProfilScreen extends ConsumerStatefulWidget {
  const SellerProfilScreen({super.key});

  @override
  ConsumerState<SellerProfilScreen> createState() => _SellerProfilScreenState();
}

class _SellerProfilScreenState extends ConsumerState<SellerProfilScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // (aktivitas terkini sekarang diambil dari notificationStreamProvider)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: const Text(
          'EcoTrade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            // ── KYC Banner untuk seller lama yang belum verifikasi ──
            _buildKycBanner(),
            const SizedBox(height: 20),
            _buildTotalProdukCard(),
            const SizedBox(height: 12),
            _buildTotalPendapatanCard(),
            const SizedBox(height: 24),
            _buildAktivitasTerkini(),
            const SizedBox(height: 24),
            _buildTambahProdukButton(),
            const SizedBox(height: 12),
            _buildKembaliButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── KYC Banner (untuk seller lama / belum kyc) ──────────────────────────
  Widget _buildKycBanner() {
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox.shrink();

    final kycStatus = user.kycStatus;

    // Hanya tampilkan banner jika belum/tidak terverifikasi
    if (kycStatus == 'verified') return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;
    String? buttonLabel;
    VoidCallback? onButton;

    switch (kycStatus) {
      case 'pending':
        bgColor     = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFC107).withValues(alpha: 0.5);
        iconColor   = const Color(0xFFF57F17);
        icon        = Icons.hourglass_top_rounded;
        title       = 'Verifikasi KYC Sedang Diproses';
        subtitle    = 'Admin sedang meninjau dokumen identitas Anda. Fitur cairkan dana akan aktif setelah disetujui (1–2 hari kerja).';
        buttonLabel = null;
        onButton    = null;
        break;
      case 'rejected':
        bgColor     = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEF5350).withValues(alpha: 0.4);
        iconColor   = const Color(0xFFB71C1C);
        icon        = Icons.cancel_rounded;
        title       = 'Verifikasi KYC Ditolak';
        subtitle    = 'Dokumen KYC Anda ditolak. Harap kirim ulang dengan dokumen yang valid.';
        buttonLabel = 'Kirim Ulang KYC';
        onButton    = () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SellerKycCompletionScreen()));
        break;
      default: // null / 'unverified' / string lainnya = seller lama
        bgColor     = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFF1976D2).withValues(alpha: 0.35);
        iconColor   = const Color(0xFF1565C0);
        icon        = Icons.verified_user_outlined;
        title       = 'Lengkapi Verifikasi Identitas (KYC)';
        subtitle    = 'Untuk dapat mencairkan dana penjualan, Anda perlu mengunggah KTP dan data rekening bank. Proses verifikasi hanya dilakukan sekali.';
        buttonLabel = 'Lengkapi KYC Sekarang';
        onButton    = () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SellerKycCompletionScreen()));
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onButton,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: iconColor)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: iconColor.withValues(alpha: 0.75),
                              height: 1.5)),
                      if (buttonLabel != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: onButton,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(buttonLabel,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildDashboardHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFIL TOKO',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: darkGreen, letterSpacing: 1.2),
        ),
        SizedBox(height: 4),
        Text(
          'Ringkasan Bisnis',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 2),
        Text(
          'Ecotrade',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue),
        ),
      ],
    );
  }

  // ── Card Total Produk ──────────────────────────────────────────────────────
  Widget _buildTotalProdukCard() {
    final totalProduk = ref.watch(myProductsProvider).when(
      data:    (list) => list.length,
      loading: () => 0,
      error:   (_, __) => 0,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Produk yang Dijual',
                    style: TextStyle(fontSize: 12, color: Color(0xFF414751))),
                const SizedBox(height: 8),
                Text(
                  '$totalProduk',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFD4E3FF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined, color: primaryBlue, size: 24),
          ),
        ],
      ),
    );
  }

  // ── Card Total Pendapatan ──────────────────────────────────────────────────
  Widget _buildTotalPendapatanCard() {
    final totalRevenue = ref.watch(sellerTotalRevenueProvider);
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;

    final withdrawn   = user?.sellerWithdrawnAmount ?? 0.0;
    final withdrawable = totalRevenue - withdrawn;
    final kycStatus   = user?.kycStatus ?? 'unverified';
    final isVerified  = kycStatus == 'verified';
    final isPending   = kycStatus == 'pending';

    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final canWithdraw = isVerified && withdrawable >= kMinWithdrawalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PENDAPATAN',
                      style: TextStyle(fontSize: 12, color: Color(0xFF414751), letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rupiah.format(totalRevenue),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF3F6D38)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bisa ditarik: ${rupiah.format(withdrawable)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF005DA7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.payments_outlined, color: Color(0xFF3F6D38), size: 24),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Status KYC Badge ─────────────────────────────────────────
          _KycStatusBadge(kycStatus: kycStatus),

          const SizedBox(height: 12),

          // ── Tombol Cairkan Dana ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canWithdraw
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SellerWithdrawalScreen(
                                withdrawableAmount: withdrawable,
                              ),
                            ),
                          )
                      : !isVerified
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SellerWithdrawalScreen(
                                    withdrawableAmount: withdrawable,
                                  ),
                                ),
                              )
                          : null,
                  icon: Icon(
                    isVerified
                        ? Icons.account_balance_wallet_outlined
                        : Icons.lock_outline_rounded,
                    size: 14,
                    color: const Color(0xFF005DA7),
                  ),
                  label: Text(
                    isVerified ? 'CAIRKAN DANA' : 'CEK STATUS',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF005DA7)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFF005DA7)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Ubah Bank (hanya jika sudah verified)
              if (isVerified || isPending)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SellerBankEditScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: Color(0xFF888888),
                  ),
                  label: const Text(
                    'UBAH BANK',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: const Color(0xFFF5F5F5),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Aktivitas Terkini (dari notifikasi real-time) ──────────────────────────
  Widget _buildAktivitasTerkini() {
    final notifAsync = ref.watch(notificationStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: bisa diklik → ke halaman notifikasi ──
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Row(
            children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              const Text('Aktivitas Terkini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Spacer(),
              const Row(
                children: [
                  Text('Lihat semua',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkGreen)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: darkGreen),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Konten: loading / error / kosong / daftar notif ──
        notifAsync.when(
          loading: () => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Center(
              child: Text('Gagal memuat aktivitas',
                  style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
            ),
          ),
          data: (notifications) {
            // Tampilkan maks 3 notifikasi terbaru
            final items = notifications.take(3).toList();

            if (items.isEmpty) {
              return GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada aktivitas',
                      style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: List.generate(items.length, (i) {
                  final n = items[i];
                  final icon  = _iconFromNotifType(n.type);
                  final color = _colorFromNotifType(n.type);
                  final timeStr = _formatRelativeTime(n.createdAt);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => context.push('/notifications'),
                        borderRadius: BorderRadius.vertical(
                          top:    i == 0 ? const Radius.circular(16) : Radius.zero,
                          bottom: i == items.length - 1 ? const Radius.circular(16) : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Ikon + dot belum-dibaca
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  if (!n.isRead)
                                    Positioned(
                                      right: -2, top: -2,
                                      child: Container(
                                        width: 10, height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Judul + isi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n.body,
                                      style: const TextStyle(fontSize: 12, color: greyText),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Waktu relatif
                              Text(timeStr,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: greyText)),
                            ],
                          ),
                        ),
                      ),
                      if (i < items.length - 1)
                        const Divider(height: 1, indent: 66, endIndent: 16),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Helper: ikon berdasarkan tipe notifikasi ────────────────────────────────
  IconData _iconFromNotifType(String type) {
    switch (type) {
      case 'order_new':        return Icons.shopping_bag_outlined;
      case 'order_confirmed':  return Icons.check_circle_outline_rounded;
      case 'order_rejected':   return Icons.cancel_outlined;
      case 'order_assigned':   return Icons.local_shipping_outlined;
      case 'order_picked_up':  return Icons.directions_bike_outlined;
      case 'order_delivered':  return Icons.home_outlined;
      case 'return_requested': return Icons.assignment_return_outlined;
      case 'return_approved':  return Icons.assignment_turned_in_outlined;
      case 'return_picked_up': return Icons.directions_bike_outlined;
      case 'return_completed': return Icons.done_all_rounded;
      case 'payout_requested': return Icons.account_balance_wallet_outlined;
      case 'payout_processed': return Icons.payments_outlined;
      default:                 return Icons.notifications_outlined;
    }
  }

  // ── Helper: warna berdasarkan tipe notifikasi ───────────────────────────────
  Color _colorFromNotifType(String type) {
    if (type.startsWith('order_')) return primaryBlue;
    if (type.startsWith('return_')) return const Color(0xFFE65100);
    if (type.startsWith('payout_')) return darkGreen;
    return greyText;
  }

  // ── Helper: format waktu relatif ───────────────────────────────────────────
  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}j';
    if (diff.inDays < 7)     return '${diff.inDays}h';
    return DateFormat('d MMM', 'id').format(dt);
  }

  // ── Tombol Tambah Produk ───────────────────────────────────────────────────
  Widget _buildTambahProdukButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SellerUnggahKomoditiScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Tambah Komoditi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Tombol Kembali ke Akun Buyer ───────────────────────────────────────────
  Widget _buildKembaliButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          // Kembali ke buyer dashboard
          // Gunakan go() agar GoRouter me-replace stack ke /dashboard
          context.go('/dashboard');
        },
        icon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF3B6934)),
        label: const Text(
          'Kembali ke Akun Buyer',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3B6934)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3B6934), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// KYC Status Badge
// ─────────────────────────────────────────────────────────────────────────────
class _KycStatusBadge extends StatelessWidget {
  const _KycStatusBadge({required this.kycStatus});
  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (kycStatus) {
      case 'verified':
        bgColor   = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon      = Icons.verified_rounded;
        label     = 'Terverifikasi — Pencairan dana aktif';
        break;
      case 'pending':
        bgColor   = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        icon      = Icons.hourglass_top_rounded;
        label     = 'Menunggu verifikasi admin';
        break;
      case 'rejected':
        bgColor   = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFB71C1C);
        icon      = Icons.cancel_rounded;
        label     = 'Verifikasi ditolak — Hubungi admin';
        break;
      default:
        bgColor   = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF888888);
        icon      = Icons.info_outline_rounded;
        label     = 'KYC belum dilengkapi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
