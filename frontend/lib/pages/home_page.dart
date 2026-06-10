import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'shop_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isLoadingProducts = true;
  String? _productLoadError;

  List<_ProductCardData> _newProducts = const [
    _ProductCardData(
      image: 'assets/images/new1.png',
      title: 'Striped Shirt',
      brand: 'Dorothy Perkins',
      price: 39,
      tagText: 'NEW',
      tagColor: Color(0xFF222222),
    ),
    _ProductCardData(
      image: 'assets/images/new2.png',
      title: 'White Shirt',
      brand: 'Mango Boy',
      price: 29,
      tagText: 'NEW',
      tagColor: Color(0xFF222222),
    ),
    _ProductCardData(
      image: 'assets/images/SportMen.webp',
      title: 'Summer Skirt',
      brand: 'Lime',
      price: 45,
      tagText: 'NEW',
      tagColor: Color(0xFF222222),
    ),
  ];

  List<_ProductCardData> _saleProducts = const [
    _ProductCardData(
      image: 'assets/images/EveningDress.webp',
      title: 'Evening Dress',
      brand: 'Dorothy Perkins',
      price: 12,
      oldPrice: 15,
      tagText: '-20%',
      tagColor: AppColors.primary,
    ),
    _ProductCardData(
      image: 'assets/images/SportDress1.avif',
      title: 'Sport Dress',
      brand: 'Sitlly',
      price: 19,
      oldPrice: 22,
      tagText: '-15%',
      tagColor: AppColors.primary,
    ),
    _ProductCardData(
      image: 'assets/images/SportDress2.jpg',
      title: 'Sport Dress',
      brand: 'Dorothy Perkins',
      price: 12,
      oldPrice: 14,
      tagText: '-20%',
      tagColor: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login thành công',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productLoadError = null;
    });

    final saleResponse = await ApiService.getProductsByTag('sale');
    final newResponse = await ApiService.getProductsByTag('new');

    if (!mounted) return;

    if (saleResponse['statusCode'] == 200 && newResponse['statusCode'] == 200) {
      setState(() {
        _saleProducts = _productsFromApi(
          saleResponse['data'],
          section: _ProductSection.sale,
        );
        _newProducts = _withSportMenFallback(_productsFromApi(
          newResponse['data'],
          section: _ProductSection.newCollection,
        ));
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _productLoadError = 'Khong tai duoc san pham tu server';
        _isLoadingProducts = false;
      });
    }
  }

  List<_ProductCardData> _productsFromApi(
    dynamic data, {
    required _ProductSection section,
  }) {
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => _ProductCardData.fromProductJson(json, section: section))
        .toList();
  }

  List<_ProductCardData> _withSportMenFallback(List<_ProductCardData> products) {
    final hasSportMen = products.any(
      (product) => product.image.toLowerCase().contains('sportmen.webp'),
    );
    if (hasSportMen) return products;

    return [
      ...products,
      const _ProductCardData(
        image: 'assets/images/SportMen.webp',
        title: 'Summer Shirt',
        brand: 'Lime',
        price: 45,
        tagText: 'NEW',
        tagColor: Color(0xFF222222),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            children: [
              _FashionSalePage(
                newProducts: _newProducts,
                isLoading: _isLoadingProducts,
                errorText: _productLoadError,
                onRefresh: _loadProducts,
              ),
              _StreetClothesPage(
                saleProducts: _saleProducts,
                newProducts: _newProducts,
                isLoading: _isLoadingProducts,
                errorText: _productLoadError,
                onRefresh: _loadProducts,
              ),
              _CollectionPage(onRefresh: _loadProducts),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNav(
              selectedIndex: _pageIndex,
              onHomeTap: () => _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              ),
              onShopTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FashionSalePage extends StatelessWidget {
  final List<_ProductCardData> newProducts;
  final bool isLoading;
  final String? errorText;
  final Future<void> Function() onRefresh;

  const _FashionSalePage({
    required this.newProducts,
    required this.isLoading,
    required this.errorText,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height * 0.52;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(
              image: 'assets/images/banner1.png',
              height: heroHeight,
              title: 'Fashion\nsale',
              alignment: Alignment.bottomLeft,
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              buttonText: 'Check',
            ),
            _SectionHeader(
              title: 'New',
              subtitle: 'You\'ve never seen it before!',
              topPadding: 28,
            ),
            _ProductRail(
              products: newProducts,
              isLoading: isLoading,
              errorText: errorText,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreetClothesPage extends StatelessWidget {
  final List<_ProductCardData> saleProducts;
  final List<_ProductCardData> newProducts;
  final bool isLoading;
  final String? errorText;
  final Future<void> Function() onRefresh;

  const _StreetClothesPage({
    required this.saleProducts,
    required this.newProducts,
    required this.isLoading,
    required this.errorText,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(
              image: 'assets/images/banner2.png',
              height: 190,
              title: 'Street clothes',
              alignment: Alignment.bottomLeft,
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            ),
            _SectionHeader(
              title: 'Sale',
              subtitle: 'Super summer sale',
              topPadding: 30,
            ),
            _ProductRail(
              products: saleProducts,
              isLoading: isLoading,
              errorText: errorText,
            ),
            _SectionHeader(
              title: 'New',
              subtitle: 'You\'ve never seen it before!',
              topPadding: 34,
            ),
            _ProductRail(
              products: newProducts,
              isLoading: isLoading,
              errorText: errorText,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionPage extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CollectionPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 92),
        child: Column(
          children: [
            _HeroBanner(
              image: 'assets/images/banner3_newcollection.png',
              height: screenHeight * 0.45,
              title: 'New collection',
              alignment: Alignment.bottomRight,
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            ),
            SizedBox(
              height: screenHeight * 0.45,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.white,
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Summer\nsale',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ImageTile(
                            image: 'assets/images/banner3_black.png',
                            title: 'Black',
                            alignment: Alignment.bottomLeft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _ImageTile(
                      image: 'assets/images/banner3_menshoodie.png',
                      title: 'Men\'s\nhoodies',
                      alignment: Alignment.centerRight,
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

class _HeroBanner extends StatelessWidget {
  final String image;
  final double height;
  final String title;
  final Alignment alignment;
  final EdgeInsets titlePadding;
  final String? buttonText;

  const _HeroBanner({
    required this.image,
    required this.height,
    required this.title,
    required this.alignment,
    required this.titlePadding,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Padding(
            padding: titlePadding,
            child: Align(
              alignment: alignment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: alignment.x > 0
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: title.contains('\n') ? 42 : 30,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (buttonText != null) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 160,
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          buttonText!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double topPadding;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.only(bottom: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View all',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  final List<_ProductCardData> products;
  final bool isLoading;
  final String? errorText;

  const _ProductRail({
    required this.products,
    required this.isLoading,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 254,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorText != null) {
      return SizedBox(
        height: 254,
        child: Center(
          child: Text(
            errorText!,
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return SizedBox(
        height: 254,
        child: Center(
          child: Text(
            'Chua co san pham',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 254,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _ProductCard(data: products[index]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductCardData data;

  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ProductImage(image: data.image),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: data.tagColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      data.tagText,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: -18,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: Color(0xFFFFBA49), size: 13),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (data.oldPrice != null) ...[
                Text(
                  '${data.oldPrice}\$',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '${data.price}\$',
                style: GoogleFonts.inter(
                  color: data.oldPrice != null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String image;
  final String title;
  final Alignment alignment;

  const _ImageTile({
    required this.image,
    required this.title,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.14)),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Align(
            alignment: alignment,
            child: Text(
              title,
              textAlign: alignment.x > 0 ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String image;

  const _ProductImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ImageFallback(message: 'Image not found'),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _ImageFallback(message: image),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String message;

  const _ImageFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onShopTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: 'assets/icons/home.svg',
            label: 'Home',
            selected: true,
            onTap: onHomeTap,
          ),
          _NavItem(
            icon: 'assets/icons/shopping_cart.svg',
            label: 'Shop',
            onTap: onShopTap,
          ),
          const _NavItem(icon: 'assets/icons/bag.svg', label: 'Bag'),
          const _NavItem(icon: 'assets/icons/favourites.svg', label: 'Favorites'),
          const _NavItem(icon: 'assets/icons/profile.svg', label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardData {
  final String image;
  final String title;
  final String brand;
  final int price;
  final int? oldPrice;
  final String tagText;
  final Color tagColor;

  const _ProductCardData({
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    this.oldPrice,
    required this.tagText,
    required this.tagColor,
  });

  factory _ProductCardData.fromProductJson(
    Map<String, dynamic> json, {
    required _ProductSection section,
  }) {
    final salePrice = _numToInt(json['salePrice']);
    final comparePrice = _numToInt(json['comparePrice']);
    final hasDiscount = section == _ProductSection.sale &&
        comparePrice != null &&
        salePrice != null &&
        comparePrice > salePrice;
    final discount = hasDiscount
        ? (((comparePrice - salePrice) / comparePrice) * 100).round()
        : null;

    return _ProductCardData(
      image: _normalizeProductImage(json['image']),
      title: (json['productName'] ?? json['name'] ?? 'Product').toString(),
      brand: (json['sku'] ?? json['brand'] ?? 'Fashion').toString(),
      price: salePrice ?? 0,
      oldPrice: hasDiscount ? comparePrice : null,
      tagText: section == _ProductSection.sale
          ? (discount != null ? '-$discount%' : 'SALE')
          : 'NEW',
      tagColor: section == _ProductSection.sale
          ? AppColors.primary
          : const Color(0xFF222222),
    );
  }
}

enum _ProductSection { sale, newCollection }

int? _numToInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.round();
  return double.tryParse(value.toString())?.round();
}

String _normalizeProductImage(dynamic value) {
  final image = value?.toString().trim();
  if (image == null || image.isEmpty) {
    return 'assets/images/new1.png';
  }

  final fileName = image.split('/').last.toLowerCase();
  final imageAliases = {
    'sale1.png': 'assets/images/EveningDress.webp',
    'sale2.png': 'assets/images/SportDress1.avif',
    'sale3.png': 'assets/images/SportDress2.jpg',
    'eveningdress.webp': 'assets/images/EveningDress.webp',
    'sportdress1.avif': 'assets/images/SportDress1.avif',
    'sportdress2.jpg': 'assets/images/SportDress2.jpg',
    'sportmen.webp': 'assets/images/SportMen.webp',
    'model.webp': 'assets/images/model.webp',
    'new1.png': 'assets/images/new1.png',
    'new2.png': 'assets/images/new2.png',
  };
  final aliasedImage = imageAliases[fileName];
  if (aliasedImage != null) return aliasedImage;

  if (image.startsWith('assets/')) return image;
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }
  return 'assets/images/$image';
}
