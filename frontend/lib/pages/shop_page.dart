import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _tabIndex = 0;
  bool _showSubCategories = false;
  bool _showCatalog = false;
  bool _gridMode = false;
  String _selectedChip = 'T-shirts';
  String _sortLabel = 'Price: lowest to high';

  final _tabs = const ['Women', 'Men', 'Kids'];
  final _subCategories = const [
    'Tops',
    'Shirts & Blouses',
    'Cardigans & Sweaters',
    'Knitwear',
    'Blazers',
    'Outerwear',
    'Pants',
    'Jeans',
    'Shorts',
    'Skirts',
    'Dresses',
  ];
  final _chips = const ['T-shirts', 'Crop tops', 'Blouses', 'Sleeveless', 'Shirts'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_showCatalog)
              _buildCatalog()
            else if (_showSubCategories)
              _buildSubCategories()
            else
              _buildCategories(),
            const Align(
              alignment: Alignment.bottomCenter,
              child: _ShopBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_showCatalog) {
                setState(() => _showCatalog = false);
              } else if (_showSubCategories) {
                setState(() => _showSubCategories = false);
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, size: 25)),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      children: [
        _header('Categories'),
        Row(
          children: List.generate(_tabs.length, (index) {
            final selected = _tabIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _tabIndex = index),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _tabs[index],
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      height: 3,
                      color: selected ? AppColors.primary : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            children: [
              _SaleBanner(onTap: () => _openSubCategories()),
              const SizedBox(height: 16),
              _CategoryCard(
                title: 'New',
                image: 'assets/images/new.jpg',
                onTap: _openSubCategories,
              ),
              _CategoryCard(
                title: 'Clothes',
                image: 'assets/images/clothes.jpg',
                onTap: _openSubCategories,
              ),
              _CategoryCard(
                title: 'Shoes',
                image: 'assets/images/shoes1.webp',
                onTap: _openSubCategories,
              ),
              _CategoryCard(
                title: 'Accesories',
                image: 'assets/images/accessories1.webp',
                onTap: _openSubCategories,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Categories'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _openCatalog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                'VIEW ALL ITEMS',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Choose category',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 104),
            itemCount: _subCategories.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE8E8E8)),
            itemBuilder: (context, index) => ListTile(
              title: Text(
                _subCategories[index],
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: _subCategories[index] == 'Tops' ? _openCatalog : () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalog() {
    final products = _sortedProducts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      children: [
        _header('Women\'s tops'),
        SizedBox(
          height: 34,
          child: ListView.separated(
            clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chip = _chips[index];
              final selected = chip == _selectedChip;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                label: Text(chip),
                onSelected: (_) => setState(() => _selectedChip = chip),
                selectedColor: AppColors.textPrimary,
                backgroundColor: AppColors.textPrimary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                labelStyle: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            children: [
              TextButton.icon(
                onPressed: () {},
              icon: const Icon(Icons.filter_list, color: AppColors.textPrimary, size: 20),
              label: Text(
                'Filters',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
              ),
              ),
              const SizedBox(width: 18),
              TextButton.icon(
                onPressed: () => setState(() {
                _sortLabel = _sortLabel == 'Price: lowest to high'
                    ? 'Price: highest to low'
                    : 'Price: lowest to high';
              }),
              icon: const Icon(Icons.swap_vert, color: AppColors.textPrimary, size: 20),
              label: Text(
                _sortLabel,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
              IconButton(
                onPressed: () => setState(() => _gridMode = !_gridMode),
                icon: Icon(_gridMode ? Icons.view_list : Icons.grid_view, size: 20),
              ),
            ],
            ),
          ),
        if (_gridMode)
          _ProductGrid(products: products, onProductTap: _openProductDetail)
        else
          ...products.take(4).map(
                (product) => _ProductListTile(
                  product: product,
                  onTap: () => _openProductDetail(product),
                ),
              ),
      ],
    );
  }

  List<_CatalogProduct> get _sortedProducts {
    final products = [...(_catalogData[_selectedChip] ?? _catalogData['T-shirts']!)];
    if (_sortLabel == 'Price: lowest to high') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else {
      products.sort((a, b) => b.price.compareTo(a.price));
    }
    return products;
  }

  void _openSubCategories() {
    setState(() => _showSubCategories = true);
  }

  void _openCatalog() {
    setState(() {
      _selectedChip = 'T-shirts';
      _gridMode = false;
      _showCatalog = true;
    });
  }

  void _openProductDetail(_CatalogProduct product) {
    final related = _sortedProducts.where((item) => item != product).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductDetailPage(
          product: product,
          relatedProducts: related.isEmpty ? _sortedProducts : related,
        ),
      ),
    );
  }
}

class _SaleBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SaleBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SUMMER SALES',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Up to 50% off',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Expanded(
                child: Image.asset(image, fit: BoxFit.cover, height: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final _CatalogProduct product;
  final VoidCallback onTap;

  const _ProductListTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 112,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Image.asset(product.image, width: 98, height: 112, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    _Stars(rating: product.rating, reviews: product.reviews),
                    const Spacer(),
                    Text(
                      '${product.price}\$',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Heart(favorite: product.favorite),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<_CatalogProduct> products;
  final ValueChanged<_CatalogProduct> onProductTap;

  const _ProductGrid({required this.products, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.57,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          onTap: () => onProductTap(product),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        product.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (product.discountPercent != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _DiscountBadge(percent: product.discountPercent!),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _Heart(favorite: product.favorite),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _Stars(rating: product.rating, reviews: product.reviews),
              Text(
                product.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  if (product.oldPrice != null) ...[
                    Text(
                      '${product.oldPrice}\$',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${product.price}\$',
                    style: GoogleFonts.inter(
                      color: product.oldPrice == null ? AppColors.textPrimary : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductDetailPage extends StatefulWidget {
  final _CatalogProduct product;
  final List<_CatalogProduct> relatedProducts;

  const _ProductDetailPage({
    required this.product,
    required this.relatedProducts,
  });

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  String _selectedSize = 'Size';
  String _selectedColor = 'Black';

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _detailHeader(product.name),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 22 + MediaQuery.paddingOf(context).bottom),
                children: [
                  _imageGallery(product),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(child: _SelectBox(label: _selectedSize, onTap: _showSizeSheet)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectBox(
                            label: _selectedColor,
                            onTap: () => setState(() {
                              _selectedColor = _selectedColor == 'Black' ? 'White' : 'Black';
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Heart(favorite: product.favorite),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.brand,
                                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                product.name,
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _Stars(rating: product.rating, reviews: product.reviews),
                            ],
                          ),
                        ),
                        Text(
                          '\$${product.price}.99',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Text(
                      '${product.name} in soft cotton jersey with decorative buttons and a comfortable everyday fit.',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _showSizeSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          'ADD TO CART',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  const _InfoRow(title: 'Shipping info'),
                  const _InfoRow(title: 'Support'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'You can also like this',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '${widget.relatedProducts.length} items',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 266,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.relatedProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) => _RelatedCard(
                        product: widget.relatedProducts[index],
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ProductDetailPage(
                                product: widget.relatedProducts[index],
                                relatedProducts: widget.relatedProducts
                                    .where((item) => item != widget.relatedProducts[index])
                                    .toList(),
                              ),
                            ),
                          );
                        },
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

  Widget _detailHeader(String title) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share, size: 22)),
        ],
      ),
    );
  }

  Widget _imageGallery(_CatalogProduct product) {
    final related = widget.relatedProducts.take(2).toList();
    final images = [product.image, ...related.map((item) => item.image)];

    return SizedBox(
      height: 370,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.72),
        padEnds: false,
        itemCount: images.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 2, right: 2),
          child: Image.asset(images[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _showSizeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select size',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                    final selected = _selectedSize == size;
                    return SizedBox(
                      width: 92,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _selectedSize = size);
                          setSheetState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? AppColors.primary : AppColors.white,
                          foregroundColor: selected ? AppColors.white : AppColors.textPrimary,
                          side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFDADADA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(size),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const _InfoRow(title: 'Size info', dense: true),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text(
                      'ADD TO CART',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SelectBox({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final bool dense;

  const _InfoRow({required this.title, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: dense,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(height: 1, color: Color(0xFFE8E8E8)),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final _CatalogProduct product;
  final VoidCallback onTap;

  const _RelatedCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      product.image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (product.discountPercent != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DiscountBadge(percent: product.discountPercent!),
                    ),
                  Positioned(right: 0, bottom: 0, child: _Heart(favorite: product.favorite)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _Stars(rating: product.rating, reviews: product.reviews),
            Text(
              product.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
            ),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                if (product.oldPrice != null) ...[
                  Text(
                    '${product.oldPrice}\$',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${product.price}\$',
                  style: GoogleFonts.inter(
                    color: product.oldPrice == null ? AppColors.textPrimary : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _Stars extends StatelessWidget {
  final double rating;
  final int reviews;

  const _Stars({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final visibleRating = rating.clamp(0, 5).round();
    final visibleReviews = reviews.clamp(0, 5);

    return Row(
      children: [
        ...List.generate(5, (index) {
          final active = index < visibleRating;
          return Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? const Color(0xFFFFBA49) : AppColors.textSecondary,
            size: 13,
          );
        }),
        const SizedBox(width: 2),
        Text(
          '($visibleReviews)',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _Heart extends StatelessWidget {
  final bool favorite;

  const _Heart({required this.favorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        favorite ? Icons.favorite : Icons.favorite_border,
        color: favorite ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Text(
        '-$percent%',
        style: GoogleFonts.inter(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ShopBottomNav extends StatelessWidget {
  const _ShopBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.fromLTRB(18, 10, 18, 8 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _MiniNav(icon: 'assets/icons/home.svg', label: 'Home'),
          _MiniNav(icon: 'assets/icons/shopping_cart.svg', label: 'Shop', selected: true),
          _MiniNav(icon: 'assets/icons/bag.svg', label: 'Bag'),
          _MiniNav(icon: 'assets/icons/favourites.svg', label: 'Favorites'),
          _MiniNav(icon: 'assets/icons/profile.svg', label: 'Profile'),
        ],
      ),
    );
  }
}

class _MiniNav extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;

  const _MiniNav({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return SizedBox(
      width: 52,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, width: 24, height: 24, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
            const SizedBox(height: 3),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogProduct {
  final String name;
  final String brand;
  final String image;
  final int price;
  final int? oldPrice;
  final int? discountPercent;
  final double rating;
  final int reviews;
  final bool favorite;

  const _CatalogProduct({
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    this.oldPrice,
    this.discountPercent,
    required this.rating,
    required this.reviews,
    this.favorite = false,
  });
}

final Map<String, List<_CatalogProduct>> _catalogData = {
  'T-shirts': [
    const _CatalogProduct(name: 'T-Shirt SPANISH', brand: 'Mango', image: 'assets/images/T-shirt1.webp', price: 9, rating: 4, reviews: 3),
    const _CatalogProduct(name: 'Blouse', brand: 'Dorothy Perkins', image: 'assets/images/blouse1.webp', price: 14, oldPrice: 21, discountPercent: 20, rating: 5, reviews: 10),
    const _CatalogProduct(name: 'Shirt', brand: 'Mango', image: 'assets/images/T-shirt2.webp', price: 18, rating: 0, reviews: 0),
    const _CatalogProduct(name: 'Light blouse', brand: 'Dorothy Perkins', image: 'assets/images/blouse2.webp', price: 16, oldPrice: 20, discountPercent: 20, rating: 5, reviews: 10),
    const _CatalogProduct(name: 'Pullover', brand: 'Mango', image: 'assets/images/T-shirt3.webp', price: 51, rating: 4, reviews: 3),
    const _CatalogProduct(name: 'T-shirt', brand: 'LOST Ink', image: 'assets/images/T-shirt4.webp', price: 12, rating: 5, reviews: 10, favorite: true),
    const _CatalogProduct(name: 'Oversize tee', brand: 'Bershka', image: 'assets/images/T-shirt5.webp', price: 17, rating: 3, reviews: 5),
    const _CatalogProduct(name: 'Basic T-shirt', brand: 'H&M', image: 'assets/images/T-shirt6.webp', price: 11, rating: 4, reviews: 8),
    const _CatalogProduct(name: 'Print tee', brand: 'Zara', image: 'assets/images/T-shirt7.webp', price: 22, rating: 5, reviews: 14),
    const _CatalogProduct(name: 'Cotton T-shirt', brand: 'Pull&Bear', image: 'assets/images/T-shirt8.webp', price: 15, rating: 4, reviews: 7),
  ],
  'Crop tops': [
    const _CatalogProduct(name: 'Rib crop top', brand: 'Stradivarius', image: 'assets/images/croptop1webp.webp', price: 18, rating: 4, reviews: 8),
    const _CatalogProduct(name: 'Summer crop', brand: 'Mango', image: 'assets/images/croptop2.webp', price: 16, oldPrice: 20, discountPercent: 20, rating: 5, reviews: 11),
    const _CatalogProduct(name: 'Pink crop top', brand: 'Bershka', image: 'assets/images/croptop3.webp', price: 19, rating: 3, reviews: 4),
    const _CatalogProduct(name: 'Knit crop', brand: 'Topshop', image: 'assets/images/croptop4.webp', price: 24, rating: 4, reviews: 6, favorite: true),
    const _CatalogProduct(name: 'White crop', brand: 'Zara', image: 'assets/images/croptop5.webp', price: 21, rating: 5, reviews: 13),
    const _CatalogProduct(name: 'Black crop', brand: 'H&M', image: 'assets/images/croptop6.webp', price: 14, rating: 4, reviews: 3),
  ],
  'Blouses': [
    const _CatalogProduct(name: 'Blouse', brand: 'Dorothy Perkins', image: 'assets/images/blouse1.webp', price: 14, oldPrice: 21, discountPercent: 20, rating: 5, reviews: 10),
    const _CatalogProduct(name: 'Light blouse', brand: 'Dorothy Perkins', image: 'assets/images/blouse2.webp', price: 16, oldPrice: 20, discountPercent: 20, rating: 5, reviews: 10),
    const _CatalogProduct(name: 'Silk blouse', brand: 'Mango', image: 'assets/images/blouse3.jpg', price: 34, rating: 0, reviews: 0),
    const _CatalogProduct(name: 'Office blouse', brand: 'Topshop', image: 'assets/images/blouse4.jpg', price: 31, rating: 4, reviews: 6),
    const _CatalogProduct(name: 'Pattern blouse', brand: 'Zara', image: 'assets/images/blouse5.jpg', price: 29, rating: 3, reviews: 5),
  ],
  'Sleeveless': [
    const _CatalogProduct(name: 'Sleeveless top', brand: 'Mango', image: 'assets/images/sleeveless1.jpg', price: 20, rating: 4, reviews: 3),
    const _CatalogProduct(name: 'White sleeveless', brand: 'Zara', image: 'assets/images/sleeveless2.jpg', price: 22, rating: 5, reviews: 9),
    const _CatalogProduct(name: 'Linen top', brand: 'H&M', image: 'assets/images/sleeveless3.webp', price: 17, rating: 3, reviews: 2),
    const _CatalogProduct(name: 'Summer blouse', brand: 'Bershka', image: 'assets/images/sleeveless4.webp', price: 19, oldPrice: 25, discountPercent: 24, rating: 4, reviews: 7),
  ],
  'Shirts': [
    const _CatalogProduct(name: 'Check shirt', brand: 'Topshop', image: 'assets/images/shirt1.jpg', price: 51, rating: 4, reviews: 3),
    const _CatalogProduct(name: 'Denim shirt', brand: 'Mango', image: 'assets/images/shirt2.jpg', price: 39, rating: 5, reviews: 12),
    const _CatalogProduct(name: 'Classic shirt', brand: 'Zara', image: 'assets/images/shirt3.jpg', price: 28, rating: 3, reviews: 4),
    const _CatalogProduct(name: 'Loose shirt', brand: 'H&M', image: 'assets/images/shirt5.jpg', price: 24, oldPrice: 30, discountPercent: 20, rating: 4, reviews: 8),
  ],
};
