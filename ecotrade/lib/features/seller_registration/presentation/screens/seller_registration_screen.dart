
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

// ─────────────────────────────────────────────────────────────────────────────
// Daftar Bank Indonesia
// ─────────────────────────────────────────────────────────────────────────────
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

  // KYC — Nama sesuai KTP
  final _ktpNameController = TextEditingController();

  // KYC — Data Bank
  String? _selectedBank;
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  String? _selectedCommodity;
  XFile? _commodityImage;
  Uint8List? _commodityImageBytes;

  // KYC — Foto KTP & Selfie
  XFile? _ktpImage;
  Uint8List? _ktpImageBytes;
  XFile? _selfieImage;
  Uint8List? _selfieImageBytes;

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
    _ktpNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
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

  Future<void> _pickKtpImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _ktpImage = pickedFile;
          _ktpImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto KTP: $e')),
        );
      }
    }
  }

  Future<void> _pickSelfieImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selfieImage = pickedFile;
          _selfieImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto selfie: $e')),
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

    // ── Validasi foto KTP ───────────────────────────────────────────────────
    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap upload foto KTP Anda'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // ── Validasi foto selfie + KTP ──────────────────────────────────────────
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap upload foto selfie bersama KTP'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // ── Validasi bank ───────────────────────────────────────────────────────
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih nama bank terlebih dahulu'),
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
          ktpImage: _ktpImage!,
          selfieImage: _selfieImage!,
          ktpName: _ktpNameController.text.trim(),
          bankName: _selectedBank!,
          bankAccountName: _accountNameController.text.trim(),
          bankAccountNumber: _accountNumberController.text.trim(),
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
              label: 'UNGGAH FOTO PRODUK',
              hint: 'Tap untuk memilih gambar',
              icon: Icons.add_photo_alternate_rounded,
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

            // ════════════════════════════════════════════════════════════════
            // ── SECTION: Verifikasi Identitas (KYC) ─────────────────────────
            // ════════════════════════════════════════════════════════════════
            _SectionDivider(
              icon: Icons.badge_outlined,
              title: 'Verifikasi Identitas',
              subtitle: 'Wajib untuk keamanan pencairan dana',
              color: colorScheme.primary,
            ),

            const SizedBox(height: 20),

            // ── Info Banner KYC ──────────────────────────────────────────
            _KycInfoBanner(colorScheme: colorScheme, textTheme: textTheme),

            const SizedBox(height: 20),

            // ── Nama sesuai KTP ──────────────────────────────────────────
            _FormLabel(label: 'NAMA LENGKAP (SESUAI KTP)'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _ktpNameController,
              hint: 'Nama lengkap sesuai KTP',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama sesuai KTP wajib diisi';
                }
                if (value.trim().length < 3) {
                  return 'Nama terlalu pendek';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Foto KTP ─────────────────────────────────────────────────
            Row(
              children: [
                _FormLabel(label: 'FOTO KTP'),
                const SizedBox(width: 8),
                _RequiredBadge(colorScheme: colorScheme, textTheme: textTheme),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan foto KTP jelas, tidak blur, dan semua teks terbaca.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            _ImageUploadBox(
              imageBytes: _ktpImageBytes,
              onTap: _pickKtpImage,
              label: 'UPLOAD FOTO KTP',
              hint: 'Ketuk untuk memilih foto KTP',
              icon: Icons.credit_card_rounded,
              accentColor: colorScheme.tertiary,
            ),

            const SizedBox(height: 20),

            // ── Foto Selfie + KTP ────────────────────────────────────────
            Row(
              children: [
                _FormLabel(label: 'FOTO SELFIE + KTP'),
                const SizedBox(width: 8),
                _RequiredBadge(colorScheme: colorScheme, textTheme: textTheme),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Foto wajah Anda sambil memegang KTP. Wajah dan teks KTP harus terlihat jelas.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            _ImageUploadBox(
              imageBytes: _selfieImageBytes,
              onTap: _pickSelfieImage,
              label: 'UPLOAD FOTO SELFIE + KTP',
              hint: 'Ketuk untuk memilih foto selfie',
              icon: Icons.face_rounded,
              accentColor: const Color(0xFF7B5EA7),
            ),

            const SizedBox(height: 32),

            // ════════════════════════════════════════════════════════════════
            // ── SECTION: Data Rekening Bank ──────────────────────────────────
            // ════════════════════════════════════════════════════════════════
            _SectionDivider(
              icon: Icons.account_balance_rounded,
              title: 'Data Rekening Bank',
              subtitle: 'Untuk pencairan dana hasil penjualan',
              color: const Color(0xFF2E7D32),
            ),

            const SizedBox(height: 20),

            // ── Info Bank ────────────────────────────────────────────────
            _BankInfoBanner(colorScheme: colorScheme, textTheme: textTheme),

            const SizedBox(height: 20),

            // ── Pilih Bank ───────────────────────────────────────────────
            _FormLabel(label: 'NAMA BANK'),
            const SizedBox(height: 8),
            _BankDropdown(
              value: _selectedBank,
              onChanged: (v) => setState(() => _selectedBank = v),
            ),

            const SizedBox(height: 16),

            // ── Nomor Rekening ───────────────────────────────────────────
            _FormLabel(label: 'NOMOR REKENING'),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _accountNumberController,
              hint: 'Contoh: 1234567890',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor rekening wajib diisi';
                }
                if (value.trim().length < 6) {
                  return 'Nomor rekening tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Nama Pemilik Rekening ────────────────────────────────────
            _FormLabel(label: 'NAMA PEMILIK REKENING'),
            const SizedBox(height: 4),
            Text(
              'Harus sama persis dengan nama pada KTP di atas',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _CustomTextField(
              controller: _accountNameController,
              hint: 'Nama sesuai buku tabungan / aplikasi bank',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pemilik rekening wajib diisi';
                }
                // Peringatan jika nama berbeda dengan nama KTP
                final ktpName = _ktpNameController.text.trim().toLowerCase();
                final accName = value.trim().toLowerCase();
                if (ktpName.isNotEmpty && !accName.contains(ktpName.split(' ').first)) {
                  return 'Nama pemilik rekening tidak cocok dengan nama KTP';
                }
                return null;
              },
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
                            'Daftar & Kirim Verifikasi',
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
// Section Divider
// ─────────────────────────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.7),
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

// ─────────────────────────────────────────────────────────────────────────────
// KYC Info Banner
// ─────────────────────────────────────────────────────────────────────────────
class _KycInfoBanner extends StatelessWidget {
  const _KycInfoBanner({required this.colorScheme, required this.textTheme});
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mengapa perlu KTP?',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verifikasi KTP memastikan identitas Anda asli dan melindungi keamanan dana hasil penjualan. Data Anda akan dijaga kerahasiaannya.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
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

// ─────────────────────────────────────────────────────────────────────────────
// Bank Info Banner
// ─────────────────────────────────────────────────────────────────────────────
class _BankInfoBanner extends StatelessWidget {
  const _BankInfoBanner({required this.colorScheme, required this.textTheme});
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_rounded,
              color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama rekening HARUS sama dengan nama KTP',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin akan memverifikasi kecocokan nama KTP dan nama pemilik rekening. Pendaftaran akan ditolak jika tidak sama.',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.75),
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

// ─────────────────────────────────────────────────────────────────────────────
// Required Badge
// ─────────────────────────────────────────────────────────────────────────────
class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.colorScheme, required this.textTheme});
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'WAJIB',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _BankDropdown extends StatelessWidget {
  const _BankDropdown({required this.value, required this.onChanged});
  final String? value;
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
        value: value,
        isExpanded: true,
        hint: Text(
          'Pilih nama bank',
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
        validator: (v) => v == null ? 'Pilih bank terlebih dahulu' : null,
        items: _bankIndonesiaList.map((bank) {
          return DropdownMenuItem<String>(
            value: bank,
            child: Text(bank, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
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
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
// Image Upload Box (reusable)
// ─────────────────────────────────────────────────────────────────────────────
class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.imageBytes,
    required this.onTap,
    required this.label,
    required this.hint,
    required this.icon,
    this.accentColor,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final String label;
  final String hint;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = accentColor ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageBytes != null
                ? color.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: imageBytes != null ? 2 : 1.5,
          ),
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
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
                    child: Image.memory(imageBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
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
                  // Checkmark overlay
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
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
            suffixText: suffix,
            suffixStyle: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kota Card
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (provinsi.isNotEmpty)
                    Text(
                      provinsi,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (isOther)
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Kota Lainnya
// ─────────────────────────────────────────────────────────────────────────────
class _SellerKotaDropdown extends StatelessWidget {
  const _SellerKotaDropdown({
    required this.selectedKota,
    required this.onChanged,
  });

  final String? selectedKota;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedKota,
        hint: Text(
          'Pilih kota di Jawa Timur',
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
        items: _kotaJawaTimurSeller.map((kota) {
          return DropdownMenuItem<String>(
            value: kota,
            child: Text(kota),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
