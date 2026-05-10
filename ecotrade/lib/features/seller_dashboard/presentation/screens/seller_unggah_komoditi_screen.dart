import 'dart:ui' show PathMetrics;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/product_repository.dart';

class SellerUnggahKomoditiScreen extends ConsumerStatefulWidget {
  const SellerUnggahKomoditiScreen({super.key});

  @override
  ConsumerState<SellerUnggahKomoditiScreen> createState() =>
      _SellerUnggahKomoditiScreenState();
}

class _SellerUnggahKomoditiScreenState
    extends ConsumerState<SellerUnggahKomoditiScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // ── Form controllers ──
  final _namaCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _stokCtrl  = TextEditingController();

  // ── Image state ──
  XFile?     _imageFile;
  Uint8List? _imageBytes;
  bool       _isUploadingImage = false;

  // ── Other state ──
  String? _jenisSelected;
  bool    _dropdownOpen = false;
  bool    _isLoading    = false;

  final _picker = ImagePicker();

  static const List<String> _jenisOptions = [
    'Serat Alami',
    'Biomassa & Energi',
    'Pupuk & Pertanian',
    'Bahan Industri',
    'Lainnya',
  ];

  @override
  void dispose() {
    _namaCtrl.dispose();
    _descCtrl.dispose();
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageFile  = picked;
      _imageBytes = bytes;
    });
  }

  // ── Upload image to Firebase Storage ─────────────────────────────────────
  Future<String> _uploadImage() async {
    if (_imageFile == null || _imageBytes == null) return '';

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '';

    final ext  = _imageFile!.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final path =
        'product_images/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(_imageBytes!, SettableMetadata(contentType: mime));
    return ref.getDownloadURL();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _onUnggah() async {
    if (_namaCtrl.text.trim().isEmpty) {
      _showSnack('Nama komoditi wajib diisi');
      return;
    }
    if (_jenisSelected == null) {
      _showSnack('Pilih jenis komoditi terlebih dahulu');
      return;
    }

    final harga = double.tryParse(_hargaCtrl.text.trim()) ?? 0.0;
    final stok  = int.tryParse(_stokCtrl.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    try {
      // Upload foto jika ada
      String imageUrl = '';
      if (_imageFile != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _uploadImage();
        if (mounted) setState(() => _isUploadingImage = false);
      }

      await ref.read(productRepositoryProvider).addProduct(
        title:         _namaCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        commodityType: _jenisSelected!,
        price:         harga,
        stock:         stok,
        imageUrl:      imageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komoditi berhasil ditambahkan!'),
          backgroundColor: Color(0xFF3B6934),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah komoditi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,

      // ── APP BAR ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Unggah Komoditi Baru',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),

      // ── BODY ──
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 28),

            // Nama Komoditi
            _buildFieldLabel('NAMA KOMODITI'),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _namaCtrl,
              hint: 'Masukkan nama komoditi',
            ),
            const SizedBox(height: 28),

            // Foto Komoditi
            _buildFieldLabel('FOTO KOMODITI'),
            const SizedBox(height: 4),
            Text(
              'Opsional — foto mempermudah pembeli mengenali produk Anda',
              style: const TextStyle(fontSize: 11, color: greyText),
            ),
            const SizedBox(height: 10),
            _buildFotoArea(),
            const SizedBox(height: 28),

            // Deskripsi
            _buildFieldLabel('DESKRIPSI'),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _descCtrl,
              hint: 'Masukkan deskripsi lengkap komoditi...',
              maxLines: 4,
            ),
            const SizedBox(height: 28),

            // Jenis Komoditi
            _buildFieldLabel('JENIS KOMODITI'),
            const SizedBox(height: 8),
            _buildDropdown(),
            const SizedBox(height: 28),

            // Stok Tersedia
            _buildFieldLabel('STOK TERSEDIA'),
            const SizedBox(height: 8),
            _buildStokField(),
            const SizedBox(height: 28),

            // Harga Per Kg
            _buildFieldLabel('HARGA PER KG'),
            const SizedBox(height: 8),
            _buildHargaField(),
            const SizedBox(height: 40),

            // Tombol Unggah
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onUnggah,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryBlue.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isUploadingImage
                                ? 'Mengunggah foto...'
                                : 'Menyimpan...',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : const Text(
                        'Unggah Komoditi Baru',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Widget: Section Header ──────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'INVENTARIS BARU',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: greyText,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Detail',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Masukkan spesifikasi teknis komoditi untuk dipublikasikan ke EcoTrade.',
          style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
        ),
      ],
    );
  }

  // ── Widget: Field Label ────────────────────────────────────────────────
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Widget: Underline TextField ────────────────────────────────────────
  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // ── Widget: Stok Field ─────────────────────────────────────────────────
  Widget _buildStokField() {
    return TextField(
      controller: _stokCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: const InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        suffixText: 'Kg',
        suffixStyle: TextStyle(fontSize: 13, color: greyText),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // ── Widget: Harga Field ────────────────────────────────────────────────
  Widget _buildHargaField() {
    return TextField(
      controller: _hargaCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: const InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixText: 'Rp ',
        prefixStyle: TextStyle(
            fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
        suffixText: '/ kg',
        suffixStyle: TextStyle(fontSize: 13, color: greyText),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // ── Widget: Area Foto (nyata) ──────────────────────────────────────────
  Widget _buildFotoArea() {
    // Sudah ada gambar yang dipilih → tampilkan preview
    if (_imageBytes != null) {
      return Column(
        children: [
          // Preview card
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.memory(
                  _imageBytes!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                // Overlay atas: badge "Foto dipilih"
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6934),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Foto dipilih',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tombol ganti / hapus
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(color: primaryBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Ganti Foto',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _imageFile  = null;
                    _imageBytes = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Hapus Foto',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Belum ada gambar → tampilkan tombol pilih dengan dashed border
    return GestureDetector(
      onTap: _pickImage,
      child: _DashedBorderBox(
        child: Container(
          width: double.infinity,
          height: 155,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    size: 26, color: primaryBlue),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ketuk untuk pilih foto',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue),
              ),
              const SizedBox(height: 4),
              const Text(
                'Format JPG atau PNG, Maks 5MB',
                style: TextStyle(fontSize: 12, color: greyText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Dropdown Jenis Komoditi ───────────────────────────────────
  Widget _buildDropdown() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _jenisSelected ?? 'Pilih jenis komoditi',
                    style: TextStyle(
                      fontSize: 15,
                      color: _jenisSelected != null
                          ? Colors.black87
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: greyText, size: 22),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _dropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_jenisOptions.length, (i) {
                final opt = _jenisOptions[i];
                final isSelected = opt == _jenisSelected;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _jenisSelected = opt;
                        _dropdownOpen  = false;
                      }),
                      borderRadius: BorderRadius.vertical(
                        top: i == 0
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottom: i == _jenisOptions.length - 1
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? primaryBlue
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded,
                                  color: primaryBlue, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (i < _jenisOptions.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper: Dashed Border Box ─────────────────────────────────────────────────
class _DashedBorderBox extends StatelessWidget {
  final Widget child;
  const _DashedBorderBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius    = 14.0;
    final paint = Paint()
      ..color       = const Color(0xFF005DA7)
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius)));

    final PathMetrics metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end =
            (distance + dashWidth).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}