import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import '../../../../features/user/data/user_repository.dart';
import '../../../../features/user/domain/user_providers.dart';
import '../../../../shared/services/profile_photo_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final doc = ref.read(currentUserDocProvider).value;
    final auth = ref.read(currentUserProvider);
    _nameCtrl  = TextEditingController(text: doc?.name  ?? auth?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: doc?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Upload & save photo ──────────────────────────────────────────────────────
  Future<void> _changePhoto() async {
    final doc = ref.read(currentUserDocProvider).value;
    if (doc == null) return;

    final bytes = await ProfilePhotoService.pickImage(context);
    if (bytes == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ProfilePhotoService.uploadProfilePhoto(
        uid: doc.uid,
        bytes: bytes,
      );
      await Future.wait([
        ref.read(userRepositoryProvider).updateProfile(uid: doc.uid, photoUrl: url),
        ref.read(authRepositoryProvider).updatePhotoUrl(url),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Delete photo ─────────────────────────────────────────────────────────────
  Future<void> _deletePhoto() async {
    final doc = ref.read(currentUserDocProvider).value;
    if (doc == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      await Future.wait([
        ref.read(userRepositoryProvider).removePhoto(doc.uid),
        ref.read(authRepositoryProvider).updatePhotoUrl(null),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus foto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Save profile info ────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final doc = ref.read(currentUserDocProvider).value;
    if (doc == null) return;

    setState(() => _saving = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      await authRepo.updateDisplayName(_nameCtrl.text.trim());
      await userRepo.updateProfile(
        uid: doc.uid,
        name: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      // ── Auto-generate username untuk akun lama yang belum punya username ──
      if (doc.username == null || doc.username!.isEmpty) {
        final username = await userRepo.generateUniqueUsername(doc.name);
        // Simpan ke field username di dokumen user
        await userRepo.updateUsername(uid: doc.uid, username: username);
        // Simpan index ke koleksi /usernames
        await userRepo.saveUsername(username, doc.uid, doc.email);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final auth      = ref.watch(currentUserProvider);
    final userAsync = ref.watch(currentUserDocProvider);
    // Gunakan HANYA Firestore sebagai sumber foto — jangan fallback ke
    // auth?.photoURL karena Firebase Auth bisa cache URL lama setelah dihapus.
    final photoUrl  = userAsync.value?.photoUrl;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: const Text('Edit Profil',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Simpan',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar with change button ────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _uploadingPhoto ? null : _changePhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: _uploadingPhoto
                              ? Container(
                                  color: cs.primaryContainer,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : photoUrl != null
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _AvatarFallback(
                                              initial: _nameCtrl.text,
                                              cs: cs),
                                    )
                                  : _AvatarFallback(
                                      initial: _nameCtrl.text, cs: cs),
                        ),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const SizedBox(height: 8),

            // Tap to change/delete label
            if (photoUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _uploadingPhoto ? null : _changePhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      _uploadingPhoto ? 'Mengunggah...' : 'Ganti Foto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _uploadingPhoto ? null : _deletePhoto,
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text(
                      'Hapus Foto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: TextButton.icon(
                  onPressed: _uploadingPhoto ? null : _changePhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: Text(
                    _uploadingPhoto ? 'Mengunggah...' : 'Tambah Foto Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── Email (read-only) ────────────────────────────────────────
            _SectionLabel(label: 'Email'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 18,
                      color: cs.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 10),
                  Text(
                    auth?.email ?? '',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Username (read-only, auto-generated) ─────────────────────
            _SectionLabel(label: 'Username'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.alternate_email_rounded, size: 18,
                      color: cs.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: userAsync.value?.username != null
                        ? Text(
                            '@${userAsync.value!.username}',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.55),
                                fontSize: 15),
                          )
                        : Text(
                            'Akan dibuat otomatis saat menyimpan profil',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.35),
                                fontSize: 13,
                                fontStyle: FontStyle.italic),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Name ────────────────────────────────────────────────────
            _SectionLabel(label: 'Nama Lengkap'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
              decoration: _inputDecor(context,
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded),
            ),

            const SizedBox(height: 20),

            // ── Phone ────────────────────────────────────────────────────
            _SectionLabel(label: 'Nomor Telepon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecor(context,
                  hint: 'Contoh: 081234567890',
                  icon: Icons.phone_outlined),
            ),

            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Perubahan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial, required this.cs});
  final String initial;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial.isNotEmpty ? initial[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: cs.primary,
        ),
      ),
    );
  }
}

InputDecoration _inputDecor(BuildContext context,
    {required String hint, required IconData icon}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: cs.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 0.3,
      ),
    );
  }
}
