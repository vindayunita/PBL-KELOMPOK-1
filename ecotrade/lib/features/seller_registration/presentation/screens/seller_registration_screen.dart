
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/seller_registration_controller.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daftar kota pilihan (preset) untuk seller
// ─────────────────────────────────────────────────────────────────────────────
class _KotaPreset {
  const _KotaPreset({required this.nama, required this.provinsi, this.isOther = false});
  final String nama;
  final String provinsi;
  final bool isOther;
}

const _kotaPresetList = [
  _KotaPreset(nama: 'Malang',       provinsi: 'Jawa Timur'),
  _KotaPreset(nama: 'Surabaya',     provinsi: 'Jawa Timur'),
  _KotaPreset(nama: 'Jember',       provinsi: 'Jawa Timur'),
  _KotaPreset(nama: 'Kota Lainnya', provinsi: 'Pilih kota di Jawa Timur', isOther: true),
];

const _kotaJawaTimurSeller = [
  'Bangkalan', 'Banyuwangi', 'Blitar', 'Bojonegoro', 'Bondowoso',
  'Gresik', 'Jombang', 'Kediri', 'Kota Batu', 'Kota Blitar',
  'Kota Kediri', 'Kota Madiun', 'Kota Mojokerto', 'Kota Pasuruan',
  'Kota Probolinggo', 'Lamongan', 'Lumajang', 'Madiun', 'Magetan',
  'Mojokerto', 'Nganjuk', 'Ngawi', 'Pacitan', 'Pamekasan', 'Pasuruan',
  'Ponorogo', 'Probolinggo', 'Sampang', 'Sidoarjo', 'Situbondo',
  'Sumenep', 'Trenggalek', 'Tuban', 'Tulungagung',
];

