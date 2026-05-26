import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/admin_dashboard/data/payout_repository.dart';
import '../../../../features/user/domain/user_providers.dart';
import 'seller_kyc_completion_screen.dart';

/// Layar 2-step pencairan dana seller:
/// Step 1 — Input nominal + tampilkan rekening tujuan (read-only)
/// Step 2 — Review & konfirmasi
class SellerWithdrawalScreen extends ConsumerStatefulWidget {
  const SellerWithdrawalScreen({
    super.key,
    required this.withdrawableAmount,
  });

  final double withdrawableAmount;

  @override
  ConsumerState<SellerWithdrawalScreen> createState() =>
      _SellerWithdrawalScreenState();
}

class _SellerWithdrawalScreenState
    extends ConsumerState<SellerWithdrawalScreen> {
  static const Color _primaryBlue  = Color(0xFF005DA7);
  static const Color _darkGreen    = Color(0xFF2E7D32);
  static const Color _lightGreen   = Color(0xFFE8F5E9);

  final _formKey     = GlobalKey<FormState>();
  final _amountCtrl  = TextEditingController();
  bool _isReviewStep = false;
  bool _isLoading    = false;

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Format Rupiah ────────────────────────────────────────────────────────
  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  // ── Step 1 → Step 2 ──────────────────────────────────────────────────────
  void _proceedToReview() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isReviewStep = true);
  }

  // ── Submit pencairan dana ────────────────────────────────────────────────
  Future<void> _submitWithdrawal() async {
    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(payoutRepositoryProvider).requestSellerPayout(
            userId: user.uid,
            userName: user.name,
            amount: _enteredAmount,
            maxWithdrawable: widget.withdrawableAmount,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Permintaan pencairan berhasil dikirim ke Admin!'),
              ],
            ),
            backgroundColor: _darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Guard: KYC belum verified ─────────────────────────────────────────
    if (user != null && !user.isKycVerified) {
      return _buildKycBlockedScreen(context, user.kycStatus, cs, tt);
    }

    // ── Guard: Saldo < minimum ────────────────────────────────────────────
    if (widget.withdrawableAmount < kMinWithdrawalAmount) {
      return _buildInsufficientBalanceScreen(context, cs, tt);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isReviewStep ? Icons.arrow_back_rounded : Icons.close_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            if (_isReviewStep) {
              setState(() => _isReviewStep = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isReviewStep ? 'Review Penarikan' : 'Cairkan Dana',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isReviewStep
            ? _buildReviewStep(user, cs, tt)
            : _buildInputStep(user, cs, tt),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 1: Input Nominal
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInputStep(dynamic user, ColorScheme cs, TextTheme tt) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step Indicator ────────────────────────────────────────────
            _StepIndicator(currentStep: 1, totalSteps: 2),
            const SizedBox(height: 24),

            // ── Saldo Card ────────────────────────────────────────────────
            _BalanceCard(
              withdrawableAmount: widget.withdrawableAmount,
              formatRupiah: _formatRupiah,
            ),
            const SizedBox(height: 24),

            // ── Input Nominal ─────────────────────────────────────────────
            const Text(
              'NOMINAL PENARIKAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryBlue,
                ),
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 24),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primaryBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Masukkan nominal';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Nominal tidak valid';
                if (amount < kMinWithdrawalAmount) {
                  return 'Minimum penarikan ${_formatRupiah(kMinWithdrawalAmount)}';
                }
                if (amount > widget.withdrawableAmount) {
                  return 'Melebihi saldo yang bisa ditarik';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum penarikan: ${_formatRupiah(kMinWithdrawalAmount)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),

            const SizedBox(height: 28),

            // ── Rekening Tujuan (Read-Only) ───────────────────────────────
            const Text(
              'REKENING TUJUAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            if (user != null)
              _BankInfoCard(
                bankName: user.bankName ?? '-',
                accountNumber: user.bankAccountNumber ?? '-',
                accountName: user.bankAccountName ?? '-',
                isReadOnly: true,
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Data rekening terkunci dan telah diverifikasi admin. Hubungi admin untuk mengubah.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Tombol Lanjut ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _proceedToReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lanjut ke Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 2: Review & Konfirmasi
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReviewStep(dynamic user, ColorScheme cs, TextTheme tt) {
    final amount = _enteredAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step Indicator ──────────────────────────────────────────────
          _StepIndicator(currentStep: 2, totalSteps: 2),
          const SizedBox(height: 24),

          // ── Review Card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RINGKASAN PENARIKAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Nominal Ditarik
                _ReviewRow(
                  label: 'Nominal Ditarik',
                  value: _formatRupiah(amount),
                  valueColor: Colors.black87,
                  valueBold: true,
                  valueSize: 16,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),

                // Biaya Admin
                _ReviewRow(
                  label: 'Biaya Admin',
                  value: 'Gratis (Rp 0)',
                  valueColor: _darkGreen,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 2),
                ),

                // Total Diterima
                _ReviewRow(
                  label: 'Total Diterima',
                  value: _formatRupiah(amount),
                  valueColor: _darkGreen,
                  valueBold: true,
                  valueSize: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Rekening Tujuan ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REKENING TUJUAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (user != null)
                  _BankInfoCard(
                    bankName: user.bankName ?? '-',
                    accountNumber: user.bankAccountNumber ?? '-',
                    accountName: user.bankAccountName ?? '-',
                    isReadOnly: true,
                    showLockIcon: false,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info Proses ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time_rounded,
                    color: Color(0xFFF57F17), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Setelah dikonfirmasi, permintaan akan diproses oleh admin dalam 1-3 hari kerja. Dana akan ditransfer ke rekening tujuan Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D4037),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Tombol Konfirmasi ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Konfirmasi & Kirim Request',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Batal
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _isReviewStep = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ubah Nominal'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Guard Screens
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKycBlockedScreen(
      BuildContext context, String kycStatus, ColorScheme cs, TextTheme tt) {
    // ── Konfigurasi per status ──────────────────────────────────────────────
    final bool isPending  = kycStatus == 'pending';
    final bool isRejected = kycStatus == 'rejected';
    // unverified / null = seller lama sebelum KYC
    final bool isLegacy   = !isPending && !isRejected;

    Color iconBg;
    Color iconColor;
    IconData icon;
    String title;
    String description;
    String? buttonLabel;
    VoidCallback? onButton;

    if (isPending) {
      iconBg       = const Color(0xFFFFF8E1);
      iconColor    = const Color(0xFFF57F17);
      icon         = Icons.hourglass_top_rounded;
      title        = 'Verifikasi Sedang Diproses';
      description  = 'Dokumen KTP dan rekening bank Anda sedang ditinjau oleh admin. Biasanya membutuhkan 1–2 hari kerja.\n\nFitur "Cairkan Dana" akan aktif otomatis setelah disetujui.';
      buttonLabel  = null;
      onButton     = null;
    } else if (isRejected) {
      iconBg       = cs.errorContainer;
      iconColor    = cs.error;
      icon         = Icons.cancel_rounded;
      title        = 'Verifikasi Ditolak';
      description  = 'Dokumen KYC Anda ditolak oleh admin. Harap periksa kembali dan kirimkan ulang dokumen yang valid.';
      buttonLabel  = 'Kirim Ulang Data KYC';
      onButton     = () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SellerKycCompletionScreen()));
    } else {
      // Seller lama — belum pernah isi KYC
      iconBg       = const Color(0xFFE3F2FD);
      iconColor    = const Color(0xFF1565C0);
      icon         = Icons.verified_user_outlined;
      title        = 'Verifikasi Identitas Diperlukan';
      description  = 'Sebagai seller aktif, Anda perlu menyelesaikan verifikasi KYC satu kali sebelum bisa mencairkan dana.\n\nProses ini aman, cepat, dan hanya dilakukan sekali.';
      buttonLabel  = 'Lengkapi Verifikasi KYC';
      onButton     = () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SellerKycCompletionScreen()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cairkan Dana',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ─────────────────────────────────────────────────────
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 44, color: iconColor),
              ),
              const SizedBox(height: 24),

              // ── Judul ─────────────────────────────────────────────────────
              Text(
                title,
                style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // ── Deskripsi ─────────────────────────────────────────────────
              Text(
                description,
                style: tt.bodyMedium?.copyWith(
                    color: Colors.black54, height: 1.65),
                textAlign: TextAlign.center,
              ),

              // ── Tombol CTA (untuk seller lama / ditolak) ──────────────────
              if (buttonLabel != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLegacy
                          ? const Color(0xFF1565C0)
                          : cs.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLegacy ? Icons.badge_outlined : Icons.refresh_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(buttonLabel,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Dashboard',
                      style: TextStyle(color: Colors.grey)),
                ),
              ] else ...[
                // Status pending — tampilkan info saja
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: Color(0xFFF57F17), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimasi waktu verifikasi: 1–2 hari kerja',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Dashboard',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsufficientBalanceScreen(
      BuildContext context, ColorScheme cs, TextTheme tt) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cairkan Dana',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 40, color: _primaryBlue),
              ),
              const SizedBox(height: 24),
              Text(
                'Saldo Belum Mencukupi',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Saldo yang bisa ditarik adalah ${_formatRupiah(widget.withdrawableAmount)}. '
                'Minimum penarikan adalah ${_formatRupiah(kMinWithdrawalAmount)}.',
                style: tt.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Indicator Widget
// ─────────────────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    const labels = ['Input Nominal', 'Review & Konfirmasi'];
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          return Expanded(
            child: Container(
              height: 2,
              color: (i ~/ 2) < currentStep - 1
                  ? const Color(0xFF005DA7)
                  : Colors.grey.shade300,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone    = stepIndex < currentStep - 1;
        final isCurrent = stepIndex == currentStep - 1;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone || isCurrent
                    ? const Color(0xFF005DA7)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone || isCurrent
                      ? const Color(0xFF005DA7)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isCurrent ? Colors.white : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? const Color(0xFF005DA7)
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.withdrawableAmount,
    required this.formatRupiah,
  });
  final double withdrawableAmount;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'SALDO BISA DITARIK',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatRupiah(withdrawableAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Min. ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(kMinWithdrawalAmount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank Info Card (read-only)
// ─────────────────────────────────────────────────────────────────────────────
class _BankInfoCard extends StatelessWidget {
  const _BankInfoCard({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.isReadOnly = true,
    this.showLockIcon = true,
  });
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isReadOnly;
  final bool showLockIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD4E3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: Color(0xFF005DA7), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accountNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF005DA7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'a.n. $accountName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (showLockIcon && isReadOnly)
            const Icon(Icons.lock_outline_rounded,
                color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review Row
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.black87,
    this.valueBold = false,
    this.valueSize = 14,
  });
  final String label;
  final String value;
  final Color valueColor;
  final bool valueBold;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            color: valueColor,
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
