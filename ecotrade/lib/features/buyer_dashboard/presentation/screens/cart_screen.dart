import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cart_item_model.dart';
import '../../data/cart_repository.dart';
import 'checkout_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart Screen
// ─────────────────────────────────────────────────────────────────────────────

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Tracks which item IDs are checked. We only auto-add IDs for items that are
  // *new* (not yet known). Removing a check must not be overridden on rebuild.
  final Set<String> _selectedIds = {};
  final Set<String> _knownIds = {}; // IDs we have already processed
  bool _selectAll = true;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  /// Called once per build with current item list.
  /// Only auto-selects IDs that are genuinely new (first time seen).
  void _handleNewItems(List<CartItemModel> items) {
    final newIds = items.map((i) => i.id).toSet().difference(_knownIds);
    if (newIds.isNotEmpty) {
      _knownIds.addAll(newIds);
      _selectedIds.addAll(newIds); // select newly added items by default
    }
    // Clean up stale IDs (items removed from Firestore)
    final currentIds = items.map((i) => i.id).toSet();
    _knownIds.removeWhere((id) => !currentIds.contains(id));
    _selectedIds.removeWhere((id) => !currentIds.contains(id));
  }

  void _syncSelectAll(List<CartItemModel> items) {
    if (items.isEmpty) return;
    final allSelected = items.every((i) => _selectedIds.contains(i.id));
    if (_selectAll != allSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectAll = allSelected);
      });
    }
  }

  void _toggleSelectAll(List<CartItemModel> items, bool value) {
    setState(() {
      _selectAll = value;
      if (value) {
        _selectedIds.addAll(items.map((i) => i.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  double _subtotal(List<CartItemModel> items) => items
      .where((i) => _selectedIds.contains(i.id))
      .fold(0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final itemsAsync = ref.watch(cartItemsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          // Auto-select only NEW items, preserve manual deselects
          _handleNewItems(items);
          _syncSelectAll(items);

          final selectedItems =
              items.where((i) => _selectedIds.contains(i.id)).toList();
          final subtotal = _subtotal(items);
          final total = subtotal; // no handling fee

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // ── App Bar ─────────────────────────────────────────────
                    SliverToBoxAdapter(child: _buildHeader(cs, tt)),

                    // ── Empty State ──────────────────────────────────────────
                    if (items.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyCart(cs: cs, tt: tt),
                      )
                    else ...[
                      // ── Select All row ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildSelectAllRow(items, cs, tt),
                      ),

                      // ── Cart Items ─────────────────────────────────────────
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _CartItemTile(
                            item: items[i],
                            isSelected: _selectedIds.contains(items[i].id),
                            cs: cs,
                            tt: tt,
                            onToggle: (v) => setState(() {
                              if (v) {
                                _selectedIds.add(items[i].id);
                              } else {
                                _selectedIds.remove(items[i].id);
                              }
                            }),
                            onQtyChanged: (qty) => ref
                                .read(cartRepositoryProvider)
                                .updateQuantity(items[i].id, qty),
                            onRemove: () => ref
                                .read(cartRepositoryProvider)
                                .removeItem(items[i].id),
                            fmt: _fmt,
                          ),
                          childCount: items.length,
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ],
                ),
              ),

              // ── Checkout Button ────────────────────────────────────────────
              if (items.isNotEmpty)
                _buildCheckoutBar(context, cs, tt,
                    selectedCount: selectedItems.length,
                    total: total,
                    selectedItems: selectedItems),
            ],
          );
        },
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR SELECTION',
              style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text('Review Your\nTrade Cart',
              style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.15,
                  letterSpacing: -0.5)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSelectAllRow(
      List<CartItemModel> items, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            activeColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => _toggleSelectAll(items, v ?? false),
          ),
          Text('SELECT ALL ITEMS',
              style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: cs.onSurface)),
          const Spacer(),
          Text('${_selectedIds.length} ITEMS SELECTED',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }


  Widget _summaryRow(
      String label, String value, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt, {
    required int selectedCount,
    required double total,
    required List<CartItemModel> selectedItems,
  }) {
    final enabled = selectedCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Total row ────────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCount > 0
                        ? '$selectedCount item dipilih'
                        : 'Belum ada item dipilih',
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('Total Pembayaran',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Text(
                'Rp ${_fmt(total)}',
                style: tt.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? cs.primary : cs.surfaceContainerHigh,
                foregroundColor:
                    enabled ? cs.onPrimary : cs.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: enabled
                  ? () => _onCheckout(
                      context, cs, selectedCount, total, selectedItems)
                  : null,
              child: Text(
                'PROCEED TO CHECKOUT',
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: enabled ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCheckout(
      BuildContext context, ColorScheme cs, int count, double total,
      List<CartItemModel> selectedItems) {
    if (selectedItems.isEmpty) return;
    final orderItems = cartItemsToOrderItems(selectedItems);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: orderItems,
          clearCartAfterOrder: true, // clear cart on success
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Item Tile
// ─────────────────────────────────────────────────────────────────────────────
class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({
    required this.item,
    required this.isSelected,
    required this.cs,
    required this.tt,
    required this.onToggle,
    required this.onQtyChanged,
    required this.onRemove,
    required this.fmt,
  });

  final CartItemModel item;
  final bool isSelected;
  final ColorScheme cs;
  final TextTheme tt;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSample = item.purchaseType == 'sample';
    // Sample: step = 1 kg, label = 'kg'; Standard: step = 1 unit
    final step = 1;
    final minQty = step;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: cs.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Checkbox(
                value: isSelected,
                activeColor: cs.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => onToggle(v ?? false),
              ),
            ),
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 72,
                color: cs.surfaceContainerHigh,
                child: item.productImageUrl.isNotEmpty
                    ? Image.network(item.productImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            color: cs.onSurfaceVariant))
                    : Icon(Icons.image_outlined,
                        color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.productTitle,
                            style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      // Purchase type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSample
                              ? cs.tertiaryContainer
                              : cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSample ? 'SAMPLE' : 'STANDARD',
                          style: tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              color: isSample
                                  ? cs.onTertiaryContainer
                                  : cs.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${fmt(item.effectiveUnitPrice)}',
                    style: tt.titleSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  // Quantity stepper
                  // Sample: locked at 1 kg — both buttons disabled
                  Row(
                    children: [
                      _QtyBtn(
                        icon: Icons.remove,
                        cs: cs,
                        onTap: () => onQtyChanged(item.quantity - step),
                        enabled: !isSample && item.quantity > minQty,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            Text('${item.quantity}',
                                style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700)),
                            Text(
                                item.unit,
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.add,
                        cs: cs,
                        onTap: () => onQtyChanged(item.quantity + step),
                        enabled: !isSample,
                      ),
                      const Spacer(),
                      // Remove button
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.errorContainer
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 14, color: cs.error),
                        ),
                      ),
                    ],
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
// Quantity stepper button
// ─────────────────────────────────────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  const _QtyBtn(
      {required this.icon,
      required this.cs,
      required this.onTap,
      required this.enabled});
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? cs.surfaceContainerHigh
              : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? cs.onSurface : cs.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty cart
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80,
              color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 20),
          Text('Keranjang Kosong',
              style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text('Tambahkan produk dari halaman Market',
              style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
