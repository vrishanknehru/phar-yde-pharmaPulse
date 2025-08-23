import 'package:flutter/material.dart';
import 'package:pharmapulse/screens/shopping/cart_manager.dart';

// --- UI Constants for a Sleek and Minimalistic Design ---
class _UIConstants {
  // Primary color for buttons and highlights
  static final Color primaryColor = Colors.green.shade700;
  // Accent color for deletions or warnings
  static final Color accentColor = Colors.red.shade600;
  // Neutral background color
  static const Color backgroundColor = Color(0xFFF8F9FA);
  // Color for surfaces like cards and bottom sheets
  static const Color surfaceColor = Colors.white;
  // Primary text color
  static const Color primaryTextColor = Color(0xFF1F2937);
  // Softer, secondary text color for details
  static const Color secondaryTextColor = Color(0xFF6B7280);
  // Subtle color for borders and dividers
  static final Color borderColor = Colors.grey.shade200;

  // Text style for main titles (e.g., AppBar)
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: primaryTextColor,
  );
  // Text style for item names
  static const TextStyle itemTitleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: primaryTextColor,
  );
  // Text style for body content and prices
  static const TextStyle bodyStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: primaryTextColor,
  );
  // Text style for secondary details (e.g., item volume, summary labels)
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );
}

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    // Listen to cart changes to rebuild the UI
    _cartManager.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    // Clean up the listener when the widget is removed
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    // Check if the widget is still in the tree before calling setState
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UIConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Cart (${_cartManager.itemCount})',
          style: _UIConstants.titleStyle,
        ),
        backgroundColor: _UIConstants.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Using a subtle border instead of a shadow for a flatter look
        shape: Border(
          bottom: BorderSide(color: _UIConstants.borderColor, width: 1.5),
        ),
        actions: [
          if (!_cartManager.isEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: _UIConstants.accentColor,
              ),
              onPressed: _showClearCartDialog,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _cartManager.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  // Using ListView.separated for clean dividers between items
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return _CartItemCard(
                        item: item,
                        onIncrement: () =>
                            _cartManager.incrementQuantity(index),
                        onDecrement: () =>
                            _cartManager.decrementQuantity(index),
                        onRemove: () => _cartManager.removeItem(index),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
                _buildOrderSummary(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _UIConstants.primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Looks like you haven't added anything yet. Let's go shopping!",
              style: _UIConstants.subtitleStyle.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _UIConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final double subtotal = _cartManager.subtotal;
    // Delivery fee is now a constant for simplicity, adjust as needed
    const double deliveryFee = 40.0;
    final bool isEligibleForFreeDelivery = subtotal > 500; // Example threshold
    final double finalDeliveryFee = subtotal > 0 && !isEligibleForFreeDelivery
        ? deliveryFee
        : 0.0;
    final double total = subtotal + finalDeliveryFee;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: _UIConstants.surfaceColor,
        // Subtle top border for separation
        border: Border(
          top: BorderSide(color: _UIConstants.borderColor, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow(
            label: 'Subtotal (${_cartManager.itemCount} items)',
            value: '₹${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            label: 'Delivery Fee',
            value: finalDeliveryFee > 0
                ? '₹${finalDeliveryFee.toStringAsFixed(2)}'
                : 'FREE',
            valueColor: finalDeliveryFee > 0
                ? _UIConstants.primaryTextColor
                : _UIConstants.primaryColor,
          ),
          const Divider(height: 24, thickness: 1.5),
          _buildSummaryRow(
            label: 'Total Amount',
            value: '₹${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showCheckoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _UIConstants.primaryColor,
                foregroundColor: _UIConstants.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to reduce repetition in the order summary
  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isTotal = false,
  }) {
    final style = isTotal
        ? _UIConstants.titleStyle.copyWith(fontSize: 18)
        : _UIConstants.bodyStyle;
    final labelStyle = isTotal
        ? style
        : _UIConstants.subtitleStyle.copyWith(fontSize: 15);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: style.copyWith(color: valueColor)),
      ],
    );
  }

  void _showClearCartDialog() {
    // Dialogs are kept simple for clarity
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _UIConstants.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _cartManager.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _UIConstants.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    final total =
        _cartManager.subtotal + 40; // Assuming fixed delivery fee for checkout
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Order Placed!'),
        content: Text(
          'Thank you for your order of ₹${total.toStringAsFixed(2)}. It will be delivered shortly.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _cartManager.clearCart();
              // Pop twice to close the dialog and the cart screen
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _UIConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// --- Refined and Minimal Cart Item Card ---
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _UIConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        // Using a subtle border instead of a shadow
        border: Border.all(color: _UIConstants.borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.medication_outlined,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.product.name,
                  style: _UIConstants.itemTitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(item.variant.volume, style: _UIConstants.subtitleStyle),
                const SizedBox(height: 6),
                // Displaying the total price for the line item directly
                Text(
                  '₹${item.totalPrice.toStringAsFixed(2)}',
                  style: _UIConstants.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          _buildQuantityControls(),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Remove Button
        IconButton(
          onPressed: onRemove,
          icon: Icon(Icons.close, color: _UIConstants.accentColor, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          tooltip: 'Remove item',
        ),
        const SizedBox(height: 10),
        // Quantity Stepper
        Container(
          decoration: BoxDecoration(
            color: _UIConstants.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _UIConstants.borderColor),
          ),
          child: Row(
            children: [
              _buildStepperButton(icon: Icons.remove, onPressed: onDecrement),
              SizedBox(
                width: 30,
                child: Text(
                  item.quantity.toString(),
                  textAlign: TextAlign.center,
                  style: _UIConstants.bodyStyle.copyWith(fontSize: 15),
                ),
              ),
              _buildStepperButton(
                icon: Icons.add,
                onPressed: onIncrement,
                color: _UIConstants.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 16,
        color: color ?? _UIConstants.secondaryTextColor,
      ),
      onPressed: onPressed,
      // Using minimal constraints for a compact design
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
    );
  }
}
