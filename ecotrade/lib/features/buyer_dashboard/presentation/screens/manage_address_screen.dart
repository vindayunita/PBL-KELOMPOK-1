import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/user/data/user_repository.dart';
import '../../../../features/user/domain/user_providers.dart';

class ManageAddressScreen extends ConsumerWidget {
  const ManageAddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        elevation: 0,
        title: const Text('Alamat Saya',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(context, ref, null, -1),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Alamat',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          final addresses = user?.addresses ?? [];
          if (addresses.isEmpty) {
            return const _EmptyAddressState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: addresses.length,
            itemBuilder: (ctx, i) {
              final addr = addresses[i];
              return _AddressCard(
                address: addr,
                onEdit: () => _showAddressSheet(context, ref, addr, i),
                onDelete: () => _deleteAddress(context, ref, user!.uid, addresses, i),
                onSetDefault: addr['isDefault'] == true
                    ? null
                    : () => _setDefault(ref, user!.uid, addresses, i),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, WidgetRef ref,
      String uid, List<Map<String, dynamic>> addresses, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: const Text('Alamat ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    final updated = [...addresses]..removeAt(index);
    // Jika yang dihapus adalah default dan masih ada alamat lain, set yang pertama jadi default
    if (addresses[index]['isDefault'] == true && updated.isNotEmpty) {
      updated[0] = {...updated[0], 'isDefault': true};
    }
    await ref.read(userRepositoryProvider).updateAddresses(uid, updated);
  }

  Future<void> _setDefault(WidgetRef ref, String uid,
      List<Map<String, dynamic>> addresses, int index) async {
    final updated = addresses
        .asMap()
        .entries
        .map((e) => {...e.value, 'isDefault': e.key == index})
        .toList();
    await ref.read(userRepositoryProvider).updateAddresses(uid, updated);
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref,
      Map<String, dynamic>? existing, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        ref: ref,
        existing: existing,
        index: index,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_outlined,
                size: 38, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text('Belum ada alamat',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Tambahkan alamat pengiriman Anda',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address Card
// ─────────────────────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  final Map<String, dynamic> address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDefault = address['isDefault'] == true;
    final label   = address['label']      as String? ?? 'Alamat';
    final detail  = address['detail']     as String? ?? '';
    final city    = address['city']       as String? ?? '';
    final postal  = address['postalCode'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(color: const Color(0xFF27AE60), width: 1.5)
            : Border.all(color: cs.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: const TextStyle(
                        color: Color(0xFF27AE60),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              if (isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Utama',
                      style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    size: 18, color: cs.error),
                visualDensity: VisualDensity.compact,
                tooltip: 'Hapus',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(detail,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface, height: 1.4)),
          if (city.isNotEmpty || postal.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [if (city.isNotEmpty) city, if (postal.isNotEmpty) postal]
                  .join(', '),
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
          if (onSetDefault != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSetDefault,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radio_button_unchecked_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Jadikan Alamat Utama',
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address Form Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({
    required this.ref,
    required this.existing,
    required this.index,
  });

  final WidgetRef ref;
  final Map<String, dynamic>? existing;
  final int index;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedLabel;
  late final TextEditingController _detailCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late bool _isDefault;
  bool _saving = false;

  static const _labels = ['Rumah', 'Kantor', 'Kos', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedLabel = e?['label'] as String? ?? 'Rumah';
    _detailCtrl = TextEditingController(text: e?['detail'] as String? ?? '');
    _cityCtrl   = TextEditingController(text: e?['city']   as String? ?? '');
    _postalCtrl = TextEditingController(text: e?['postalCode'] as String? ?? '');
    _isDefault  = e?['isDefault'] as bool? ?? false;
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = widget.ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = widget.ref.read(userRepositoryProvider);
      final addresses = List<Map<String, dynamic>>.from(user.addresses);

      final newAddr = {
        'id': widget.existing?['id'] as String? ??
            '${DateTime.now().millisecondsSinceEpoch}',
        'label':      _selectedLabel,
        'detail':     _detailCtrl.text.trim(),
        'city':       _cityCtrl.text.trim(),
        'postalCode': _postalCtrl.text.trim(),
        'isDefault':  _isDefault,
      };

      // Jika set sebagai default, reset semua isDefault dulu
      List<Map<String, dynamic>> updated;
      if (_isDefault) {
        updated = addresses
            .map((a) => {...a, 'isDefault': false})
            .toList();
      } else {
        updated = List.from(addresses);
      }

      if (widget.index >= 0) {
        updated[widget.index] = newAddr;
      } else {
        // Jika ini alamat pertama, otomatis jadikan default
        if (updated.isEmpty) {
          updated.add({...newAddr, 'isDefault': true});
        } else {
          updated.add(newAddr);
        }
      }

      await repo.updateAddresses(user.uid, updated);

      if (mounted) Navigator.of(context).pop();
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
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(isEdit ? 'Edit Alamat' : 'Tambah Alamat',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),

              // Label
              Text('Label', style: _labelStyle(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _labels.map((l) {
                  final selected = _selectedLabel == l;
                  return ChoiceChip(
                    label: Text(l),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedLabel = l),
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Detail
              Text('Detail Alamat', style: _labelStyle(context)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailCtrl,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Alamat tidak boleh kosong' : null,
                decoration: InputDecoration(
                  hintText: 'Jl. Merdeka No. 1, RT 01/RW 02...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // City & Postal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kota/Kab.', style: _labelStyle(context)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cityCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi' : null,
                          decoration: InputDecoration(
                            hintText: 'Jakarta',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kode Pos', style: _labelStyle(context)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _postalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '12345',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Jadikan Alamat Utama',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Alamat ini akan digunakan sebagai default'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
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
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Alamat',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.6),
      );
}
