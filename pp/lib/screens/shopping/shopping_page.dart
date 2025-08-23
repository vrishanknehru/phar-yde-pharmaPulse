import 'package:flutter/material.dart';
import 'package:pharmapulse/screens/shopping/cart.dart';
import 'package:pharmapulse/screens/shopping/cart_manager.dart';

// MAIN WIDGET
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  // Use the singleton instance of CartManager
  final CartManager _cartManager = CartManager();

  final List<Product> _products = [
    Product(
      name: 'Honitus Hot Sip Ayurvedic Kaadha',
      imageUrl:
          'https://m.media-amazon.com/images/I/51aL1dz6MrL._SY300_SX300_QL70_FMwebp_.jpg',
      discount: '15% OFF',
      variants: [
        ProductVariant(volume: '30 Sachets', price: 306, originalPrice: 360),
        ProductVariant(volume: '1 Sachet', price: 12),
      ],
    ),
    Product(
      name: 'Eno Lemon Antacid',
      imageUrl:
          'https://i-cf65.ch-static.com/content/dam/cf-consumer-healthcare/nutrition-eno/en_IN/eno-products/eno-sachet-lemon.png?auto=format',
      variants: [
        ProductVariant(volume: '30 g', price: 66),
        ProductVariant(volume: '100 g', price: 152),
      ],
    ),
    Product(
      name: 'Dabur Hajmola Regular',
      imageUrl:
          'https://newassets.apollo247.com/pub/media/catalog/product/d/a/dab0104.jpg',
      variants: [
        ProductVariant(volume: '120 pieces', price: 68, originalPrice: 70),
        ProductVariant(volume: '240 pieces', price: 120, originalPrice: 130),
      ],
    ),
    Product(
      name: 'Himalaya Koflet Cough Syrup',
      imageUrl:
          'https://newassets.apollo247.com/pub/media/catalog/product/h/i/him0078.jpg',
      variants: [
        ProductVariant(volume: '100 ml', price: 113),
        ProductVariant(volume: '200 ml', price: 195),
      ],
    ),
    Product(
      name: 'Vicks Cough Tablets - Ginger',
      imageUrl:
          'https://newassets.apollo247.com/pub/media/catalog/product/v/i/vic0203.jpg',
      discount: '14% OFF',
      variants: [
        ProductVariant(
          volume: '1 pack (25 pieces)',
          price: 43,
          originalPrice: 50,
        ),
      ],
    ),
    Product(
      name: 'Pudin Hara Pearls',
      imageUrl:
          'https://m.media-amazon.com/images/I/817rRLldofL._UF1000,1000_QL80_.jpg',
      discount: '10% OFF',
      variants: [
        ProductVariant(volume: '2 x 10 tablets', price: 62, originalPrice: 69),
        ProductVariant(volume: '10 tablets', price: 32),
      ],
    ),
    Product(
      name: 'Moov Pain Relief Cream',
      imageUrl:
          'https://www.jiomart.com/images/product/original/490577735/moov-pain-relief-cream-15-g-product-images-o490577735-p590141178-0-202203151358.jpg?im=Resize=(420,420)',
      variants: [
        ProductVariant(volume: '50 g', price: 160),
        ProductVariant(volume: '30 g', price: 105),
      ],
    ),
    Product(
      name: 'Crocin Advance 500mg',
      imageUrl:
          'https://www.crocin.com/content/dam/cf-consumer-healthcare/panadol-reborn/en_IN/product-detail/380x463/Crocin-Advance-Pack_20May22-380x463.png',
      discount: '8% OFF',
      variants: [
        ProductVariant(volume: '20 tablets', price: 28, originalPrice: 30),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _onCartUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text(
          'Medicines',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Cart()),
                    );
                  },
                ),
                if (_cartManager.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_cartManager.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _products.map((product) {
              final cardWidth = (MediaQuery.of(context).size.width - 48) / 2;
              return _ProductCard(
                product: product,
                width: cardWidth,
                cartManager: _cartManager,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// PRODUCT CARD WIDGET
class _ProductCard extends StatefulWidget {
  final Product product;
  final CartManager cartManager;
  final double width;

  const _ProductCard({
    required this.product,
    required this.cartManager,
    required this.width,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late ProductVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.variants.first;
  }

  // In your _ProductCardState class inside shopping_page.dart

  void _showVariantBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
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
              const Text(
                'Select Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 🎨 Color for the title
                ),
              ),
              const SizedBox(height: 16),
              ...widget.product.variants.map((variant) {
                return ListTile(
                  title: Text(
                    variant.volume,
                    style: const TextStyle(
                      color: Colors.black, // 🎨 Color for the option text
                    ),
                  ),
                  trailing: Text(
                    '₹${variant.price.toInt()}',
                    style: const TextStyle(
                      color: Colors.black, // 🎨 Color for the price
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedVariant = variant;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return SizedBox(
    width: widget.width,
    child: Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGE + DISCOUNT OVERLAY
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.medication_liquid_rounded,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              if (widget.product.discount != null)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.discount!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // PRODUCT NAME
          Text(
            widget.product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // VARIANT SELECTOR
          GestureDetector(
            onTap: () => _showVariantBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedVariant.volume,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // PRICE + ADD BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${_selectedVariant.price.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  if (_selectedVariant.originalPrice != null)
                    Text(
                      '₹${_selectedVariant.originalPrice!.toInt()}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  widget.cartManager.addItem(
                    widget.product,
                    _selectedVariant,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart!'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'ADD',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
