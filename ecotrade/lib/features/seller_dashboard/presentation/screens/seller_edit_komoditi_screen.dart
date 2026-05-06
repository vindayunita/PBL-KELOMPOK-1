import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/product_repository.dart';
import '../../domain/product_model.dart';

class SellerEditKomoditiScreen extends ConsumerStatefulWidget {
  const SellerEditKomoditiScreen({super.key, required this.product});
  final ProductModel product;

  @override
  ConsumerState<SellerEditKomoditiScreen> createState() =>
      _SellerEditKomoditiScreenState();
}

class _SellerEditKomoditiScreenState
    extends ConsumerState<SellerEditKomoditiScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color dangerRed     = Color(0xFFE53935);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  late final TextEditingController _stokCtrl;
  late final TextEditingController _descCtrl;
  bool _isSaving   = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _stokCtrl = TextEditingController(
      text: widget.product.stock > 0 ? '${widget.product.stock}' : '',
    );
    _descCtrl = TextEditingController(text: widget.product.description);
    _stokCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _stokCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Simpan ke Firebase ──────────────────────────────────────────────────────
  Future<void> _onSimpan() async {
    final stokBaru = int.tryParse(_stokCtrl.text.trim());
    if (stokBaru == null || stokBaru < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok harus berupa angka yang valid')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(productRepositoryProvider).updateProduct(
        widget.product.id,
        {
          'stock':       stokBaru,
          'description': _descCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komoditi berhasil diperbarui!'),
          backgroundColor: Color(0xFF3B6934),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Hapus dari Firebase ─────────────────────────────────────────────────────
  void _onHapus() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Komoditi'),
        content: Text(
          'Yakin ingin menghapus "${widget.product.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // tutup dialog
              setState(() => _isDeleting = true);
              try {
                await ref.read(productRepositoryProvider)
                    .deleteProduct(widget.product.id);
                if (!mounted) return;
                Navigator.of(context).pop(); // kembali ke daftar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Komoditi berhasil dihapus'),
                    backgroundColor: dangerRed,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isDeleting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stok = widget.product.stock;
    final formattedStok = stok.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    final descLen = _descCtrl.text.length;
    final isBusy  = _isSaving || _isDeleting;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kelola Komoditi',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const Text(
              'COMMODITY UPDATE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: greyText, letterSpacing: 1.4),
            ),
            const SizedBox(height: 6),
            const Text(
              'Optimalkan Profil\nKomoditi Anda',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikan deskripsi yang mendalam untuk meningkatkan nilai kepercayaan dalam ekosistem perdagangan sirkular.',
              style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
            ),
            const SizedBox(height: 28),

            // ── Stok Tersedia Sekarang ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok Tersedia', style: TextStyle(fontSize: 12, color: greyText)),
                      Text(
                        '$formattedStok ${widget.product.unit}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Input: Update Stok ───────────────────────────────────────────
            const Text(
              'Update Stok Tersedia (Kg)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stokCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 28),

            // ── Input: Deskripsi ─────────────────────────────────────────────
            const Text(
              'Ubah Deskripsi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 7,
              maxLength: 2000,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Jelaskan karakteristik, asal-usul, dan proses pengolahan komoditi ini secara mendetail...',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                counterText: '$descLen / 2000',
                counterStyle: const TextStyle(fontSize: 11, color: greyText),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // ── Bottom Buttons ──────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Batalkan
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Hapus
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : _onHapus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: dangerRed.withValues(alpha: 0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hapus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),

              // Simpan
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : _onSimpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryBlue.withValues(alpha: 0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
