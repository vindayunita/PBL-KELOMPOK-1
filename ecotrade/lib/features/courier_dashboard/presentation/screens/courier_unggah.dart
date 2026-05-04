import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'courier_status_verif.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
enum _UploadStatus { belum, berhasil }

class _DocState {
  _DocState({required this.label, this.status = _UploadStatus.belum});
  final String label;
  _UploadStatus status;

  bool get uploaded => status == _UploadStatus.berhasil;
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

  // Daftar dokumen yang perlu diunggah
  final List<_DocState> _docs = [
    _DocState(label: 'Foto KTP'),
    _DocState(label: 'Foto SIM C'),
  ];

  // Simulasi upload (ganti dengan image_picker + Firestore Storage nantinya)
  Future<void> _simulateUpload(int index) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _docs[index].status = _UploadStatus.berhasil);
  }

  // Ganti / reset
  void _resetDoc(int index) =>
      setState(() => _docs[index].status = _UploadStatus.belum);

  bool get _allUploaded => _docs.every((d) => d.uploaded);

  Future<void> _kirimDokumen() async {
    if (!_allUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap unggah semua dokumen terlebih dahulu.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSending = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Dokumen berhasil dikirim! Menunggu verifikasi admin.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
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
              child:
                  Icon(Icons.person_rounded, color: cs.primary, size: 20),
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
                'Lengkapi dokumen kurir Anda untuk mulai melakukan pengiriman ramah lingkungan hari ini.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 24),

              // ── Document Cards ────────────────────────────────────────
              ...List.generate(_docs.length, (i) {
                final doc = _docs[i];
                return _DocCard(
                  doc: doc,
                  onUpload: () => _simulateUpload(i),
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
                  onPressed: _isSending ? null : _kirimDokumen,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
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
                    'Kirim Dokumen',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Card
// ─────────────────────────────────────────────────────────────────────────────
class _DocCard extends StatefulWidget {
  const _DocCard({
    required this.doc,
    required this.onUpload,
    required this.onRetake,
  });

  final _DocState doc;
  final VoidCallback onUpload;
  final VoidCallback onRetake;

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  bool _uploading = false;

  Future<void> _handleUpload() async {
    setState(() => _uploading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _uploading = false);
    widget.onUpload();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final uploaded = widget.doc.uploaded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
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
                      widget.doc.label,
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
                            : cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        uploaded ? 'BERHASIL DIUNGGAH' : 'BELUM DIUNGGAH',
                        style: tt.labelSmall?.copyWith(
                          color: uploaded
                              ? const Color(0xFF10B981)
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
                      : cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_rounded
                      : Icons.file_upload_outlined,
                  color: uploaded ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
            ],
          ),

          if (!uploaded) ...[
            // Belum diunggah: deskripsi + tombol ambil foto
            const SizedBox(height: 14),
            Text(
              'Pastikan foto ${widget.doc.label} terlihat jelas, tidak buram, '
              'dan berada dalam bingkai yang ditentukan.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _uploading ? null : _handleUpload,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _uploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(
                  _uploading ? 'Mengupload...' : 'Ambil ${widget.doc.label}',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Berhasil diunggah: preview placeholder + Lihat/Ganti
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 140,
                color: cs.surfaceContainerHigh,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 56,
                      color: cs.onSurface.withValues(alpha: 0.2),
                    ),
                    // "Lihat Foto" overlay button
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.remove_red_eye_outlined,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Text(
                              'Lihat Foto',
                              style: tt.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onRetake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(
                      color: cs.outlineVariant, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Ganti Foto',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
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
                  'Gunakan latar belakang berwarna polos dan pastikan pencahayaan cukup terang (cahaya matahari adalah yang terbaik).',
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
