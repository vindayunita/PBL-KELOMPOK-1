import 'dart:ui' show PathMetrics;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SellerUnggahKomoditiScreen extends StatefulWidget {
  const SellerUnggahKomoditiScreen({super.key});

  @override
  State<SellerUnggahKomoditiScreen> createState() =>
      _SellerUnggahKomoditiScreenState();
}

class _SellerUnggahKomoditiScreenState
    extends State<SellerUnggahKomoditiScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // ── State ──
  final TextEditingController _namaCtrl  = TextEditingController();
  final TextEditingController _descCtrl  = TextEditingController();
  final TextEditingController _hargaCtrl = TextEditingController();
  final TextEditingController _stokCtrl  = TextEditingController();

  String? _jenisSelected;
  bool    _dropdownOpen = false;

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

  void _onUnggah() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simulasi Unggah',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Komoditi berhasil diunggah (simulasi — belum terhubung ke backend).'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Kembali ke Produk',
                style: TextStyle(
                    color: primaryBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 8),
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
                onPressed: _onUnggah,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Unggah Komoditi Baru',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Widget: Section Header ─────────────────────────────────────────────────
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

  // ── Widget: Field Label ────────────────────────────────────────────────────
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

  // ── Widget: Underline TextField ────────────────────────────────────────────
  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixWidget,
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
        prefix: prefixWidget,
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

  // ── Widget: Stok Field (input teks angka) ──────────────────────────────────
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

  // ── Widget: Harga Field (input teks angka) ─────────────────────────────────
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

  // ── Widget: Area Foto ──────────────────────────────────────────────────────
  Widget _buildFotoArea() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Pilih foto (simulasi — belum terhubung ke backend)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: _DashedBorderBox(
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.camera_alt_outlined,
                  size: 34, color: Color(0xFFBBBBBB)),
              SizedBox(height: 10),
              Text(
                'Ketuk untuk unggah foto',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888)),
              ),
              SizedBox(height: 4),
              Text(
                'Format JPG atau PNG, Maks 5MB',
                style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Dropdown Jenis Komoditi ───────────────────────────────────────
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

// ── Helper: Dashed Border Box ──────────────────────────────────────────────────
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
      ..color       = const Color(0xFFCCCCCC)
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