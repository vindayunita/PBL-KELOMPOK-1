import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/courier_dashboard/data/courier_application_repository.dart';
import 'courier_status_verif.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model per dokumen
// ─────────────────────────────────────────────────────────────────────────────
class _DocItem {
  _DocItem({required this.label, required this.storageKey});

  final String label;
  final String storageKey; // 'ktp' | 'sim'

  XFile? xfile;
  Uint8List? bytes;
  String? uploadedUrl;

  bool get isUploaded => uploadedUrl != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierUnggahScreen extends ConsumerStatefulWidget {
  const CourierUnggahScreen({super.key});

  @override
  ConsumerState<CourierUnggahScreen> createState() =>
      _CourierUnggahScreenState();
}

class _CourierUnggahScreenState extends ConsumerState<CourierUnggahScreen> {
  bool _isSending = false;
  final _picker = ImagePicker();

  final List<_DocItem> _docs = [
    _DocItem(label: 'Foto KTP', storageKey: 'ktp'),
    _DocItem(label: 'Foto SIM C', storageKey: 'sim'),
  ];

  bool get _allUploaded => _docs.every((d) => d.isUploaded);

  // ── Pick & upload single doc ──────────────────────────────────────────────
  Future<void> _pickAndUpload(int index) async {
    final doc = _docs[index];

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

    // Preview dulu sebelum upload
    final bytes = await picked.readAsBytes();
    setState(() {
      doc.xfile = picked;
      doc.bytes = bytes;
      doc.uploadedUrl = null; // reset URL lama
    });

    // Upload ke Firebase Storage
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User belum login');

      final ext = picked.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path =
          'courier_documents/$uid/${doc.storageKey}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();

      setState(() => doc.uploadedUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${doc.label} berhasil diunggah ✓'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        doc.xfile = null;
        doc.bytes = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah ${doc.label}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Retake ────────────────────────────────────────────────────────────────
  void _resetDoc(int index) => setState(() {
        _docs[index].xfile = null;
        _docs[index].bytes = null;
        _docs[index].uploadedUrl = null;
      });

  // ── Kirim semua dokumen → update Firestore ────────────────────────────────
  Future<void> _kirimDokumen() async {
    if (!_allUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap unggah semua dokumen terlebih dahulu.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User belum login');

      final ktpUrl = _docs[0].uploadedUrl!;
      final simUrl = _docs[1].uploadedUrl!;

      // Update URL ke Firestore
      final repo = ref.read(courierApplicationRepositoryProvider);
      await repo.updateDocumentImages(
        uid: uid,
        ktpImageUrl: ktpUrl,
        simImageUrl: simUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Dokumen berhasil dikirim! Menunggu verifikasi admin.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CourierStatusVerifScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim dokumen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
            icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person_rounded, color: cs.primary, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Title ─────────────────────────────────────────────
              Text(
                'Verifikasi Identitas',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unggah foto KTP dan SIM C Anda untuk mulai menjadi kurir EcoTrade.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 8),

              // Progress indicator
              _buildProgress(cs, tt),

              const SizedBox(height: 20),

              // ── Document Cards ────────────────────────────────────────
              ...List.generate(_docs.length, (i) {
                final doc = _docs[i];
                return _DocCard(
                  doc: doc,
                  onPickAndUpload: () => _pickAndUpload(i),
                  onRetake: () => _resetDoc(i),
                );
              }),

              const SizedBox(height: 8),

              // ── Tips Card ────────────────────────────────────────────
              _TipsCard(),

              const SizedBox(height: 28),

              // ── Kirim Dokumen Button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isSending || !_allUploaded) ? null : _kirimDokumen,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  icon: _isSending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending
                        ? 'Mengirim...'
                        : _allUploaded
                            ? 'Kirim Dokumen'
                            : 'Unggah Semua Foto Dulu',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ColorScheme cs, TextTheme tt) {
    final uploaded = _docs.where((d) => d.isUploaded).length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            uploaded == _docs.length
                ? Icons.check_circle_rounded
                : Icons.upload_file_rounded,
            color: uploaded == _docs.length
                ? const Color(0xFF10B981)
                : cs.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$uploaded dari ${_docs.length} dokumen berhasil diunggah',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Progress dots
          Row(
            children: List.generate(_docs.length, (i) {
              final done = _docs[i].isUploaded;
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF10B981)
                      : cs.outlineVariant,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Card
// ─────────────────────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.onPickAndUpload,
    required this.onRetake,
  });

  final _DocItem doc;
  final VoidCallback onPickAndUpload;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final uploaded = doc.isUploaded;
    final hasPick = doc.bytes != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: uploaded
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.label,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: uploaded
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : hasPick
                                ? cs.primary.withValues(alpha: 0.1)
                                : cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        uploaded
                            ? 'BERHASIL DIUNGGAH'
                            : hasPick
                                ? 'SEDANG MENGUPLOAD...'
                                : 'BELUM DIUNGGAH',
                        style: tt.labelSmall?.copyWith(
                          color: uploaded
                              ? const Color(0xFF10B981)
                              : hasPick
                                  ? cs.primary
                                  : cs.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Icon kanan
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: uploaded
                      ? const Color(0xFF10B981)
                      : hasPick
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_rounded
                      : hasPick
                          ? Icons.hourglass_top_rounded
                          : Icons.file_upload_outlined,
                  color: uploaded
                      ? Colors.white
                      : hasPick
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
            ],
          ),

          if (!uploaded && !hasPick) ...[
            // Belum dipilih: deskripsi + tombol ambil foto
            const SizedBox(height: 14),
            Text(
              'Pastikan foto ${doc.label} terlihat jelas, tidak buram, '
              'dan semua teks terbaca.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPickAndUpload,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(
                  'Pilih ${doc.label}',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Sudah dipilih (atau uploaded): tampilkan preview
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Preview gambar
                  if (doc.bytes != null)
                    Image.memory(
                      doc.bytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 180,
                      color: cs.surfaceContainerHigh,
                      child: Icon(Icons.image_rounded,
                          size: 56,
                          color: cs.onSurface.withValues(alpha: 0.2)),
                    ),

                  // Upload sedang berjalan overlay
                  if (hasPick && !uploaded)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Mengupload...',
                              style: tt.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Sukses badge
                  if (uploaded)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_rounded,
                                size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Terunggah',
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Ganti Foto',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
// Tips Card
// ─────────────────────────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Verifikasi Cepat',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gunakan latar belakang berwarna polos, pastikan semua teks pada KTP/SIM terbaca jelas, dan pencahayaan cukup terang.',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0xFF065F46),
                    height: 1.5,
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
