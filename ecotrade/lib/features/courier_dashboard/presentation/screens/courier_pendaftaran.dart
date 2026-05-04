import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'courier_unggah.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Area Kerja model
// ─────────────────────────────────────────────────────────────────────────────
class _AreaKerja {
  const _AreaKerja({
    required this.nama,
    required this.provinsi,
    this.isOther = false,
  });
  final String nama;
  final String provinsi;
  final bool isOther;
}

const _areaList = [
  _AreaKerja(nama: 'Malang',  provinsi: 'Jawa Timur [Provinsi]'),
  _AreaKerja(nama: 'Surabaya',     provinsi: 'Jawa Timur [Provinsi]'),
  _AreaKerja(nama: 'Jember',       provinsi: 'Jawa Timur [Provinsi]'),
  _AreaKerja(nama: 'Area Lainnya', provinsi: 'Pilih kota di Jawa Timur', isOther: true),
];

// Daftar kota/kabupaten di Jawa Timur
const _kotaJawaTimur = [
  'Bangkalan',
  'Banyuwangi',
  'Blitar',
  'Bojonegoro',
  'Bondowoso',
  'Gresik',
  'Jombang',
  'Kediri',
  'Kota Batu',
  'Kota Blitar',
  'Kota Kediri',
  'Kota Madiun',
  'Kota Mojokerto',
  'Kota Pasuruan',
  'Kota Probolinggo',
  'Lamongan',
  'Lumajang',
  'Madiun',
  'Magetan',
  'Mojokerto',
  'Nganjuk',
  'Ngawi',
  'Pacitan',
  'Pamekasan',
  'Pasuruan',
  'Ponorogo',
  'Probolinggo',
  'Sampang',
  'Sidoarjo',
  'Situbondo',
  'Sumenep',
  'Trenggalek',
  'Tuban',
  'Tulungagung',
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierPendaftaranScreen extends ConsumerStatefulWidget {
  const CourierPendaftaranScreen({super.key});

  @override
  ConsumerState<CourierPendaftaranScreen> createState() =>
      _CourierPendaftaranScreenState();
}

class _CourierPendaftaranScreenState
    extends ConsumerState<CourierPendaftaranScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _namaCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _teleponCtrl = TextEditingController();

  int  _selectedArea    = 0;
  bool _agreedToTerms   = false;
  bool _isSubmitting    = false;
  String? _selectedKota; // Kota yang dipilih untuk "Area Lainnya"

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap setujui syarat & ketentuan terlebih dahulu.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    // Lanjut ke halaman unggah dokumen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CourierUnggahScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest,
              elevation: 0,
              floating: true,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sync_rounded,
                        color: cs.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EcoTrade',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Section ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PELUANG KARIR',
                            style: tt.labelSmall?.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'Menjadi Kurir',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Masa Depan.',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle
                        Text(
                          'Bergabunglah dengan armada kurir ramah lingkungan kami dan bantu mewujudkan ekosistem perdagangan berkelanjutan.',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Illustration card
                        Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF34D399),
                                  Color(0xFF10B981),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form Section ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formulir Pendaftaran',
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // NAMA LENGKAP
                          _FieldLabel(label: 'NAMA LENGKAP'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _namaCtrl,
                            hint: 'Masukkan nama sesuai KTP',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                          ),

                          const SizedBox(height: 20),

                          // EMAIL
                          _FieldLabel(label: 'ALAMAT EMAIL'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _emailCtrl,
                            hint: 'contoh@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              final emailRegex = RegExp(
                                  r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d.\-]+$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // NOMOR HP
                          _FieldLabel(label: 'NOMOR HP'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _teleponCtrl,
                            hint: '+62 812 XXXX XXXX',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nomor HP wajib diisi'
                                : null,
                          ),

                          const SizedBox(height: 24),

                          // PILIH AREA KERJA
                          _FieldLabel(label: 'PILIH AREA KERJA'),
                          const SizedBox(height: 10),

                          ...List.generate(_areaList.length, (i) {
                            final area = _areaList[i];
                            final selected = _selectedArea == i;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AreaCard(
                                  area: area,
                                  selected: selected,
                                  onTap: () => setState(() {
                                    _selectedArea = i;
                                    if (!area.isOther) _selectedKota = null;
                                  }),
                                ),
                                // Dropdown kota Jawa Timur muncul saat "Area Lainnya" dipilih
                                if (area.isOther && selected)
                                  _KotaDropdown(
                                    selectedKota: _selectedKota,
                                    onChanged: (kota) =>
                                        setState(() => _selectedKota = kota),
                                  ),
                              ],
                            );
                          }),

                          const SizedBox(height: 20),

                          // Terms
                          GestureDetector(
                            onTap: () => setState(
                                () => _agreedToTerms = !_agreedToTerms),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (v) => setState(
                                        () => _agreedToTerms = v ?? false),
                                    shape: const CircleBorder(),
                                    activeColor: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.6),
                                        height: 1.5,
                                      ),
                                      children: [
                                        const TextSpan(
                                            text: 'Saya menyetujui '),
                                        TextSpan(
                                          text: 'Syarat & Ketentuan',
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ' yang berlaku serta kebijakan privasi penggunaan data kurir EcoTrade.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded,
                                      size: 20),
                              label: Text(
                                'Daftar & Unggah Dokumen',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Info note
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Langkah selanjutnya: Verifikasi dokumen identitas (KTP/SIM) wajib dilakukan.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.45),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Center(
                            child: Text(
                              '© 2024 ECOTRADE COURIER INITIATIVE',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.3),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Label
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text(
      label,
      style: tt.labelSmall?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Field
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: tt.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(icon,
            size: 20, color: cs.onSurface.withValues(alpha: 0.45)),
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Area Kerja Card
// ─────────────────────────────────────────────────────────────────────────────
class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  final _AreaKerja area;
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              area.isOther
                  ? Icons.more_horiz_rounded
                  : Icons.location_on_outlined,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.nama,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? cs.primary
                          : cs.onSurface,
                    ),
                  ),
                  Text(
                    area.provinsi,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Kota Jawa Timur (muncul saat "Area Lainnya" dipilih)
// ─────────────────────────────────────────────────────────────────────────────
class _KotaDropdown extends StatelessWidget {
  const _KotaDropdown({
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
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.primary, size: 22),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          ),
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          items: _kotaJawaTimur.map((kota) {
            return DropdownMenuItem<String>(
              value: kota,
              child: Text(kota),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) =>
              v == null ? 'Harap pilih kota / kabupaten' : null,
        ),
      ),
    );
  }
}
