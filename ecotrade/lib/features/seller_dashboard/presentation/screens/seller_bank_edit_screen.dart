import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/seller_registration/data/seller_application_repository.dart';
import '../../../../features/user/domain/user_providers.dart';

/// Daftar bank Indonesia (sama persis dengan yang ada di form registrasi)
const _bankIndonesiaList = [
  'Bank BCA (Bank Central Asia)',
  'Bank Mandiri',
  'Bank BRI (Bank Rakyat Indonesia)',
  'Bank BNI (Bank Negara Indonesia)',
  'Bank CIMB Niaga',
  'Bank Danamon',
  'Bank Permata',
  'Bank Maybank Indonesia',
  'Bank OCBC NISP',
  'Bank Panin',
  'Bank BTN (Bank Tabungan Negara)',
  'Bank BSI (Bank Syariah Indonesia)',
  'Bank Muamalat',
  'Bank BTPN',
  'Bank Mega',
  'Bank Commonwealth',
  'Bank Sinarmas',
  'Bank DBS Indonesia',
  'Bank HSBC Indonesia',
  'Bank Standard Chartered Indonesia',
  'Bank Citibank Indonesia',
  'Bank ANZ Indonesia',
  'Bank BPD Jawa Timur (Bank Jatim)',
  'Bank BPD Jawa Tengah (Bank Jateng)',
  'Bank BPD Jawa Barat (Bank BJB)',
  'Bank BPD DKI Jakarta',
  'Bank BPD Bali',
  'Bank BPD Sulselbar',
  'Bank BPD Kaltim',
  'Bank BPD Sumatera Utara',
  'Bank BPD Sumatera Barat',
  'Bank BPD Sumatera Selatan',
  'Bank BPD Riau Kepri',
  'Bank BPD Kalimantan Barat',
  'Bank BPD Sulawesi Utara',
  'Bank BPD NTB',
  'Bank BPD NTT',
  'Bank BPD Papua',
  'Bank Ina Perdana',
  'Bank Neo Commerce',
  'Allo Bank',
  'SeaBank (Bank Seabank Indonesia)',
  'Bank Jago',
  'Blu by BCA Digital',
  'Bank Raya (BRI Agro)',
  'Bank Saqu (TMRW by UOB)',
  'GoPay Later (Bank Jago)',
  'OVO (Bank Nobu)',
  'Dana (Bank Allo)',
  'Jenius (BTPN)',
];

/// Layar ubah data bank seller.
/// Setiap perubahan data bank akan me-reset kycStatus ke 'pending'
/// dan membekukan fitur pencairan dana hingga admin memverifikasi ulang.
class SellerBankEditScreen extends ConsumerStatefulWidget {
  const SellerBankEditScreen({super.key});

  @override
  ConsumerState<SellerBankEditScreen> createState() =>
      _SellerBankEditScreenState();
}

class _SellerBankEditScreenState extends ConsumerState<SellerBankEditScreen> {
  static const Color _primaryBlue = Color(0xFF005DA7);
  static const Color _warningOrange = Color(0xFFF57F17);

  final _formKey = GlobalKey<FormState>();
  String? _selectedBank;
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl   = TextEditingController();
  bool _isLoading = false;
  bool _confirmedWarning = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dengan data bank yang sudah ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserDocProvider).value;
      if (user != null) {
        setState(() {
          _selectedBank = _bankIndonesiaList.contains(user.bankName)
              ? user.bankName
              : null;
          _accountNumberCtrl.text = user.bankAccountNumber ?? '';
          _accountNameCtrl.text   = user.bankAccountName   ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitChange() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmedWarning) {
      _showConfirmationDialog();
      return;
    }
    await _doSubmit();
  }

  Future<void> _doSubmit() async {
    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(sellerApplicationRepositoryProvider).updateBankData(
            uid:              user.uid,
            bankName:         _selectedBank!,
            bankAccountName:  _accountNameCtrl.text.trim(),
            bankAccountNumber:_accountNumberCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data bank diperbarui. Pencairan dana dibekukan hingga admin memverifikasi.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: _warningOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah data bank: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF57F17), size: 24),
            SizedBox(width: 8),
            Text(
              'Perhatian Penting',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: const Text(
          'Mengubah data bank akan:\n\n'
          '• Membekukan fitur "Cairkan Dana" Anda\n'
          '• Mengharuskan verifikasi ulang oleh admin\n'
          '• Membutuhkan waktu 1-2 hari kerja\n\n'
          'Pastikan nama pemilik rekening baru SAMA dengan nama di KTP Anda.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warningOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Ubah Data Bank'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() => _confirmedWarning = true);
        _doSubmit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ubah Data Bank',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Data Bank Saat Ini ────────────────────────────────────────
            if (user?.bankName != null) ...[
              const Text(
                'DATA BANK SAAT INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E3E4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_rounded,
                          color: Colors.grey, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.bankName ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            user?.bankAccountNumber ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'a.n. ${user?.bankAccountName ?? '-'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Warning Banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _warningOrange.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: _warningOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perubahan akan membekukan pencairan dana',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Setelah mengubah data bank, fitur "Cairkan Dana" akan dibekukan sementara hingga admin memverifikasi kecocokan nama KTP dan rekening baru Anda.',
                          style: tt.bodySmall?.copyWith(
                            color: const Color(0xFF5D4037).withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Form Data Bank Baru ───────────────────────────────────────
            const Text(
              'DATA BANK BARU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Bank
            const Text(
              'Nama Bank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedBank,
                isExpanded: true,
                hint: const Text(
                  'Pilih nama bank',
                  style: TextStyle(color: Colors.grey),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey),
                dropdownColor: Colors.white,
                validator: (v) =>
                    v == null ? 'Pilih bank terlebih dahulu' : null,
                items: _bankIndonesiaList.map((bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
              ),
            ),

            const SizedBox(height: 16),

            // Nomor Rekening
            const Text(
              'Nomor Rekening',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Contoh: 1234567890',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nomor rekening wajib diisi';
                }
                if (v.trim().length < 6) {
                  return 'Nomor rekening tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Nama Pemilik Rekening
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Pemilik Rekening',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Harus sama persis dengan nama di KTP',
                  style: tt.bodySmall?.copyWith(
                    color: cs.error.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNameCtrl,
              decoration: InputDecoration(
                hintText: 'Nama sesuai buku tabungan / aplikasi bank',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama pemilik rekening wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // ── Tombol Simpan ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _warningOrange,
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
                          Icon(Icons.save_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Simpan Perubahan Data Bank',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Batal
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Batal'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
