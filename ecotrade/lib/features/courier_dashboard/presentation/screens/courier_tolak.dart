import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model alasan penolakan
// ─────────────────────────────────────────────────────────────────────────────
class _RejectReason {
  const _RejectReason({
    required this.label,
    required this.icon,
  });
  final String label;
  final IconData icon;
}

const _kReasons = [
  _RejectReason(label: 'Cuaca Buruk', icon: Icons.thunderstorm_outlined),
  _RejectReason(label: 'Lokasi Terlalu Jauh', icon: Icons.location_off_outlined),
  _RejectReason(label: 'Lainnya', icon: Icons.more_horiz_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper — tampilkan bottom sheet, kembalikan alasan yang dipilih atau null
// ─────────────────────────────────────────────────────────────────────────────
Future<String?> showTolakTugasSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TolakTugasSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────
class _TolakTugasSheet extends StatefulWidget {
  const _TolakTugasSheet();

  @override
  State<_TolakTugasSheet> createState() => _TolakTugasSheetState();
}

class _TolakTugasSheetState extends State<_TolakTugasSheet> {
  int? _selectedIndex;
  final _otherController = TextEditingController();
  final _otherFocus = FocusNode();

  // index Lainnya selalu yang terakhir
  static const _lainnyaIndex = 2;

  bool get _isLainnya => _selectedIndex == _lainnyaIndex;

  @override
  void dispose() {
    _otherController.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  String? get _submitReason {
    if (_selectedIndex == null) return null;
    if (_isLainnya) {
      final text = _otherController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _kReasons[_selectedIndex!].label;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Header row ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan Penolakan',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Subtitle ──────────────────────────────────────────────────
              Text(
                'Berikan alasan Anda menolak pesanan ini\nuntuk membantu kami menyesuaikan jadwal Anda.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // ── Reason list ───────────────────────────────────────────────
              ...List.generate(_kReasons.length, (i) {
                final reason = _kReasons[i];
                final selected = _selectedIndex == i;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      _ReasonTile(
                        icon: reason.icon,
                        label: reason.label,
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          if (i == _lainnyaIndex) {
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () => _otherFocus.requestFocus(),
                            );
                          }
                        },
                      ),
                      // TextField muncul di bawah tile Lainnya
                      if (i == _lainnyaIndex)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: _isLainnya
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _OtherTextField(
                                    controller: _otherController,
                                    focusNode: _otherFocus,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitReason == null
                      ? null
                      : () => Navigator.of(context).pop(_submitReason),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor:
                        cs.primary.withOpacity(0.35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'SUBMIT',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Batal ─────────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'BATAL',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.45),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reason Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withOpacity(0.07)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),

            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Other Text Field  (shown when "Lainnya" is selected)
// ─────────────────────────────────────────────────────────────────────────────
class _OtherTextField extends StatelessWidget {
  const _OtherTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: 3,
      minLines: 2,
      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: 'Tuliskan alasan lainnya…',
        hintStyle: tt.bodyMedium?.copyWith(
          color: cs.onSurface.withOpacity(0.4),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: cs.outlineVariant.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}
