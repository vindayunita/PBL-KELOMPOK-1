import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Handles picking a photo from gallery or camera and uploading it to
/// Firebase Storage under `profile_photos/{uid}.jpg`.
class ProfilePhotoService {
  ProfilePhotoService._();

  static final _picker = ImagePicker();
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Picks an image (gallery or camera) and returns the raw bytes.
  /// Returns null if the user cancels.
  static Future<Uint8List?> pickImage(BuildContext context) async {
    ImageSource? source;

    // Show bottom-sheet to choose source
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Ganti Foto Profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDDE8FF),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFF4A7AFF)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  source = ImageSource.gallery;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD4F5E2),
                  child: Icon(Icons.camera_alt_outlined, color: Color(0xFF27AE60)),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  source = ImageSource.camera;
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    final xFile = await _picker.pickImage(
      source: source!,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (xFile == null) return null;

    final bytes = await xFile.readAsBytes();
    if (bytes.length > _maxFileSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file terlalu besar. Maks 5 MB.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
    return bytes;
  }

  /// Uploads [bytes] to Firebase Storage at `profile_photos/{uid}.jpg`
  /// and returns the public download URL.
  static Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}
