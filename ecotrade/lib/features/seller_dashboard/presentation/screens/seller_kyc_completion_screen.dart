import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/seller_registration/data/seller_application_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daftar Bank Indonesia
// ─────────────────────────────────────────────────────────────────────────────
const _bankList = [
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

/// Layar pelengkap KYC untuk seller lama yang sudah aktif
/// sebelum sistem verifikasi KYC diterapkan.
///
/// Seller tidak perlu mendaftar ulang — hanya perlu upload KTP,
/// selfie + KTP, dan mengisi data rekening bank.
class SellerKycCompletionScreen extends ConsumerStatefulWidget {
  const SellerKycCompletionScreen({super.key});

  @override
  ConsumerState<SellerKycCompletionScreen> createState() =>
      _SellerKycCompletionScreenState();
}

class _SellerKycCompletionScreenState
    extends ConsumerState<SellerKycCompletionScreen> {
  static const Color _primaryBlue  = Color(0xFF005DA7);
  static const Color _darkGreen    = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();
  final _ktpNameCtrl      = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl   = TextEditingController();
  String? _selectedBank;

  XFile? _ktpImage;
  Uint8List? _ktpImageBytes;
  XFile? _selfieImage;
  Uint8List? _selfieImageBytes;

  final _picker = ImagePicker();
  bool _isLoading = false;
  int _currentStep = 0; // 0 = KTP, 1 = Bank, 2 = Review

  @override
  void dispose() {
    _ktpNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  // ── Pick foto KTP ────────────────────────────────────────────────────────
  Future<void> _pickKtpImage() async {
    try {
      final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600, maxHeight: 1600, imageQuality: 90);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _ktpImage = file;
          _ktpImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  // ── Pick foto selfie ────────────────────────────────────────────────────
  Future<void> _pickSelfieImage() async {
    try {
      final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600, maxHeight: 1600, imageQuality: 90);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selfieImage = file;
          _selfieImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  bool get _step0Valid =>
      _ktpImage != null &&
      _selfieImage != null &&
      _ktpNameCtrl.text.trim().isNotEmpty;

  bool get _step1Valid =>
      _selectedBank != null &&
      _accountNumberCtrl.text.trim().length >= 6 &&
      _accountNameCtrl.text.trim().isNotEmpty;

  // ── Navigasi antar step ──────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 0) {
      if (_ktpImage == null) { _showError('Harap upload foto KTP'); return; }
      if (_selfieImage == null) { _showError('Harap upload foto selfie'); return; }
      if (_ktpNameCtrl.text.trim().isEmpty) { _showError('Nama KTP wajib diisi'); return; }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── Submit KYC ────────────────────────────────────────────────────────────
  Future<void> _submitKyc() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      // Upload foto KTP
      String ktpUrl = '';
      final ktpBytes = await _ktpImage!.readAsBytes();
      final ktpExt = _ktpImage!.name.split('.').last.toLowerCase();
      final ktpRef = FirebaseStorage.instance
          .ref()
          .child('kyc/$uid/ktp_${DateTime.now().millisecondsSinceEpoch}.$ktpExt');
      await ktpRef.putData(ktpBytes,
          SettableMetadata(contentType: ktpExt == 'png' ? 'image/png' : 'image/jpeg'));
      ktpUrl = await ktpRef.getDownloadURL();

      // Upload foto selfie
      String selfieUrl = '';
      final selfieBytes = await _selfieImage!.readAsBytes();
      final selfieExt = _selfieImage!.name.split('.').last.toLowerCase();
      final selfieRef = FirebaseStorage.instance
          .ref()
          .child('kyc/$uid/selfie_${DateTime.now().millisecondsSinceEpoch}.$selfieExt');
      await selfieRef.putData(selfieBytes,
          SettableMetadata(contentType: selfieExt == 'png' ? 'image/png' : 'image/jpeg'));
      selfieUrl = await selfieRef.getDownloadURL();

      // Submit KYC ke Firestore
      await ref.read(sellerApplicationRepositoryProvider).submitKycOnly(
            uid:                   uid,
            ktpImageUrl:           ktpUrl,
            selfieWithKtpImageUrl: selfieUrl,
            ktpName:               _ktpNameCtrl.text.trim(),
            bankName:              _selectedBank!,
            bankAccountName:       _accountNameCtrl.text.trim(),
            bankAccountNumber:     _accountNumberCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data KYC berhasil dikirim! Admin akan memverifikasi dalam 1-2 hari kerja.',
                ),
              ),
            ],
          ),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      _showError('Gagal mengirim data KYC: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
            color: Colors.black87,
          ),
          onPressed: _currentStep > 0 ? _prevStep : () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verifikasi KYC',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
              'Langkah ${_currentStep + 1} dari 3',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Progress Bar ─────────────────────────────────────────────────
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade200,
            color: _primaryBlue,
            minHeight: 3,
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(cs, tt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme cs, TextTheme tt) {
    switch (_currentStep) {
      case 0:  return _buildStep0Ktp(cs, tt);
      case 1:  return _buildStep1Bank(cs, tt);
      default: return _buildStep2Review(cs, tt);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 0: Upload KTP & Nama
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep0Ktp(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info Banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kenapa perlu KYC?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _primaryBlue,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Sebagai seller aktif, Anda perlu menyelesaikan verifikasi identitas satu kali untuk dapat mencairkan dana penjualan ke rekening bank Anda.',
                        style: tt.bodySmall?.copyWith(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.75),
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Nama sesuai KTP ──────────────────────────────────────────────
          _sectionLabel('NAMA LENGKAP SESUAI KTP'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ktpNameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDeco('Contoh: BUDI SANTOSO'),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // ── Upload KTP ───────────────────────────────────────────────────
          Row(
            children: [
              _sectionLabel('FOTO KTP'),
              const SizedBox(width: 8),
              _requiredBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pastikan semua teks pada KTP terbaca dengan jelas.',
              style: tt.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 10),
          _PhotoPickerBox(
            imageBytes: _ktpImageBytes,
            onTap: _pickKtpImage,
            icon: Icons.credit_card_rounded,
            label: 'UPLOAD FOTO KTP',
            hint: 'Ketuk untuk memilih',
            accentColor: _primaryBlue,
          ),

          const SizedBox(height: 20),

          // ── Upload Selfie ────────────────────────────────────────────────
          Row(
            children: [
              _sectionLabel('FOTO SELFIE + KTP'),
              const SizedBox(width: 8),
              _requiredBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Foto wajah Anda sambil memegang KTP. Pastikan keduanya terlihat jelas.',
              style: tt.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 10),
          _PhotoPickerBox(
            imageBytes: _selfieImageBytes,
            onTap: _pickSelfieImage,
            icon: Icons.face_rounded,
            label: 'UPLOAD FOTO SELFIE + KTP',
            hint: 'Ketuk untuk memilih',
            accentColor: const Color(0xFF7B5EA7),
          ),

          const SizedBox(height: 32),

          // ── Tombol Lanjut ────────────────────────────────────────────────
          _primaryButton(
            label: 'Lanjut ke Data Bank',
            icon: Icons.arrow_forward_rounded,
            onPressed: _step0Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 1: Data Bank
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1Bank(ColorScheme cs, TextTheme tt) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const ValueKey('step1'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Warning nama harus sama ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _darkGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.security_rounded,
                      color: _darkGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama rekening HARUS sama dengan nama KTP',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _darkGreen,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nama KTP Anda: "${_ktpNameCtrl.text.trim()}".\nPastikan nama pemilik rekening sama persis.',
                          style: tt.bodySmall?.copyWith(
                              color: const Color(0xFF1B5E20)
                                  .withValues(alpha: 0.75),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Pilih Bank ───────────────────────────────────────────────
            _sectionLabel('NAMA BANK'),
            const SizedBox(height: 8),
            _BankDropdownField(
              value: _selectedBank,
              onChanged: (v) => setState(() => _selectedBank = v),
            ),

            const SizedBox(height: 16),

            // ── Nomor Rekening ───────────────────────────────────────────
            _sectionLabel('NOMOR REKENING'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.black87),
              decoration: _inputDeco('Contoh: 1234567890'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (v.trim().length < 6) return 'Nomor rekening tidak valid';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Nama Pemilik ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('NAMA PEMILIK REKENING'),
                const SizedBox(height: 2),
                const Text(
                  'Harus sama persis dengan nama KTP di atas',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.black87),
              decoration: _inputDeco('Nama sesuai buku tabungan / aplikasi bank'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                return null;
              },
            ),

            // ── Live check kecocokan nama ────────────────────────────────
            if (_accountNameCtrl.text.trim().isNotEmpty &&
                _ktpNameCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Builder(builder: (_) {
                final ktp = _ktpNameCtrl.text.trim().toLowerCase();
                final acc = _accountNameCtrl.text.trim().toLowerCase();
                final match = acc.contains(ktp.split(' ').first) ||
                    ktp.contains(acc.split(' ').first);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: match
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        match
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: match ? _darkGreen : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        match
                            ? 'Nama kemungkinan cocok dengan KTP'
                            : 'Periksa: nama mungkin berbeda dengan KTP!',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: match ? _darkGreen : Colors.red),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 32),

            _primaryButton(
              label: 'Lanjut ke Review',
              icon: Icons.arrow_forward_rounded,
              onPressed: _step1Valid ? _nextStep : null,
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
  Widget _buildStep2Review(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Review Card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewSectionHeader(
                    Icons.badge_outlined, 'DATA KTP', _primaryBlue),
                const SizedBox(height: 12),
                _reviewRow('Nama sesuai KTP', _ktpNameCtrl.text.trim(),
                    highlight: true),
                const SizedBox(height: 8),
                // Preview foto KTP
                if (_ktpImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_ktpImageBytes!,
                        height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 8),
                // Preview selfie
                if (_selfieImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_selfieImageBytes!,
                        height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewSectionHeader(
                    Icons.account_balance_rounded, 'DATA BANK', _darkGreen),
                const SizedBox(height: 12),
                _reviewRow('Nama Bank', _selectedBank ?? '-'),
                const SizedBox(height: 6),
                _reviewRow('Nomor Rekening', _accountNumberCtrl.text.trim()),
                const SizedBox(height: 6),
                _reviewRow('Nama Pemilik', _accountNameCtrl.text.trim(),
                    highlight: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info proses verifikasi ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Color(0xFFF57F17), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Setelah dikirim, admin akan memverifikasi data Anda dalam 1-2 hari kerja. Fitur "Cairkan Dana" akan aktif setelah verifikasi selesai.',
                    style: tt.bodySmall?.copyWith(
                        color: const Color(0xFF5D4037), height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Tombol Kirim ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Kirim Data Verifikasi KYC',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _prevStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ubah Data'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF888888),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _requiredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('WAJIB',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB71C1C),
            letterSpacing: 0.5,
          )),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _primaryButton(
      {required String label, required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _reviewSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.8)),
      ],
    );
  }

  Widget _reviewRow(String label, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? _primaryBlue : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Picker Box
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({
    required this.imageBytes,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.hint,
    required this.accentColor,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String hint;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: imageBytes != null
              ? Colors.transparent
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageBytes != null
                ? accentColor.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: imageBytes != null ? 2 : 1.5,
          ),
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(hint,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        Image.memory(imageBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                          color: accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Ganti',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
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
// Bank Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _BankDropdownField extends StatelessWidget {
  const _BankDropdownField({required this.value, required this.onChanged});
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        style: const TextStyle(color: Colors.black87),
        hint: const Text('Pilih nama bank',
            style: TextStyle(color: Colors.grey)),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.grey),
        dropdownColor: Colors.white,
        validator: (v) => v == null ? 'Pilih bank terlebih dahulu' : null,
        items: _bankList.map((bank) {
          return DropdownMenuItem<String>(
            value: bank,
            child: Text(bank, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
