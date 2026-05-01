import 'package:flutter/material.dart';

class SellerOrderScreen extends StatefulWidget {
  const SellerOrderScreen({super.key});

  @override
  State<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends State<SellerOrderScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF7F7F7);
  static const double _imgWidth    = 60;
  static const double _imgGap      = 14;

  // Data diisi dari backend — kosong = tampil empty state
  final List<Map<String, dynamic>> _orders  = [];
  final List<Map<String, dynamic>> _returns = [];
  final List<Map<String, dynamic>> _completedOrders = [];

  int _selectedCategory = 0;
  final List<String> _categories = ['Order', 'Return', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,

      // ── APP BAR ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: const Text(
          'EcoTrade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),

      // ── BODY ──
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Tab Kategori ──
          Row(
            children: List.generate(_categories.length, (index) {
              final selected = _selectedCategory == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < _categories.length - 1 ? 10 : 0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedCategory = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected ? primaryBlue : Colors.white,
                      foregroundColor: selected ? Colors.white : Colors.black87,
                      elevation: selected ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: selected ? primaryBlue : const Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Judul + hitungan item ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _selectedCategory == 0
                    ? 'Order Masuk'
                    : _selectedCategory == 1
                        ? 'Return Requests'
                        : 'Pesanan Selesai',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                '${_selectedCategory == 0 ? _orders.length : _selectedCategory == 1 ? _returns.length : _completedOrders.length} ITEM',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkGreen),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedCategory == 0) ...[
            if (_orders.isEmpty)
              _buildOrderEmptyState()
            else
              ..._orders.map((order) {
                final isGreen = order['badgeType'] == 'green';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildOrderCard(
                    orderNo    : order['orderNo']     as String,
                    badgeLabel : order['badgeLabel']  as String,
                    badgeBg    : isGreen ? primaryGreen : const Color(0xFFDCEEFF),
                    badgeText  : isGreen ? darkGreen    : primaryBlue,
                    productName: order['productName'] as String,
                    weight     : order['weight']      as String,
                    price      : order['price']       as String,
                    useImage   : order['useImage']    as bool,
                    actions    : _buildOrderActions(order['actionType'] as String),
                  ),
                );
              }),
          ] else if (_selectedCategory == 1) ...[
            if (_returns.isEmpty)
              _buildReturnEmptyState()
            else
              ..._returns.map((ret) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildReturnCard(
                  productName: ret['productName'] as String,
                  requestedBy: ret['requestedBy'] as String,
                  returnId   : ret['returnId']    as String,
                  totalItems : ret['totalItems']  as String,
                  totalPrice : ret['totalPrice']  as String,
                ),
              )),
          ] else ...[
            if (_completedOrders.isEmpty)
              _buildCompletedEmptyState()
            else
              ..._completedOrders.map((order) {
                final isGreen = order['badgeType'] == 'green';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildOrderCard(
                    orderNo    : order['orderNo']     as String,
                    badgeLabel : order['badgeLabel']  as String,
                    badgeBg    : isGreen ? primaryGreen : const Color(0xFFDCEEFF),
                    badgeText  : isGreen ? darkGreen    : primaryBlue,
                    productName: order['productName'] as String,
                    weight     : order['weight']      as String,
                    price      : order['price']       as String,
                    useImage   : order['useImage']    as bool,
                    actions    : _buildCompletedActions(),
                  ),
                );
              }),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Empty State: Order ─────────────────────────────────────────────────────
  Widget _buildOrderEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada orderan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pesanan dari pembeli akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Empty State: Return ────────────────────────────────────────────────────
  Widget _buildReturnEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo_rounded, size: 32, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'Tidak ada permintaan return',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline, size: 46, color: Color(0xFF9CCC65)),
          SizedBox(height: 16),
          Text(
            'Belum ada pesanan selesai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA)),
          ),
          SizedBox(height: 6),
          Text(
            'Pesanan yang sudah selesai akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedActions() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: const Text('Detail', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Widget: Order Card ─────────────────────────────────────────────────────
  Widget _buildOrderCard({
    required String orderNo,
    required String badgeLabel,
    required Color  badgeBg,
    required Color  badgeText,
    required String productName,
    required String weight,
    required String price,
    required bool   useImage,
    required Widget actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeText)),
          ),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: _imgWidth, height: _imgWidth,
            decoration: BoxDecoration(
              color: useImage ? const Color(0xFFD4C4A0) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: useImage
                ? const Icon(Icons.grass, color: Colors.brown, size: 30)
                : const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: _imgGap),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(orderNo, style: const TextStyle(fontSize: 11, color: greyText)),
              const SizedBox(height: 2),
              Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(weight, style: const TextStyle(fontSize: 12, color: greyText)),
              const SizedBox(height: 4),
              Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        actions,
      ]),
    );
  }

  Widget _buildOrderActions(String actionType) {
    if (actionType == 'accept_reject') {
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tolak', style: TextStyle(color: Colors.black87)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Terima'),
          ),
        ),
      ]);
    }
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: const Text('Lacak', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Widget: Return Card ────────────────────────────────────────────────────
  Widget _buildReturnCard({
    required String productName,
    required String requestedBy,
    required String returnId,
    required String totalItems,
    required String totalPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(6)),
          child: const Text('RETURN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: _imgWidth, height: _imgWidth,
            decoration: BoxDecoration(color: const Color(0xFFD4C4A0), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.set_meal_outlined, color: Colors.brown, size: 28),
          ),
          const SizedBox(width: _imgGap),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(
                'Requested by $requestedBy • ID: $returnId',
                style: const TextStyle(fontSize: 11, color: greyText, height: 1.4),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: _imgWidth + _imgGap),
          child: Column(children: [
            _buildInfoRow('TOTAL PESANAN', totalItems, Colors.black87),
            const SizedBox(height: 6),
            _buildInfoRow('TOTAL HARGA', totalPrice, primaryBlue),
          ]),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: _imgWidth + _imgGap),
          child: Row(children: [
            Expanded(child: _smallButton('Detail', Colors.transparent, Colors.black87, bordered: true)),
            const SizedBox(width: 8),
            Expanded(child: _smallButton('Tolak', Colors.transparent, Colors.black87, bordered: true)),
            const SizedBox(width: 8),
            Expanded(child: _smallButton('Terima', darkGreen, Colors.white)),
          ]),
        ),
      ]),
    );
  }

  Widget _smallButton(String label, Color bg, Color fg, {bool bordered = false}) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, foregroundColor: fg, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: bordered ? const BorderSide(color: Colors.black38) : BorderSide.none,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: greyText, letterSpacing: 0.8)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
    ]);
  }
}