class SellerRegistrationScreen extends ConsumerStatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  ConsumerState<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState
    extends ConsumerState<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _productNameController = TextEditingController();
  final _commodityDescController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCommodity;
  XFile? _commodityImage;
  Uint8List? _commodityImageBytes;
  final _imagePicker = ImagePicker();

  // Pilih kota
  int _selectedKotaPreset = 0;
  String? _selectedKotaLain;

  // Commodity options
  final List<String> _commodityOptions = [
    'Serat Alami',
    'Biomassa & Energi',
    'Pupuk & Pertanian',
    'Bahan Industri',
    'Lainnya',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _productNameController.dispose();
    _commodityDescController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? get _resolvedCity {
    final preset = _kotaPresetList[_selectedKotaPreset];
    if (preset.isOther) return _selectedKotaLain;
    return preset.nama;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _commodityImage = pickedFile;
          _commodityImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // ── Blokir jika sudah menjadi Courier aktif ─────────────────────────────
    final courierApp = ref.read(myCourierApplicationProvider).value;
    if (courierApp != null && courierApp.isApproved) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tidak Dapat Mendaftar',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Akun Anda sudah terdaftar sebagai Kurir aktif. '
            'Satu akun tidak dapat menjadi Kurir dan Seller secara bersamaan.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedCommodity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis komoditi terlebih dahulu')),
      );
      return;
    }

    // Validasi kota
    final preset = _kotaPresetList[_selectedKotaPreset];
    if (preset.isOther && (_selectedKotaLain == null || _selectedKotaLain!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih kota terlebih dahulu'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Submit to controller
    ref.read(sellerRegistrationControllerProvider.notifier).submitRegistration(
          businessName: _businessNameController.text.trim(),
          productName: _productNameController.text.trim(),
          address: _addressController.text.trim(),
          commodityType: _selectedCommodity!,
          commodityDescription: _commodityDescController.text.trim(),
          stock: int.parse(_stockController.text.trim()),
          pricePerKg: double.parse(_priceController.text.trim()),
          city: _resolvedCity,
          commodityImage: _commodityImage,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Listen to controller state
    ref.listen<AsyncValue<void>>(
      sellerRegistrationControllerProvider,
      (_, state) {
        state.whenOrNull(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pendaftaran berhasil! Menunggu verifikasi admin.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mendaftar: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
    );

    final isLoading =
        ref.watch(sellerRegistrationControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'REGISTRATION FLOW',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ────────────────────────────────────────────────────
            Text(
              'Bisnis Marketplace',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              'Siapkan profil bisnis Anda untuk mulai melakukan perdagangan komoditi berkelanjutan di ekosistem EcoTrade.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // ── Business Name ────────────────────────────────────────────
            _FormLabel(label: 'Nama Bisnis'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _businessNameController,
              hint: 'Nama bisnis',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama bisnis wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Commodity Type ───────────────────────────────────────────
            _FormLabel(label: 'Jenis Komoditi'),
            const SizedBox(height: 8),
            _CommodityDropdown(
              value: _selectedCommodity,
              items: _commodityOptions,
              onChanged: (value) {
                setState(() {
                  _selectedCommodity = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // ── Pilih Kota ───────────────────────────────────────────────
            _FormLabel(label: 'Kota / Lokasi Bisnis'),
            const SizedBox(height: 10),
            ...List.generate(_kotaPresetList.length, (i) {
              final kota = _kotaPresetList[i];
              final selected = _selectedKotaPreset == i;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SellerKotaCard(
                    nama: kota.nama,
                    provinsi: kota.provinsi,
                    isOther: kota.isOther,
                    selected: selected,
                    onTap: () => setState(() {
                      _selectedKotaPreset = i;
                      if (!kota.isOther) _selectedKotaLain = null;
                    }),
                  ),
                  if (kota.isOther && selected)
                    _SellerKotaDropdown(
                      selectedKota: _selectedKotaLain,
                      onChanged: (v) => setState(() => _selectedKotaLain = v),
                    ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ── Address ──────────────────────────────────────────────────
            _FormLabel(label: 'Deskripsi Bisnis'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _addressController,
              hint: 'Jelaskan visi dan lokasi bisnis Anda...',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi bisnis wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Commodity Photo ──────────────────────────────────────────
            Row(
              children: [
                _FormLabel(label: 'Foto Komoditi'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'OPSIONAL',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ImageUploadBox(
              imageBytes: _commodityImageBytes,
              onTap: _pickImage,
            ),

            const SizedBox(height: 24),

            // ── Nama Produk ─────────────────────────────────────────────
            _FormLabel(label: 'NAMA PRODUK'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _productNameController,
              hint: 'Contoh: Serat Eceng Gondok Kering Grade A',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama produk wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Commodity Description ────────────────────────────────────
            _FormLabel(label: 'Deskripsi Komoditi'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _commodityDescController,
              hint: 'Kualitas, grade, atau spesifikasi',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi komoditi wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Stock & Price ────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormLabel(label: 'STOK TERSEDIA'),
                      const SizedBox(height: 8),
                      _NumberInputField(
                        controller: _stockController,
                        hint: '24',
                        suffix: 'Kg',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Harus angka';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormLabel(label: 'HARGA'),
                      const SizedBox(height: 8),
                      _NumberInputField(
                        controller: _priceController,
                        hint: '8.500',
                        suffix: 'Satuan Per Kg',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harus angka';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Submit Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor:
                      colorScheme.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              size: 20, color: colorScheme.onPrimary),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Label
// ─────────────────────────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      label,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Commodity Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _CommodityDropdown extends StatelessWidget {
  const _CommodityDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(
          'Pilih jenis komoditi',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.6)),
        dropdownColor: colorScheme.surface,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Upload Box
// ─────────────────────────────────────────────────────────────────────────────
class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.imageBytes,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageBytes != null
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: imageBytes != null ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UNGGAH FOTO PRODUK',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk memilih gambar',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Overlay: ganti foto
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Ganti Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
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
// Number Input Field with +/- buttons
// ─────────────────────────────────────────────────────────────────────────────
class _NumberInputField extends StatelessWidget {
  const _NumberInputField({
    required this.controller,
    required this.hint,
    required this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Suffix label
        Text(
          suffix,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seller Kota Card
// ─────────────────────────────────────────────────────────────────────────────
class _SellerKotaCard extends StatelessWidget {
  const _SellerKotaCard({
    required this.nama,
    required this.provinsi,
    required this.isOther,
    required this.selected,
    required this.onTap,
  });

  final String nama;
  final String provinsi;
  final bool isOther;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOther ? Icons.more_horiz_rounded : Icons.location_on_outlined,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  Text(
                    provinsi,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seller Kota Dropdown (muncul saat "Kota Lainnya" dipilih)
// ─────────────────────────────────────────────────────────────────────────────
class _SellerKotaDropdown extends StatelessWidget {
  const _SellerKotaDropdown({
    required this.selectedKota,
    required this.onChanged,
  });

  final String? selectedKota;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: selectedKota,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.primary, size: 22),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_city_outlined,
                size: 20, color: cs.primary.withValues(alpha: 0.7)),
            hintText: 'Pilih kota / kabupaten',
            hintStyle: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          ),
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          items: _kotaJawaTimurSeller.map((kota) {
            return DropdownMenuItem<String>(
              value: kota,
              child: Text(kota),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Harap pilih kota / kabupaten' : null,
        ),
      ),
    );
  }
}
