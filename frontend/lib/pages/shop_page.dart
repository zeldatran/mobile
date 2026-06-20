import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class ShopPage extends StatefulWidget {
  final UserModel user;
  final String initialTab;
  final Map<String, dynamic>? initialProduct;

  const ShopPage({
    super.key,
    required this.user,
    this.initialTab = 'Shop',
    this.initialProduct,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class ProductDetailRoutePage extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> product;

  const ProductDetailRoutePage({
    super.key,
    required this.user,
    required this.product,
  });

  @override
  State<ProductDetailRoutePage> createState() => _ProductDetailRoutePageState();
}

class _ProductDetailRoutePageState extends State<ProductDetailRoutePage> {
  final Set<String> _favoriteKeys = {};
  late final _CatalogProduct _product;

  @override
  void initState() {
    super.initState();
    _product = _CatalogProduct.fromHomePayload(widget.product);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (widget.user.id.isEmpty) return;
    final response = await ApiService.getFavorites(widget.user.id);
    if (!mounted ||
        response['statusCode'] != 200 ||
        response['data'] is! List) {
      return;
    }

    setState(() {
      _favoriteKeys
        ..clear()
        ..addAll(
          (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((json) => (json['productKey'] ?? '').toString())
              .where((key) => key.isNotEmpty),
        );
    });
  }

  Future<void> _handleFavoriteTap(_CatalogProduct product) async {
    final key = product.productKey;
    if (_favoriteKeys.contains(key)) {
      final response = await ApiService.removeFavorite(
        accountId: widget.user.id,
        productKey: key,
      );
      if (!mounted) return;
      if (response['statusCode'] == 204 || response['statusCode'] == 200) {
        setState(() => _favoriteKeys.remove(key));
      }
      return;
    }

    final item = await showModalBottomSheet<_FavoriteItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FavoriteSizeSheet(product: product),
    );

    if (item == null || !mounted) return;
    final response = await ApiService.addFavorite(
      accountId: widget.user.id,
      productKey: product.productKey,
      productName: product.name,
      brand: product.brand,
      image: product.image,
      price: product.price,
      oldPrice: product.oldPrice,
      discountPercent: product.discountPercent,
      rating: product.rating,
      reviews: product.reviews,
      size: item.size,
      color: item.color,
    );

    if (!mounted) return;
    if (response['statusCode'] == 201 || response['statusCode'] == 200) {
      setState(() => _favoriteKeys.add(key));
    }
  }

  Future<void> _addToBag(
    _CatalogProduct product,
    String size,
    String color,
  ) async {
    final selectedSize = size == 'Size' ? 'S' : size;
    if (widget.user.id.isNotEmpty) {
      await ApiService.addCartItem(
        accountId: widget.user.id,
        productKey: product.productKey,
        productName: product.name,
        brand: product.brand,
        image: product.image,
        price: product.price,
        oldPrice: product.oldPrice,
        discountPercent: product.discountPercent,
        rating: product.rating,
        reviews: product.reviews,
        size: selectedSize,
        color: color,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to bag',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProductDetailPage(
      product: _product,
      relatedProducts: const [],
      user: widget.user,
      favoriteKeys: _favoriteKeys,
      onFavoriteTap: _handleFavoriteTap,
      onAddToBag: _addToBag,
      onBackPressed: () {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
    );
  }
}

class _ShopPageState extends State<ShopPage> {
  int _tabIndex = 0;
  bool _showSubCategories = false;
  bool _showCatalog = false;
  bool _showFavorites = false;
  bool _showBag = false;
  bool _showProfile = false;
  bool _gridMode = false;
  bool _isCheckingBackend = true;
  bool _backendAvailable = false;
  String? _backendErrorText;
  String _selectedChip = 'T-shirts';
  String _sortLabel = 'Price: lowest to high';
  String _selectedCategory = 'Tops';
  _CatalogFilter _catalogFilter = _CatalogFilter.defaults();
  _CatalogProduct? _initialDetailProduct;
  final Set<String> _favoriteKeys = {};
  final Map<String, _FavoriteItem> _favoriteItems = {};
  final TextEditingController _promoController = TextEditingController();
  late final List<_BagItem> _bagItems;
  bool _promoApplied = false;

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
  final _chips = const [
    'T-shirts',
    'Crop tops',
    'Blouses',
    'Sleeveless',
    'Shirts',
  ];

  @override
  void initState() {
    super.initState();
    _showBag = widget.initialTab == 'Bag';
    _showFavorites = widget.initialTab == 'Favorites';
    _showProfile = widget.initialTab == 'Profile';
    _initialDetailProduct = widget.initialProduct == null
        ? null
        : _CatalogProduct.fromHomePayload(widget.initialProduct!);
    _bagItems = [];
    _refreshBackendData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialDetailProduct = _initialDetailProduct;
    if (initialDetailProduct != null) {
      final related = _sortedProducts
          .where((item) => item.productKey != initialDetailProduct.productKey)
          .toList();
      return _ProductDetailPage(
        product: initialDetailProduct,
        relatedProducts: related.isEmpty ? _sortedProducts : related,
        user: widget.user,
        favoriteKeys: _favoriteKeys,
        onFavoriteTap: _handleFavoriteTap,
        onAddToBag: _addToBag,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildCurrentSurface(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _ShopBottomNav(
                selected: _showBag
                    ? 'Bag'
                    : (_showFavorites
                          ? 'Favorites'
                          : (_showProfile ? 'Profile' : 'Shop')),
                onHomeTap: () => Navigator.pop(context),
                onShopTap: () => setState(() {
                  _showBag = false;
                  _showFavorites = false;
                  _showProfile = false;
                  _showCatalog = false;
                  _showSubCategories = false;
                }),
                onBagTap: () => setState(() {
                  _showBag = true;
                  _showFavorites = false;
                  _showProfile = false;
                  _showCatalog = false;
                  _showSubCategories = false;
                }),
                onFavoritesTap: () => setState(() {
                  _showBag = false;
                  _showFavorites = true;
                  _showProfile = false;
                  _showCatalog = false;
                  _showSubCategories = false;
                }),
                onProfileTap: () => setState(() {
                  _showBag = false;
                  _showFavorites = false;
                  _showProfile = true;
                  _showCatalog = false;
                  _showSubCategories = false;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSurface() {
    if (_isCheckingBackend) {
      return _backendStatusSurface(loading: true);
    }

    if (!_backendAvailable) {
      return _backendStatusSurface(
        message: _backendErrorText ?? 'Khong ket noi duoc backend',
      );
    }

    if (_showBag) {
      return _buildBag();
    } else if (_showFavorites) {
      return _buildFavorites();
    } else if (_showProfile) {
      return _buildProfile();
    } else if (_showCatalog) {
      return _buildCatalog();
    } else if (_showSubCategories) {
      return _buildSubCategories();
    }
    return _buildCategories();
  }

  Widget _backendStatusSurface({bool loading = false, String? message}) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBackendData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: Center(
              child: loading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Text(
                      message ?? 'Khong co du lieu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshBackendData() async {
    if (mounted) {
      setState(() {
        _isCheckingBackend = true;
        _backendErrorText = null;
      });
    }

    final productsResponse = await ApiService.getAllProducts();
    final online =
        productsResponse['statusCode'] == 200 &&
        productsResponse['data'] is List;

    if (!mounted) return;

    if (!online) {
      setState(() {
        _backendAvailable = false;
        _isCheckingBackend = false;
        _backendErrorText = 'Backend dang tat. Vuot xuong de tai lai.';
        _favoriteKeys.clear();
        _favoriteItems.clear();
        _bagItems.clear();
        _promoApplied = false;
      });
      return;
    }

    setState(() {
      _backendAvailable = true;
      _isCheckingBackend = false;
    });

    await _loadFavorites();
    await _loadCart();
  }

  Future<void> _loadFavorites() async {
    if (widget.user.id.isEmpty) return;
    final response = await ApiService.getFavorites(widget.user.id);
    if (!mounted ||
        response['statusCode'] != 200 ||
        response['data'] is! List) {
      if (mounted && !_backendAvailable) {
        setState(() {
          _favoriteKeys.clear();
          _favoriteItems.clear();
        });
      }
      return;
    }
    final items = (response['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(_FavoriteItem.fromJson)
        .toList();
    setState(() {
      _favoriteKeys
        ..clear()
        ..addAll(items.map((item) => item.product.productKey));
      _favoriteItems
        ..clear()
        ..addEntries(
          items.map((item) => MapEntry(item.product.productKey, item)),
        );
    });
  }

  Future<void> _loadCart() async {
    if (widget.user.id.isEmpty) return;
    final response = await ApiService.getCartItems(widget.user.id);
    if (!mounted ||
        response['statusCode'] != 200 ||
        response['data'] is! List) {
      if (mounted && !_backendAvailable) {
        setState(() => _bagItems.clear());
      }
      return;
    }
    final items = (response['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(_BagItem.fromJson)
        .toList();
    setState(() {
      _bagItems
        ..clear()
        ..addAll(items);
    });
  }

  Widget _header(String title) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_showBag) {
                setState(() => _showBag = false);
              } else if (_showFavorites) {
                setState(() => _showFavorites = false);
              } else if (_showProfile) {
                setState(() => _showProfile = false);
              } else if (_showCatalog) {
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
          IconButton(
            onPressed: _openVisualSearch,
            icon: const Icon(Icons.search, size: 25),
          ),
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
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshBackendData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'VIEW ALL ITEMS',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Choose category',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshBackendData,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 104),
              itemCount: _subCategories.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  _subCategories[index],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  _selectedCategory = _subCategories[index];
                  _openCatalog();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalog() {
    final products = _sortedProducts;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBackendData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
        children: [
          _header(_selectedCategory),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
          Row(
            children: [
              Flexible(
                flex: 3,
                child: TextButton.icon(
                  onPressed: _showFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  label: Text(
                    'Filters',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 6,
                child: TextButton.icon(
                  onPressed: _showSortSheet,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.swap_vert,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  label: Text(
                    _sortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CatalogViewToggle(
                gridMode: _gridMode,
                onTap: () => setState(() => _gridMode = !_gridMode),
              ),
            ],
          ),
          if (_gridMode)
            _ProductGrid(
              products: products,
              favoriteKeys: _favoriteKeys,
              onProductTap: _openProductDetail,
              onFavoriteTap: _handleFavoriteTap,
            )
          else
            ...products
                .take(4)
                .map(
                  (product) => _ProductListTile(
                    product: product,
                    favorite: _favoriteKeys.contains(product.productKey),
                    onTap: () => _openProductDetail(product),
                    onFavoriteTap: () => _handleFavoriteTap(product),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFavorites() {
    final items = _favoriteItems.values.toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBackendData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Favorites',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openVisualSearch,
                icon: const Icon(Icons.search, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                selected: true,
                showCheckmark: false,
                label: Text(index == 0 ? 'Summer' : _chips[index]),
                onSelected: (_) {},
                selectedColor: AppColors.textPrimary,
                backgroundColor: AppColors.textPrimary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                labelStyle: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CatalogToolbar(
            sortLabel: _sortLabel,
            gridMode: _gridMode,
            onFilterTap: _showFilters,
            onSortTap: _showSortSheet,
            onViewTap: () => setState(() => _gridMode = !_gridMode),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Center(
                child: Text(
                  'No favorites yet',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else if (_gridMode)
            _FavoriteGrid(
              items: items,
              onTap: (item) => _openProductDetail(item.product),
              onRemove: _removeFavoriteItem,
              onAddToBag: _addFavoriteToBag,
            )
          else
            ...items.map(
              (item) => _FavoriteListTile(
                item: item,
                onTap: () => _openProductDetail(item.product),
                onRemove: () => _removeFavoriteItem(item),
                onAddToBag: () => _addFavoriteToBag(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBag() {
    final subtotal = _bagSubtotal;
    final discount = _promoApplied ? 12 : 0;
    final total = (subtotal - discount).clamp(0, subtotal);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBackendData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 130),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Bag',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openVisualSearch,
                icon: const Icon(Icons.search, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_bagItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Center(
                child: Text(
                  'Your bag is empty',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ..._bagItems.map(
              (item) => _BagProductTile(
                item: item,
                onMinus: () => _changeBagQuantity(item, -1),
                onPlus: () => _changeBagQuantity(item, 1),
                onAddFavorite: () => _addBagItemToFavorites(item),
                onDelete: () => setState(() => _bagItems.remove(item)),
              ),
            ),
          const SizedBox(height: 12),
          _PromoField(
            controller: _promoController,
            applied: _promoApplied,
            onClear: () => setState(() {
              _promoController.clear();
              _promoApplied = false;
            }),
            onSubmit: _handlePromoSubmit,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Total amount:',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$total\$',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _bagItems.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CheckoutPage(
                          subtotal: subtotal,
                          discount: discount,
                        ),
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.textSecondary,
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'CHECK OUT',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = widget.user;
    final fullName = [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final displayName = fullName.isEmpty ? 'Fashion User' : fullName;
    final orderCount = _bagItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBackendData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My profile',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openVisualSearch,
                icon: const Icon(Icons.search, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if ((user.phoneNumber ?? '').isNotEmpty)
                      Text(
                        user.phoneNumber!,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ProfileMenuRow(
            title: 'My orders',
            subtitle: orderCount == 0
                ? 'No current bag items'
                : 'Currently $orderCount items in your bag',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ProfileOrdersPage(
                  items: List<_BagItem>.from(_bagItems),
                  subtotal: _bagSubtotal,
                  discount: _promoApplied ? 12 : 0,
                ),
              ),
            ),
          ),
          _ProfileMenuRow(
            title: 'Shipping addresses',
            subtitle: '3 addresses',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _ShippingAddressesPage()),
            ),
          ),
          _ProfileMenuRow(
            title: 'Payment methods',
            subtitle: 'Visa **34',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PaymentMethodsPage()),
            ),
          ),
          _ProfileMenuRow(
            title: 'Promocodes',
            subtitle: _promoApplied
                ? 'Applied ${_promoController.text}'
                : 'You have special promocodes',
            onTap: _showPromoCodesSheet,
          ),
          _ProfileMenuRow(
            title: 'My reviews',
            subtitle: 'Reviews for ${_favoriteKeys.length} items',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _MyReviewsProfilePage(
                  products: _allSearchProducts,
                  user: widget.user,
                ),
              ),
            ),
          ),
          _ProfileMenuRow(
            title: 'Settings',
            subtitle: 'Notifications, password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ProfileSettingsPage(user: widget.user),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CatalogProduct> get _sortedProducts {
    if (!_backendAvailable) return const [];

    final products = [
      ...(_catalogData[_selectedChip] ?? _catalogData['T-shirts']!),
    ];

    products.removeWhere(
      (product) =>
          product.price < _catalogFilter.priceRange.start.round() ||
          product.price > _catalogFilter.priceRange.end.round(),
    );

    if (_catalogFilter.brands.isNotEmpty) {
      products.removeWhere(
        (product) => !_catalogFilter.brands.contains(product.brand),
      );
    }

    switch (_sortLabel) {
      case 'Popular':
        products.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          return ratingCompare == 0
              ? b.reviews.compareTo(a.reviews)
              : ratingCompare;
        });
        break;
      case 'Newest':
        products.sort((a, b) => b.productKey.compareTo(a.productKey));
        break;
      case 'Customer review':
        products.sort((a, b) => b.reviews.compareTo(a.reviews));
        break;
      case 'Price: highest to low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price: lowest to high':
      default:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
    }
    return products;
  }

  List<_CatalogProduct> get _allSearchProducts {
    if (!_backendAvailable) return const [];

    final byKey = <String, _CatalogProduct>{};
    for (final products in _catalogData.values) {
      for (final product in products) {
        byKey[product.productKey] = product;
      }
    }
    for (final item in _favoriteItems.values) {
      byKey[item.product.productKey] = item.product;
    }
    for (final item in _bagItems) {
      byKey[item.product.productKey] = item.product;
    }
    return byKey.values.toList();
  }

  Future<void> _showSortSheet() async {
    final nextSort = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SortBySheet(selectedSort: _sortLabel),
    );
    if (nextSort == null || !mounted) return;
    setState(() => _sortLabel = nextSort);
  }

  Future<void> _showFilters() async {
    final nextFilter = await Navigator.push<_CatalogFilter>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FiltersPage(initialFilter: _catalogFilter, brands: _allBrands),
      ),
    );
    if (nextFilter == null || !mounted) return;
    setState(() => _catalogFilter = nextFilter);
  }

  Future<void> _openVisualSearch() async {
    final product = await Navigator.push<_CatalogProduct>(
      context,
      MaterialPageRoute(
        builder: (_) => _VisualSearchPage(products: _allSearchProducts),
      ),
    );
    if (product == null || !mounted) return;
    await _openProductDetail(product);
  }

  void _openSubCategories() {
    setState(() => _showSubCategories = true);
  }

  void _openCatalog() {
    setState(() {
      _selectedChip = 'T-shirts';
      _gridMode = false;
      _showCatalog = true;
      _showFavorites = false;
      _showBag = false;
      _showProfile = false;
    });
  }

  int get _bagSubtotal =>
      _bagItems.fold(0, (total, item) => total + item.totalPrice);

  void _changeBagQuantity(_BagItem item, int delta) {
    setState(() {
      final nextQuantity = item.quantity + delta;
      if (nextQuantity <= 0) {
        _bagItems.remove(item);
      } else {
        item.quantity = nextQuantity;
      }
    });
  }

  void _handlePromoSubmit() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      _showPromoCodesSheet();
      return;
    }
    setState(() {
      _promoController.text = code;
      _promoApplied = true;
    });
  }

  void _showPromoCodesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PromoCodesSheet(
        onApply: (code) {
          setState(() {
            _promoController.text = code;
            _promoApplied = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addToBag(_CatalogProduct product, String size, String color) {
    final selectedSize = size == 'Size' ? 'S' : size;
    _upsertLocalBagItem(
      _BagItem(product: product, color: color, size: selectedSize),
    );
    _saveBagItemToBackend(product: product, size: selectedSize, color: color);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to bag',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _addFavoriteToBag(_FavoriteItem favorite) async {
    final response = await _saveBagItemToBackend(
      product: favorite.product,
      size: favorite.size,
      color: favorite.color,
    );
    if (!mounted) return;

    if (response != null) {
      _upsertLocalBagItem(response);
    } else {
      _upsertLocalBagItem(
        _BagItem(
          product: favorite.product,
          color: favorite.color,
          size: favorite.size,
        ),
      );
    }
    setState(() {
      _showBag = true;
      _showFavorites = false;
      _showCatalog = false;
      _showSubCategories = false;
    });
  }

  Future<_BagItem?> _saveBagItemToBackend({
    required _CatalogProduct product,
    required String size,
    required String color,
  }) async {
    if (widget.user.id.isEmpty) return null;
    final response = await ApiService.addCartItem(
      accountId: widget.user.id,
      productKey: product.productKey,
      productName: product.name,
      brand: product.brand,
      image: product.image,
      price: product.price,
      oldPrice: product.oldPrice,
      discountPercent: product.discountPercent,
      rating: product.rating,
      reviews: product.reviews,
      size: size,
      color: color,
    );
    if (response['statusCode'] != 200 ||
        response['data'] is! Map<String, dynamic>) {
      return null;
    }
    return _BagItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  void _upsertLocalBagItem(_BagItem item) {
    final existingIndex = _bagItems.indexWhere(
      (bagItem) =>
          bagItem.product.productKey == item.product.productKey &&
          bagItem.size == item.size &&
          bagItem.color == item.color,
    );
    setState(() {
      if (existingIndex >= 0) {
        _bagItems[existingIndex].quantity = item.quantity > 1
            ? item.quantity
            : _bagItems[existingIndex].quantity + 1;
      } else {
        _bagItems.insert(0, item);
      }
    });
  }

  Future<void> _addBagItemToFavorites(_BagItem item) async {
    final key = item.product.productKey;
    if (_favoriteKeys.contains(key)) {
      setState(() {
        _showBag = false;
        _showFavorites = true;
      });
      return;
    }

    final response = await ApiService.addFavorite(
      accountId: widget.user.id,
      productKey: key,
      productName: item.product.name,
      brand: item.product.brand,
      image: item.product.image,
      price: item.product.price,
      oldPrice: item.product.oldPrice,
      discountPercent: item.product.discountPercent,
      rating: item.product.rating,
      reviews: item.product.reviews,
      size: item.size,
      color: item.color,
    );
    if (!mounted) return;
    if (response['statusCode'] == 201 || response['statusCode'] == 200) {
      setState(() {
        _favoriteKeys.add(key);
        _favoriteItems[key] = _FavoriteItem(
          product: item.product,
          size: item.size,
          color: item.color,
        );
      });
    }
  }

  Future<void> _handleFavoriteTap(_CatalogProduct product) async {
    final key = product.productKey;
    if (_favoriteKeys.contains(key)) {
      final response = await ApiService.removeFavorite(
        accountId: widget.user.id,
        productKey: key,
      );
      if (!mounted) return;
      if (response['statusCode'] == 204 || response['statusCode'] == 200) {
        setState(() {
          _favoriteKeys.remove(key);
          _favoriteItems.remove(key);
        });
      }
      return;
    }

    final item = await showModalBottomSheet<_FavoriteItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FavoriteSizeSheet(product: product),
    );

    if (item == null || !mounted) return;
    final response = await ApiService.addFavorite(
      accountId: widget.user.id,
      productKey: product.productKey,
      productName: product.name,
      brand: product.brand,
      image: product.image,
      price: product.price,
      oldPrice: product.oldPrice,
      discountPercent: product.discountPercent,
      rating: product.rating,
      reviews: product.reviews,
      size: item.size,
      color: item.color,
    );

    if (!mounted) return;
    if (response['statusCode'] == 201 || response['statusCode'] == 200) {
      setState(() {
        _favoriteKeys.add(key);
        _favoriteItems[key] = item;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['data']['message'] ?? 'Không lưu được yêu thích.',
          ),
        ),
      );
    }
  }

  Future<void> _removeFavoriteItem(_FavoriteItem item) async {
    final response = await ApiService.removeFavorite(
      accountId: widget.user.id,
      productKey: item.product.productKey,
    );
    if (!mounted) return;
    if (response['statusCode'] == 204 || response['statusCode'] == 200) {
      setState(() {
        _favoriteKeys.remove(item.product.productKey);
        _favoriteItems.remove(item.product.productKey);
      });
    }
  }

  Future<void> _openProductDetail(_CatalogProduct product) async {
    final related = _sortedProducts.where((item) => item != product).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductDetailPage(
          product: product,
          relatedProducts: related.isEmpty ? _sortedProducts : related,
          user: widget.user,
          favoriteKeys: _favoriteKeys,
          onFavoriteTap: _handleFavoriteTap,
          onAddToBag: _addToBag,
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
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
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
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _ProductListTile({
    required this.product,
    required this.favorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

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
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: Image.asset(
                    product.image,
                    width: 98,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 52, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          product.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _Stars(
                          rating: product.rating,
                          reviews: product.reviews,
                        ),
                        const Spacer(),
                        Text(
                          '${product.price}\$',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _Heart(favorite: favorite, onTap: onFavoriteTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogViewToggle extends StatelessWidget {
  final bool gridMode;
  final VoidCallback onTap;

  const _CatalogViewToggle({required this.gridMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
      icon: gridMode
          ? const Icon(Icons.view_list, size: 20, color: AppColors.textPrimary)
          : const _FilledGridIcon(),
    );
  }
}

class _FilledGridIcon extends StatelessWidget {
  const _FilledGridIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 16,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: List.generate(
          6,
          (_) => Container(width: 5, height: 5, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<_CatalogProduct> products;
  final Set<String> favoriteKeys;
  final ValueChanged<_CatalogProduct> onProductTap;
  final ValueChanged<_CatalogProduct> onFavoriteTap;

  const _ProductGrid({
    required this.products,
    required this.favoriteKeys,
    required this.onProductTap,
    required this.onFavoriteTap,
  });

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
                        child: _DiscountBadge(
                          percent: product.discountPercent!,
                        ),
                      ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _Heart(
                        favorite: favoriteKeys.contains(product.productKey),
                        onTap: () => onFavoriteTap(product),
                      ),
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
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
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
                      color: product.oldPrice == null
                          ? AppColors.textPrimary
                          : AppColors.primary,
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
  final UserModel user;
  final Set<String> favoriteKeys;
  final ValueChanged<_CatalogProduct> onFavoriteTap;
  final void Function(_CatalogProduct product, String size, String color)
  onAddToBag;
  final VoidCallback? onBackPressed;

  const _ProductDetailPage({
    required this.product,
    required this.relatedProducts,
    required this.user,
    required this.favoriteKeys,
    required this.onFavoriteTap,
    required this.onAddToBag,
    this.onBackPressed,
  });

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  String _selectedSize = 'Size';
  String _selectedColor = 'Black';
  bool _isBackNavigating = false;
  late double _rating;
  late int _reviewCount;

  @override
  void initState() {
    super.initState();
    _rating = widget.product.rating;
    _reviewCount = widget.product.reviews;
    _loadReviewSummary();
  }

  Future<void> _loadReviewSummary() async {
    if (widget.user.id.isEmpty) return;
    final response = await ApiService.getReviewSummary(
      productKey: widget.product.productKey,
      accountId: widget.user.id,
    );
    if (!mounted || response['statusCode'] != 200) return;
    final data = response['data'] as Map<String, dynamic>;
    final backendCountValue = data['count'];
    final backendAverageValue = data['average'];
    final backendCount = backendCountValue is int
        ? backendCountValue
        : int.tryParse('$backendCountValue') ?? 0;
    final backendAverage = backendAverageValue is num
        ? backendAverageValue.toDouble()
        : double.tryParse('$backendAverageValue') ?? 0;
    final totalCount = widget.product.reviews + backendCount;
    final totalRating = totalCount == 0
        ? widget.product.rating
        : ((widget.product.rating * widget.product.reviews) +
                  (backendAverage * backendCount)) /
              totalCount;
    setState(() {
      _reviewCount = totalCount;
      _rating = totalRating;
    });
  }

  Future<void> _openReviews() async {
    final summary = await Navigator.push<_ReviewSummary>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ReviewsPage(product: widget.product, user: widget.user),
      ),
    );
    if (summary == null || !mounted) return;
    setState(() {
      _rating = summary.average;
      _reviewCount = summary.count;
    });
  }

  void _handleBackPressed() {
    if (_isBackNavigating) return;
    _isBackNavigating = true;
    final onBackPressed = widget.onBackPressed;
    if (onBackPressed != null) {
      onBackPressed();
      return;
    }
    Navigator.of(context).maybePop();
  }

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
                padding: EdgeInsets.only(
                  bottom: 104 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _imageGallery(product),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SelectBox(
                            label: _selectedSize,
                            onTap: _showSizeSheet,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectBox(
                            label: _selectedColor,
                            onTap: () => setState(() {
                              _selectedColor = _selectedColor == 'Black'
                                  ? 'White'
                                  : 'Black';
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Heart(
                          favorite: widget.favoriteKeys.contains(
                            product.productKey,
                          ),
                          onTap: () => widget.onFavoriteTap(product),
                        ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                product.name,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _openReviews,
                                child: _Stars(
                                  rating: _rating,
                                  reviews: _reviewCount,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${product.price}.99',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
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
                          shadowColor: AppColors.primary.withValues(
                            alpha: 0.35,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'ADD TO CART',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  const _InfoRow(title: 'Shipping info'),
                  const _InfoRow(title: 'Support'),
                  if (widget.relatedProducts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'You can also like this',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.relatedProducts.length} items',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
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
                          favorite: widget.favoriteKeys.contains(
                            widget.relatedProducts[index].productKey,
                          ),
                          onFavoriteTap: () => widget.onFavoriteTap(
                            widget.relatedProducts[index],
                          ),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _ProductDetailPage(
                                  product: widget.relatedProducts[index],
                                  relatedProducts: widget.relatedProducts
                                      .where(
                                        (item) =>
                                            item !=
                                            widget.relatedProducts[index],
                                      )
                                      .toList(),
                                  user: widget.user,
                                  favoriteKeys: widget.favoriteKeys,
                                  onFavoriteTap: widget.onFavoriteTap,
                                  onAddToBag: widget.onAddToBag,
                                  onBackPressed: widget.onBackPressed,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
            onPressed: _handleBackPressed,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              18 + MediaQuery.paddingOf(context).bottom,
            ),
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
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
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
                          backgroundColor: selected
                              ? AppColors.primary
                              : AppColors.white,
                          foregroundColor: selected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : const Color(0xFFDADADA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                    onPressed: () {
                      widget.onAddToBag(
                        widget.product,
                        _selectedSize,
                        _selectedColor,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'ADD TO CART',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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

class _CatalogToolbar extends StatelessWidget {
  final String sortLabel;
  final bool gridMode;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final VoidCallback onViewTap;

  const _CatalogToolbar({
    required this.sortLabel,
    required this.gridMode,
    required this.onFilterTap,
    required this.onSortTap,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: TextButton.icon(
            onPressed: onFilterTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.filter_list,
              color: AppColors.textPrimary,
              size: 20,
            ),
            label: Text(
              'Filters',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 6,
          child: TextButton.icon(
            onPressed: onSortTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.swap_vert,
              color: AppColors.textPrimary,
              size: 20,
            ),
            label: Text(
              sortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CatalogViewToggle(gridMode: gridMode, onTap: onViewTap),
      ],
    );
  }
}

class _SortBySheet extends StatelessWidget {
  final String selectedSort;

  const _SortBySheet({required this.selectedSort});

  static const options = [
    'Popular',
    'Newest',
    'Customer review',
    'Price: lowest to high',
    'Price: highest to low',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final selected = option == selectedSort;
              return InkWell(
                onTap: () => Navigator.pop(context, option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: selected ? AppColors.primary : AppColors.white,
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      color: selected ? AppColors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CatalogFilter {
  final RangeValues priceRange;
  final String? color;
  final Set<String> sizes;
  final String category;
  final Set<String> brands;

  const _CatalogFilter({
    required this.priceRange,
    required this.color,
    required this.sizes,
    required this.category,
    required this.brands,
  });

  factory _CatalogFilter.defaults() {
    return const _CatalogFilter(
      priceRange: RangeValues(0, 160),
      color: null,
      sizes: <String>{},
      category: 'All',
      brands: <String>{},
    );
  }

  _CatalogFilter copyWith({
    RangeValues? priceRange,
    String? color,
    bool clearColor = false,
    Set<String>? sizes,
    String? category,
    Set<String>? brands,
  }) {
    return _CatalogFilter(
      priceRange: priceRange ?? this.priceRange,
      color: clearColor ? null : (color ?? this.color),
      sizes: sizes ?? this.sizes,
      category: category ?? this.category,
      brands: brands ?? this.brands,
    );
  }
}

class _FiltersPage extends StatefulWidget {
  final _CatalogFilter initialFilter;
  final List<String> brands;

  const _FiltersPage({required this.initialFilter, required this.brands});

  @override
  State<_FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<_FiltersPage> {
  late RangeValues _priceRange;
  String? _color;
  late Set<String> _sizes;
  late String _category;
  late Set<String> _brands;

  static const _colors = <String, Color>{
    'Black': Color(0xFF111111),
    'White': Color(0xFFF8F8F8),
    'Red': AppColors.primary,
    'Taupe': Color(0xFFC3B6B6),
    'Beige': Color(0xFFE7B978),
    'Navy': Color(0xFF172B86),
  };

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialFilter.priceRange;
    _color = widget.initialFilter.color;
    _sizes = {...widget.initialFilter.sizes};
    _category = widget.initialFilter.category;
    _brands = {...widget.initialFilter.brands};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Filters',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, _CatalogFilter.defaults()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Discard',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _CatalogFilter(
                      priceRange: _priceRange,
                      color: _color,
                      sizes: _sizes,
                      category: _category,
                      brands: _brands,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          _FilterTitle('Price range'),
          Row(
            children: [
              Text(
                '\$${_priceRange.start.round()}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '\$${_priceRange.end.round()}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 160,
            divisions: 32,
            activeColor: AppColors.primary,
            inactiveColor: const Color(0xFFD8D8D8),
            onChanged: (value) => setState(() => _priceRange = value),
          ),
          const Divider(height: 28),
          _FilterTitle('Colors'),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: _colors.entries.map((entry) {
              final selected = _color == entry.key;
              return InkWell(
                onTap: () => setState(() {
                  _color = selected ? null : entry.key;
                }),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDADADA),
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                      border: entry.key == 'White'
                          ? Border.all(color: const Color(0xFFEDEDED))
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 28),
          _FilterTitle('Sizes'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
              final selected = _sizes.contains(size);
              return SizedBox(
                width: 52,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    selected ? _sizes.remove(size) : _sizes.add(size);
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: selected
                        ? AppColors.primary
                        : AppColors.white,
                    foregroundColor: selected
                        ? AppColors.white
                        : AppColors.textPrimary,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDADADA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(size),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 28),
          _FilterTitle('Category'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['All', 'Women', 'Men', 'Boys', 'Girls'].map((category) {
              final selected = _category == category;
              return SizedBox(
                width: 78,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => setState(() => _category = category),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: selected
                        ? AppColors.primary
                        : AppColors.white,
                    foregroundColor: selected
                        ? AppColors.white
                        : AppColors.textPrimary,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDADADA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(category),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 28),
          InkWell(
            onTap: _openBrandList,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _brands.isEmpty
                              ? 'Choose brands'
                              : _brands.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBrandList() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _BrandFilterPage(brands: widget.brands, selectedBrands: _brands),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _brands = result);
  }
}

class _FilterTitle extends StatelessWidget {
  final String text;

  const _FilterTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BrandFilterPage extends StatefulWidget {
  final List<String> brands;
  final Set<String> selectedBrands;

  const _BrandFilterPage({required this.brands, required this.selectedBrands});

  @override
  State<_BrandFilterPage> createState() => _BrandFilterPageState();
}

class _BrandFilterPageState extends State<_BrandFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedBrands;

  @override
  void initState() {
    super.initState();
    _selectedBrands = {...widget.selectedBrands};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final brands = widget.brands
        .where((brand) => brand.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Brand',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, <String>{}),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedBrands),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                icon: const Icon(Icons.search, size: 18),
                hintText: 'Search',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...brands.map((brand) {
            final selected = _selectedBrands.contains(brand);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                brand,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              trailing: Checkbox(
                value: selected,
                activeColor: AppColors.primary,
                onChanged: (_) => setState(() {
                  selected
                      ? _selectedBrands.remove(brand)
                      : _selectedBrands.add(brand);
                }),
              ),
              onTap: () => setState(() {
                selected
                    ? _selectedBrands.remove(brand)
                    : _selectedBrands.add(brand);
              }),
            );
          }),
        ],
      ),
    );
  }
}

enum _VisualSearchMode { intro, crop, finding, results }

class _VisualSearchPage extends StatefulWidget {
  final List<_CatalogProduct> products;

  const _VisualSearchPage({required this.products});

  @override
  State<_VisualSearchPage> createState() => _VisualSearchPageState();
}

class _VisualSearchPageState extends State<_VisualSearchPage> {
  final ImagePicker _picker = ImagePicker();
  _VisualSearchMode _mode = _VisualSearchMode.intro;
  File? _image;
  List<_CatalogProduct> _results = const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  String get _title {
    switch (_mode) {
      case _VisualSearchMode.crop:
        return 'Crop the item';
      case _VisualSearchMode.finding:
        return 'Visual search';
      case _VisualSearchMode.results:
        return 'Similar results';
      case _VisualSearchMode.intro:
        return 'Visual search';
    }
  }

  Widget _body() {
    switch (_mode) {
      case _VisualSearchMode.crop:
        return _cropBody();
      case _VisualSearchMode.finding:
        return _findingBody();
      case _VisualSearchMode.results:
        return _resultsBody();
      case _VisualSearchMode.intro:
        return _introBody();
    }
  }

  Widget _introBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/T-shirt7.webp', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.52)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Search for an outfit by taking a photo or uploading an image',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'TAKE A PHOTO',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'UPLOAD AN IMAGE',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cropBody() {
    final image = _image;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image == null)
                const ColoredBox(color: Color(0xFFECECEC))
              else
                Image.file(image, fit: BoxFit.cover),
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(painter: _CropCornerPainter()),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 104 + MediaQuery.paddingOf(context).bottom,
          color: AppColors.white,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 18),
          child: InkWell(
            onTap: _findSimilarProducts,
            customBorder: const CircleBorder(),
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _findingBody() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, color: AppColors.primary, size: 44),
          const SizedBox(height: 18),
          Text(
            'Finding similar\nresults...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsBody() {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No similar products found',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) => _VisualResultCard(
        product: _results[index],
        onTap: () => Navigator.pop(context, _results[index]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _image = File(picked.path);
      _mode = _VisualSearchMode.crop;
    });
  }

  void _findSimilarProducts() {
    setState(() => _mode = _VisualSearchMode.finding);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _results = _matchProducts();
        _mode = _VisualSearchMode.results;
      });
    });
  }

  List<_CatalogProduct> _matchProducts() {
    final products = widget.products;
    if (products.isEmpty) return const [];
    final fileName = (_image?.path.split(RegExp(r'[\\/]')).last ?? '')
        .toLowerCase();
    final tokens = fileName
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 2)
        .toSet();

    if (tokens.isEmpty) {
      return products.take(8).toList();
    }

    final scored =
        products
            .map((product) {
              final haystack =
                  '${product.productKey} ${product.name} ${product.brand} ${product.image}'
                      .toLowerCase();
              final score = tokens.where(haystack.contains).length;
              return MapEntry(product, score);
            })
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (scored.isEmpty) {
      return products.take(8).toList();
    }
    return scored.map((entry) => entry.key).take(8).toList();
  }
}

class _VisualResultCard extends StatelessWidget {
  final _CatalogProduct product;
  final VoidCallback onTap;

  const _VisualResultCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                product.image,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 7),
          _Stars(rating: product.rating, reviews: product.reviews),
          Text(
            product.brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Text(
            '${product.price}\$',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CropCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const length = 28.0;

    canvas.drawLine(Offset.zero, const Offset(length, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, length), paint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FavoriteSizeSheet extends StatefulWidget {
  final _CatalogProduct product;

  const _FavoriteSizeSheet({required this.product});

  @override
  State<_FavoriteSizeSheet> createState() => _FavoriteSizeSheetState();
}

class _FavoriteSizeSheetState extends State<_FavoriteSizeSheet> {
  String _selectedSize = 'S';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select size',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
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
                  onPressed: () => setState(() => _selectedSize = size),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? AppColors.primary
                        : AppColors.white,
                    foregroundColor: selected
                        ? AppColors.white
                        : AppColors.textPrimary,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDADADA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _FavoriteItem(
                  product: widget.product,
                  size: _selectedSize,
                  color: 'Black',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'ADD TO FAVORITES',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteListTile extends StatelessWidget {
  final _FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToBag;

  const _FavoriteListTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
    required this.onAddToBag,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 126,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: Image.asset(
                    product.image,
                    width: 98,
                    height: 126,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 48, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Color: ${item.color}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Size: ${item.size}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '${product.price}\$',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _Stars(
                                  rating: product.rating,
                                  reviews: product.reviews,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                onTap: onRemove,
                child: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _BagButton(onTap: onAddToBag),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteGrid extends StatelessWidget {
  final List<_FavoriteItem> items;
  final ValueChanged<_FavoriteItem> onTap;
  final ValueChanged<_FavoriteItem> onRemove;
  final ValueChanged<_FavoriteItem> onAddToBag;

  const _FavoriteGrid({
    required this.items,
    required this.onTap,
    required this.onRemove,
    required this.onAddToBag,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final product = item.product;
        return InkWell(
          onTap: () => onTap(item),
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
                        child: _DiscountBadge(
                          percent: product.discountPercent!,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => onRemove(item),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _BagButton(onTap: () => onAddToBag(item)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _Stars(rating: product.rating, reviews: product.reviews),
              Text(
                product.brand,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Color: ${item.color}      Size: ${item.size}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '${product.price}\$',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BagButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BagButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.white,
          size: 19,
        ),
      ),
    );
  }
}

class _ReviewsPage extends StatefulWidget {
  final _CatalogProduct product;
  final UserModel user;

  const _ReviewsPage({required this.product, required this.user});

  @override
  State<_ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<_ReviewsPage> {
  bool _loading = true;
  bool _withPhotoOnly = false;
  bool _hasReviewed = false;
  double _backendAverage = 0;
  int _backendCount = 0;
  List<_ProductReviewData> _backendReviews = const [];

  int get _totalCount => widget.product.reviews + _backendCount;

  double get _totalAverage {
    if (_totalCount == 0) return widget.product.rating;
    return ((widget.product.rating * widget.product.reviews) +
            (_backendAverage * _backendCount)) /
        _totalCount;
  }

  List<_ProductReviewData> get _visibleReviews {
    final reviews = [..._backendReviews, ..._seedReviews(widget.product)];
    if (!_withPhotoOnly) return reviews;
    return reviews.where((review) => review.photoUrls.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final responses = await Future.wait([
      ApiService.getReviewSummary(
        productKey: widget.product.productKey,
        accountId: widget.user.id,
      ),
      ApiService.getReviews(widget.product.productKey),
    ]);

    if (!mounted) return;
    final summary = responses[0];
    final reviews = responses[1];
    if (summary['statusCode'] == 200) {
      final data = summary['data'] as Map<String, dynamic>;
      final count = data['count'];
      final average = data['average'];
      _backendCount = count is int ? count : int.tryParse('$count') ?? 0;
      _backendAverage = average is num
          ? average.toDouble()
          : double.tryParse('$average') ?? 0;
      _hasReviewed = data['reviewed'] == true;
    }
    if (reviews['statusCode'] == 200 && reviews['data'] is List) {
      _backendReviews = (reviews['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_ProductReviewData.fromJson)
          .toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _openWriteReviewSheet() async {
    if (_hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã đánh giá sản phẩm này rồi.')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _WriteReviewSheet(product: widget.product, user: widget.user),
    );

    if (created == true) {
      await _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        Navigator.pop(
          context,
          _ReviewSummary(count: _totalCount, average: _totalAverage),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(
              context,
              _ReviewSummary(count: _totalCount, average: _totalAverage),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
            ),
          ),
          title: Text(
            'Rating and reviews',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
                    children: [
                      Text(
                        'Rating&Reviews',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _totalAverage.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '$_totalCount ratings',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 28),
                          Expanded(child: _RatingBars(average: _totalAverage)),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Text(
                            '$_totalCount reviews',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Checkbox(
                            value: _withPhotoOnly,
                            activeColor: AppColors.textPrimary,
                            onChanged: (value) =>
                                setState(() => _withPhotoOnly = value ?? false),
                          ),
                          Text(
                            'With photo',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._visibleReviews.map(
                        (review) => _ReviewCard(review: review),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 20 + MediaQuery.paddingOf(context).bottom,
                    child: ElevatedButton.icon(
                      onPressed: _openWriteReviewSheet,
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        _hasReviewed ? 'Reviewed' : 'Write a review',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final _CatalogProduct product;
  final UserModel user;

  const _WriteReviewSheet({required this.product, required this.user});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  int _rating = 0;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (photo == null || !mounted) return;
    setState(() => _photos.add(photo));
  }

  Future<void> _sendReview() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (_rating == 0 || _controller.text.trim().isEmpty) {
      setState(() => _errorText = 'Chọn sao và nhập nội dung đánh giá nha.');
      return;
    }

    if (widget.user.id.isEmpty) {
      setState(() => _errorText = 'Không tìm thấy tài khoản đăng nhập.');
      return;
    }

    setState(() => _submitting = true);
    final uploadedUrls = <String>[];
    for (final photo in _photos) {
      final upload = await ApiService.uploadReviewPhoto(File(photo.path));
      if (upload['statusCode'] == 201) {
        uploadedUrls.add(upload['data']['url']);
      } else {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _errorText =
              upload['data']['message'] ??
              'Upload ảnh thất bại. Kiểm tra backend/IP mạng.';
        });
        return;
      }
    }

    final response = await ApiService.createReview(
      productKey: widget.product.productKey,
      productName: widget.product.name,
      accountId: widget.user.id,
      rating: _rating,
      comment: _controller.text.trim(),
      photoUrls: uploadedUrls,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (response['statusCode'] == 201) {
      Navigator.pop(context, true);
      return;
    }

    final message =
        response['data']['message'] == 'ACCOUNT_ALREADY_REVIEWED_PRODUCT'
        ? 'Bạn đã đánh giá sản phẩm này rồi.'
        : response['data']['message'] ??
              'Không gửi được đánh giá. Kiểm tra backend/IP mạng.';
    setState(() => _errorText = message);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        18 + MediaQuery.paddingOf(context).bottom + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'What is you rate?',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final active = value <= _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  active ? Icons.star : Icons.star_border,
                  color: active
                      ? const Color(0xFFFFBA49)
                      : AppColors.textSecondary,
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Please share your opinion\nabout the product',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Your review',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._photos.map(
                  (photo) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(photo.path),
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _takePhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 92,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add your photos',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_errorText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorText!,
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _sendReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'SEND REVIEW',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _ProductReviewData review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.accountName,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ReviewStars(rating: review.rating),
              const Spacer(),
              Text(
                review.displayDate,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: GoogleFonts.inter(fontSize: 13, height: 1.35),
          ),
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = review.photoUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: url.startsWith('assets/')
                        ? Image.asset(
                            url,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _absoluteImageUrl(url),
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 82,
                              height: 82,
                              color: const Color(0xFFE8E8E8),
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewStars extends StatelessWidget {
  final int rating;

  const _ReviewStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final active = index < rating;
        return Icon(
          active ? Icons.star : Icons.star_border,
          color: active ? const Color(0xFFFFBA49) : AppColors.textSecondary,
          size: 13,
        );
      }),
    );
  }
}

class _RatingBars extends StatelessWidget {
  final double average;

  const _RatingBars({required this.average});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final value = (average / stars).clamp(0.08, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(
                    stars,
                    (_) => const Icon(
                      Icons.star,
                      size: 12,
                      color: Color(0xFFFFBA49),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: value,
                    backgroundColor: const Color(0xFFE8E8E8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ProductReviewData {
  final String accountName;
  final int rating;
  final String comment;
  final List<String> photoUrls;
  final DateTime? createdAt;

  const _ProductReviewData({
    required this.accountName,
    required this.rating,
    required this.comment,
    this.photoUrls = const [],
    this.createdAt,
  });

  factory _ProductReviewData.fromJson(Map<String, dynamic> json) {
    final rawPhotos = '${json['photoUrls'] ?? ''}';
    return _ProductReviewData(
      accountName: json['accountName'] ?? 'Customer',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse('${json['rating']}') ?? 0,
      comment: json['comment'] ?? '',
      photoUrls: rawPhotos.isEmpty
          ? const []
          : rawPhotos.split(',').where((url) => url.trim().isNotEmpty).toList(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  String get displayDate {
    final date = createdAt;
    if (date == null) return 'Today';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _ReviewSummary {
  final int count;
  final double average;

  const _ReviewSummary({required this.count, required this.average});
}

List<_ProductReviewData> _seedReviews(_CatalogProduct product) {
  return [
    _ProductReviewData(
      accountName: 'Helene Moore',
      rating: product.rating.round().clamp(1, 5),
      comment:
          'The ${product.name} is great! Very classy and comfortable. It fits perfectly and the material feels soft for everyday wear.',
    ),
    const _ProductReviewData(
      accountName: 'Kim Shine',
      rating: 4,
      comment:
          'I loved this product so much as soon as I tried it on. The color is easy to match and the fit is flattering.',
      photoUrls: ['assets/images/new1.png', 'assets/images/clothes.jpg'],
    ),
    const _ProductReviewData(
      accountName: 'Matilda Brown',
      rating: 4,
      comment:
          'Nice quality for the price. I would buy another color because it works well for casual outfits.',
    ),
  ];
}

String _absoluteImageUrl(String url) {
  if (url.startsWith('http')) return url;
  if (url.startsWith('assets/')) return url;
  final apiRoot = ApiService.baseUrl.replaceFirst(RegExp(r'/api$'), '');
  return '$apiRoot$url';
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
          title: Text(
            title,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(height: 1, color: Color(0xFFE8E8E8)),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final _CatalogProduct product;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _RelatedCard({
    required this.product,
    required this.favorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

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
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _Heart(favorite: favorite, onTap: onFavoriteTap),
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
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
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
                    color: product.oldPrice == null
                        ? AppColors.textPrimary
                        : AppColors.primary,
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
    final visibleReviews = reviews < 0 ? 0 : reviews;

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
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Heart extends StatelessWidget {
  final bool favorite;
  final VoidCallback onTap;

  const _Heart({required this.favorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '-$percent%',
        style: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BagProductTile extends StatelessWidget {
  final _BagItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAddFavorite;
  final VoidCallback onDelete;

  const _BagProductTile({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onAddFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            child: Image.asset(
              item.product.image,
              width: 88,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        iconSize: 18,
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'favorite') {
                            onAddFavorite();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'favorite',
                            child: Text('Add to favorites'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete from the list'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Color: ${item.color}    Size: ${item.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _QuantityButton(icon: Icons.remove, onTap: onMinus),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _QuantityButton(icon: Icons.add, onTap: onPlus),
                      const Spacer(),
                      Text(
                        '${item.totalPrice}\$',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
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
        child: Icon(icon, color: AppColors.textSecondary, size: 15),
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _PromoField({
    required this.controller,
    required this.applied,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter your promo code',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
          if (applied)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: onSubmit,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoCodesSheet extends StatelessWidget {
  final ValueChanged<String> onApply;

  const _PromoCodesSheet({required this.onApply});

  @override
  Widget build(BuildContext context) {
    final promos = const [
      _PromoCodeData(
        '10',
        'Personal offer',
        'mypromocode2020',
        '6 days remaining',
      ),
      _PromoCodeData('15', 'Summer Sale', 'summer2020', '23 days remaining'),
      _PromoCodeData(
        '22',
        'Personal offer',
        'mypromocode2020',
        '6 days remaining',
      ),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.88,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _SheetPromoInput(),
          const SizedBox(height: 18),
          Text(
            'Your Promo Codes',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...promos.map(
            (promo) => _PromoCodeCard(data: promo, onApply: onApply),
          ),
        ],
      ),
    );
  }
}

class _SheetPromoInput extends StatelessWidget {
  const _SheetPromoInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Enter your promo code',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCodeCard extends StatelessWidget {
  final _PromoCodeData data;
  final ValueChanged<String> onApply;

  const _PromoCodeCard({required this.data, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            decoration: BoxDecoration(
              color: data.percent == '22'
                  ? AppColors.textPrimary
                  : AppColors.primary,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(
                    text: data.percent,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const TextSpan(
                    text: '%\noff',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    data.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.remaining,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 74,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => onApply(data.code),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _CheckoutPage extends StatelessWidget {
  final int subtotal;
  final int discount;

  const _CheckoutPage({required this.subtotal, required this.discount});

  @override
  Widget build(BuildContext context) {
    const delivery = 15;
    final order = (subtotal - discount).clamp(0, subtotal);
    final summary = order + delivery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Checkout',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _CheckoutSectionHeader(
              title: 'Shipping address',
              action: 'Change',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _ShippingAddressesPage(),
                ),
              ),
            ),
            const _AddressCard(),
            const SizedBox(height: 24),
            _CheckoutSectionHeader(
              title: 'Payment',
              action: 'Change',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _PaymentMethodsPage()),
              ),
            ),
            const _PaymentSummaryCard(),
            const SizedBox(height: 24),
            Text(
              'Delivery method',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _DeliveryCard(label: 'FedEx', detail: '2-3 days'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _DeliveryCard(label: 'USPS.COM', detail: '2-3 days'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _DeliveryCard(label: 'DHL', detail: '2-3 days'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SummaryRow(label: 'Order:', value: '$order\$'),
            _SummaryRow(label: 'Delivery:', value: '$delivery\$'),
            _SummaryRow(label: 'Summary:', value: '$summary\$'),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const _OrderSuccessPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'SUBMIT ORDER',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _CheckoutSectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(),
      child: Text(
        'Jane Doe\n3 Newbridge Court\nChino Hills, CA 91709, United States',
        style: GoogleFonts.inter(fontSize: 12, height: 1.55),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.credit_card,
            color: AppColors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '****  ****  ****  3947',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String label;
  final String detail;

  const _DeliveryCard({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final color = label == 'DHL'
        ? const Color(0xFFFFC400)
        : (label == 'FedEx' ? const Color(0xFF5B2AA0) : AppColors.textPrimary);
    return Container(
      height: 72,
      decoration: _softCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsPage extends StatefulWidget {
  const _PaymentMethodsPage();

  @override
  State<_PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<_PaymentMethodsPage> {
  int _defaultCard = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Payment methods',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.white,
        onPressed: _showAddCardSheet,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              'Your payment cards',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _PaymentCard(
              dark: true,
              number: '3947',
              expiry: '05/23',
              selected: _defaultCard == 0,
              onSelect: () => setState(() => _defaultCard = 0),
            ),
            const SizedBox(height: 22),
            _PaymentCard(
              dark: false,
              number: '4546',
              expiry: '11/22',
              selected: _defaultCard == 1,
              onSelect: () => setState(() => _defaultCard = 1),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddCardSheet(),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final bool dark;
  final String number;
  final String expiry;
  final bool selected;
  final VoidCallback onSelect;

  const _PaymentCard({
    required this.dark,
    required this.number,
    required this.expiry,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = dark ? const Color(0xFF222222) : const Color(0xFF9F9F9F);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 170,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const Spacer(),
              Text(
                '* * * *  * * * *  * * * *  $number',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Card Holder Name\nJennyfer Doe',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ),
                  Text(
                    'Expiry Date\n$expiry',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.circle, color: Colors.orange, size: 20),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onSelect,
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: AppColors.textPrimary,
                onChanged: (_) => onSelect(),
              ),
              Expanded(
                child: Text(
                  'Use as default payment method',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddCardSheet extends StatelessWidget {
  const _AddCardSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        18 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
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
          const SizedBox(height: 22),
          Text(
            'Add new card',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          const _PlainInput(hint: 'Name on card'),
          const _PlainInput(
            hint: 'Card number',
            initial: '5546 8205 3693 3947',
          ),
          const _PlainInput(hint: 'Expire Date', initial: '05/23'),
          const _PlainInput(hint: 'CVV', initial: '567'),
          Row(
            children: [
              Checkbox(
                value: true,
                activeColor: AppColors.textPrimary,
                onChanged: (_) {},
              ),
              Expanded(
                child: Text(
                  'Set as default payment method',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'ADD CARD',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainInput extends StatelessWidget {
  final String hint;
  final String? initial;

  const _PlainInput({required this.hint, this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          border: InputBorder.none,
        ),
        style: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }
}

class _ShippingAddressesPage extends StatefulWidget {
  const _ShippingAddressesPage();

  @override
  State<_ShippingAddressesPage> createState() => _ShippingAddressesPageState();
}

class _ShippingAddressesPageState extends State<_ShippingAddressesPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final addresses = const [
      ('Jane Doe', '3 Newbridge Court\nChino Hills, CA 91709, United States'),
      ('John Doe', '3 Newbridge Court\nChino Hills, CA 91709, United States'),
      ('John Doe', '51 Riverside\nChino Hills, CA 91709, United States'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Shipping Addresses',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const _AddShippingAddressPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: addresses.length,
          itemBuilder: (context, index) => _ShippingAddressTile(
            name: addresses[index].$1,
            address: addresses[index].$2,
            selected: _selected == index,
            onSelected: () => setState(() => _selected = index),
          ),
        ),
      ),
    );
  }
}

class _ShippingAddressTile extends StatelessWidget {
  final String name;
  final String address;
  final bool selected;
  final VoidCallback onSelected;

  const _ShippingAddressTile({
    required this.name,
    required this.address,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Edit',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address, style: GoogleFonts.inter(fontSize: 12, height: 1.45)),
          const SizedBox(height: 8),
          InkWell(
            onTap: onSelected,
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  activeColor: AppColors.textPrimary,
                  onChanged: (_) => onSelected(),
                ),
                Expanded(
                  child: Text(
                    'Use as the shipping address',
                    style: GoogleFonts.inter(fontSize: 12),
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

class _AddShippingAddressPage extends StatelessWidget {
  const _AddShippingAddressPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Adding Shipping Address',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const _PlainInput(hint: 'Full name'),
            const _PlainInput(hint: 'Address', initial: '3 Newbridge Court'),
            const _PlainInput(hint: 'City', initial: 'Chino Hills'),
            const _PlainInput(
              hint: 'State/Province/Region',
              initial: 'California',
            ),
            const _PlainInput(hint: 'Zip Code (Postal Code)', initial: '91709'),
            const _CountrySelect(),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'SAVE ADDRESS',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountrySelect extends StatelessWidget {
  const _CountrySelect();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Country\nUnited States',
              style: GoogleFonts.inter(fontSize: 12, height: 1.55),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _OrderSuccessPage extends StatelessWidget {
  const _OrderSuccessPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: AppColors.primary.withValues(alpha: 0.95),
                    size: 92,
                  ),
                  Transform.translate(
                    offset: const Offset(-42, -28),
                    child: Icon(
                      Icons.shopping_bag,
                      color: const Color(0xFFFFB300).withValues(alpha: 0.95),
                      size: 58,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                'Success!',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your order will be delivered soon.\nThank you for choosing our app!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, height: 1.35),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'CONTINUE SHOPPING',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

BoxDecoration _softCardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _ProfileMenuRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOrdersPage extends StatefulWidget {
  final List<_BagItem> items;
  final int subtotal;
  final int discount;

  const _ProfileOrdersPage({
    required this.items,
    required this.subtotal,
    required this.discount,
  });

  @override
  State<_ProfileOrdersPage> createState() => _ProfileOrdersPageState();
}

class _ProfileOrdersPageState extends State<_ProfileOrdersPage> {
  String _tab = 'Delivered';

  int get _quantity =>
      widget.items.fold(0, (total, item) => total + item.quantity);

  int get _total =>
      (widget.subtotal - widget.discount).clamp(0, widget.subtotal);

  @override
  Widget build(BuildContext context) {
    final tabs = const ['Delivered', 'Processing', 'Cancelled'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'My Orders',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 23),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(
            'My Orders',
            style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: tabs.map((tab) {
              final selected = _tab == tab;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Center(child: Text(tab)),
                    onSelected: (_) => setState(() => _tab = tab),
                    selectedColor: AppColors.textPrimary,
                    backgroundColor: AppColors.background,
                    side: BorderSide.none,
                    labelStyle: GoogleFonts.inter(
                      color: selected ? AppColors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Center(
                child: Text(
                  'No order items yet',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _tab == 'Delivered' ? 3 : 1,
              (index) => _OrderProfileCard(
                index: index,
                quantity: _quantity,
                total: _total,
                status: _tab,
                onDetails: () => _showOrderDetails(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OrderDetailsSheet(items: widget.items, total: _total),
    );
  }
}

class _OrderProfileCard extends StatelessWidget {
  final int index;
  final int quantity;
  final int total;
  final String status;
  final VoidCallback onDetails;

  const _OrderProfileCard({
    required this.index,
    required this.quantity,
    required this.total,
    required this.status,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final delivered = status == 'Delivered';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order No.19470${34 + index}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '05-12-2019',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Tracking number:',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'IW3475453455',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Quantity:',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$quantity',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'Total Amount:',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$total\$',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 36,
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Details',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                status,
                style: GoogleFonts.inter(
                  color: delivered ? AppColors.success : AppColors.primary,
                  fontSize: 12,
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

class _OrderDetailsSheet extends StatelessWidget {
  final List<_BagItem> items;
  final int total;

  const _OrderDetailsSheet({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Order items',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  item.product.image,
                  width: 52,
                  height: 62,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                item.product.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Color: ${item.color}   Size: ${item.size}   Qty: ${item.quantity}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: Text(
                '${item.totalPrice}\$',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const Divider(height: 28),
          _SummaryRow(label: 'Total:', value: '$total\$'),
        ],
      ),
    );
  }
}

class _ProfileSettingsPage extends StatefulWidget {
  final UserModel user;

  const _ProfileSettingsPage({required this.user});

  @override
  State<_ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<_ProfileSettingsPage> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = [
      widget.user.firstName,
      widget.user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text(
              'Personal information',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _ReadOnlySettingTile(
              label: 'Name',
              value: name.trim().isEmpty ? 'Fashion User' : name,
            ),
            _ReadOnlySettingTile(label: 'Email', value: widget.user.email),
            _ReadOnlySettingTile(
              label: 'Phone number',
              value: widget.user.phoneNumber ?? 'Not updated',
            ),
            const SizedBox(height: 24),
            Text(
              'Password change',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _PasswordInput(
              controller: _currentController,
              label: 'Current password',
            ),
            _PasswordInput(controller: _newController, label: 'New password'),
            _PasswordInput(
              controller: _confirmController,
              label: 'Repeat new password',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _loading ? 'SAVING...' : 'SAVE PASSWORD',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (newPassword.length < 6) {
      _showMessage('Password must be at least 6 characters', false);
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('New password does not match', false);
      return;
    }

    setState(() => _loading = true);
    final response = await ApiService.changePassword(
      accountId: widget.user.id,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    final success =
        response['statusCode'] == 200 && response['data']['success'] == true;
    _showMessage(
      success
          ? 'Password changed successfully'
          : (response['data']['message'] ?? 'Cannot change password'),
      success,
    );

    if (success) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }
  }

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: success ? AppColors.success : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReadOnlySettingTile extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlySettingTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PasswordInput({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softCardDecoration(),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _MyReviewsProfilePage extends StatelessWidget {
  final List<_CatalogProduct> products;
  final UserModel user;

  const _MyReviewsProfilePage({required this.products, required this.user});

  @override
  Widget build(BuildContext context) {
    final reviewedProducts = products
        .where((product) => product.reviews > 0)
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'My reviews',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            'Reviews',
            style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...reviewedProducts.map(
            (product) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: _softCardDecoration(),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      product.image,
                      width: 58,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _Stars(
                          rating: product.rating,
                          reviews: product.reviews,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopBottomNav extends StatelessWidget {
  final String selected;
  final VoidCallback onHomeTap;
  final VoidCallback onShopTap;
  final VoidCallback onBagTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onProfileTap;

  const _ShopBottomNav({
    required this.selected,
    required this.onHomeTap,
    required this.onShopTap,
    required this.onBagTap,
    required this.onFavoritesTap,
    required this.onProfileTap,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MiniNav(
            icon: 'assets/icons/home.svg',
            label: 'Home',
            selected: selected == 'Home',
            onTap: onHomeTap,
          ),
          _MiniNav(
            icon: 'assets/icons/shopping_cart.svg',
            label: 'Shop',
            selected: selected == 'Shop',
            onTap: onShopTap,
          ),
          _MiniNav(
            icon: 'assets/icons/bag.svg',
            label: 'Bag',
            selected: selected == 'Bag',
            onTap: onBagTap,
          ),
          _MiniNav(
            icon: 'assets/icons/favourites.svg',
            label: 'Favorites',
            selected: selected == 'Favorites',
            onTap: onFavoritesTap,
          ),
          _MiniNav(
            icon: 'assets/icons/profile.svg',
            label: 'Profile',
            selected: selected == 'Profile',
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _MiniNav extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _MiniNav({
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
  final String? productKeyOverride;

  const _CatalogProduct({
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    this.oldPrice,
    this.discountPercent,
    required this.rating,
    required this.reviews,
    this.productKeyOverride,
  });

  String get productKey =>
      productKeyOverride ??
      '${brand.toLowerCase()}-${name.toLowerCase()}'
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');

  factory _CatalogProduct.fromFavoriteJson(Map<String, dynamic> json) {
    return _CatalogProduct(
      name: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      image: json['image'] ?? '',
      price: json['price'] is int
          ? json['price']
          : int.tryParse('${json['price']}') ?? 0,
      oldPrice: json['oldPrice'] == null
          ? null
          : int.tryParse('${json['oldPrice']}'),
      discountPercent: json['discountPercent'] == null
          ? null
          : int.tryParse('${json['discountPercent']}'),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse('${json['rating']}') ?? 0,
      reviews: json['reviews'] is int
          ? json['reviews']
          : int.tryParse('${json['reviews']}') ?? 0,
      productKeyOverride: json['productKey']?.toString(),
    );
  }

  factory _CatalogProduct.fromHomePayload(Map<String, dynamic> json) {
    return _CatalogProduct(
      name: (json['productName'] ?? json['name'] ?? 'Product').toString(),
      brand: (json['brand'] ?? 'Fashion').toString(),
      image: (json['image'] ?? 'assets/images/new1.png').toString(),
      price: json['price'] is int
          ? json['price']
          : int.tryParse('${json['price']}') ?? 0,
      oldPrice: json['oldPrice'] == null
          ? null
          : int.tryParse('${json['oldPrice']}'),
      discountPercent: json['discountPercent'] == null
          ? null
          : int.tryParse('${json['discountPercent']}'),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse('${json['rating']}') ?? 5,
      reviews: json['reviews'] is int
          ? json['reviews']
          : int.tryParse('${json['reviews']}') ?? 0,
      productKeyOverride: json['productKey']?.toString(),
    );
  }
}

class _FavoriteItem {
  final _CatalogProduct product;
  final String size;
  final String color;

  const _FavoriteItem({
    required this.product,
    required this.size,
    required this.color,
  });

  factory _FavoriteItem.fromJson(Map<String, dynamic> json) {
    return _FavoriteItem(
      product: _CatalogProduct.fromFavoriteJson(json),
      size: json['size'] ?? 'S',
      color: json['color'] ?? 'Black',
    );
  }
}

class _BagItem {
  final _CatalogProduct product;
  final String color;
  final String size;
  int quantity = 1;

  _BagItem({required this.product, required this.color, required this.size});

  factory _BagItem.fromJson(Map<String, dynamic> json) {
    final product = _CatalogProduct(
      name: (json['productName'] ?? 'Product').toString(),
      brand: (json['brand'] ?? 'Fashion').toString(),
      image: (json['image'] ?? 'assets/images/new1.png').toString(),
      price: json['price'] is int
          ? json['price']
          : int.tryParse('${json['price']}') ?? 0,
      oldPrice: json['oldPrice'] == null
          ? null
          : int.tryParse('${json['oldPrice']}'),
      discountPercent: json['discountPercent'] == null
          ? null
          : int.tryParse('${json['discountPercent']}'),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse('${json['rating']}') ?? 0,
      reviews: json['reviews'] is int
          ? json['reviews']
          : int.tryParse('${json['reviews']}') ?? 0,
      productKeyOverride: json['productKey']?.toString(),
    );
    return _BagItem(
        product: product,
        color: (json['color'] ?? 'Black').toString(),
        size: (json['size'] ?? 'S').toString(),
      )
      ..quantity = json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 1;
  }

  int get totalPrice => product.price * quantity;
}

class _PromoCodeData {
  final String percent;
  final String title;
  final String code;
  final String remaining;

  const _PromoCodeData(this.percent, this.title, this.code, this.remaining);
}

final Map<String, List<_CatalogProduct>> _catalogData = {
  'T-shirts': [
    const _CatalogProduct(
      name: 'T-Shirt SPANISH',
      brand: 'Mango',
      image: 'assets/images/T-shirt1.webp',
      price: 9,
      rating: 4,
      reviews: 3,
    ),
    const _CatalogProduct(
      name: 'Blouse',
      brand: 'Dorothy Perkins',
      image: 'assets/images/blouse1.webp',
      price: 14,
      oldPrice: 21,
      discountPercent: 20,
      rating: 5,
      reviews: 10,
    ),
    const _CatalogProduct(
      name: 'Shirt',
      brand: 'Mango',
      image: 'assets/images/T-shirt2.webp',
      price: 18,
      rating: 0,
      reviews: 0,
    ),
    const _CatalogProduct(
      name: 'Light blouse',
      brand: 'Dorothy Perkins',
      image: 'assets/images/blouse2.webp',
      price: 16,
      oldPrice: 20,
      discountPercent: 20,
      rating: 5,
      reviews: 10,
    ),
    const _CatalogProduct(
      name: 'Pullover',
      brand: 'Mango',
      image: 'assets/images/T-shirt3.webp',
      price: 51,
      rating: 4,
      reviews: 3,
    ),
    const _CatalogProduct(
      name: 'T-shirt',
      brand: 'LOST Ink',
      image: 'assets/images/T-shirt4.webp',
      price: 12,
      rating: 5,
      reviews: 10,
    ),
    const _CatalogProduct(
      name: 'Oversize tee',
      brand: 'Bershka',
      image: 'assets/images/T-shirt5.webp',
      price: 17,
      rating: 3,
      reviews: 5,
    ),
    const _CatalogProduct(
      name: 'Basic T-shirt',
      brand: 'H&M',
      image: 'assets/images/T-shirt6.webp',
      price: 11,
      rating: 4,
      reviews: 8,
    ),
    const _CatalogProduct(
      name: 'Print tee',
      brand: 'Zara',
      image: 'assets/images/T-shirt7.webp',
      price: 22,
      rating: 5,
      reviews: 14,
    ),
    const _CatalogProduct(
      name: 'Cotton T-shirt',
      brand: 'Pull&Bear',
      image: 'assets/images/T-shirt8.webp',
      price: 15,
      rating: 4,
      reviews: 7,
    ),
  ],
  'Crop tops': [
    const _CatalogProduct(
      name: 'Rib crop top',
      brand: 'Stradivarius',
      image: 'assets/images/croptop1webp.webp',
      price: 18,
      rating: 4,
      reviews: 8,
    ),
    const _CatalogProduct(
      name: 'Summer crop',
      brand: 'Mango',
      image: 'assets/images/croptop2.webp',
      price: 16,
      oldPrice: 20,
      discountPercent: 20,
      rating: 5,
      reviews: 11,
    ),
    const _CatalogProduct(
      name: 'Pink crop top',
      brand: 'Bershka',
      image: 'assets/images/croptop3.webp',
      price: 19,
      rating: 3,
      reviews: 4,
    ),
    const _CatalogProduct(
      name: 'Knit crop',
      brand: 'Topshop',
      image: 'assets/images/croptop4.webp',
      price: 24,
      rating: 4,
      reviews: 6,
    ),
    const _CatalogProduct(
      name: 'White crop',
      brand: 'Zara',
      image: 'assets/images/croptop5.webp',
      price: 21,
      rating: 5,
      reviews: 13,
    ),
    const _CatalogProduct(
      name: 'Black crop',
      brand: 'H&M',
      image: 'assets/images/croptop6.webp',
      price: 14,
      rating: 4,
      reviews: 3,
    ),
  ],
  'Blouses': [
    const _CatalogProduct(
      name: 'Blouse',
      brand: 'Dorothy Perkins',
      image: 'assets/images/blouse1.webp',
      price: 14,
      oldPrice: 21,
      discountPercent: 20,
      rating: 5,
      reviews: 10,
    ),
    const _CatalogProduct(
      name: 'Light blouse',
      brand: 'Dorothy Perkins',
      image: 'assets/images/blouse2.webp',
      price: 16,
      oldPrice: 20,
      discountPercent: 20,
      rating: 5,
      reviews: 10,
    ),
    const _CatalogProduct(
      name: 'Silk blouse',
      brand: 'Mango',
      image: 'assets/images/blouse3.jpg',
      price: 34,
      rating: 0,
      reviews: 0,
    ),
    const _CatalogProduct(
      name: 'Office blouse',
      brand: 'Topshop',
      image: 'assets/images/blouse4.jpg',
      price: 31,
      rating: 4,
      reviews: 6,
    ),
    const _CatalogProduct(
      name: 'Pattern blouse',
      brand: 'Zara',
      image: 'assets/images/blouse5.jpg',
      price: 29,
      rating: 3,
      reviews: 5,
    ),
  ],
  'Sleeveless': [
    const _CatalogProduct(
      name: 'Sleeveless top',
      brand: 'Mango',
      image: 'assets/images/sleeveless1.jpg',
      price: 20,
      rating: 4,
      reviews: 3,
    ),
    const _CatalogProduct(
      name: 'White sleeveless',
      brand: 'Zara',
      image: 'assets/images/sleeveless2.jpg',
      price: 22,
      rating: 5,
      reviews: 9,
    ),
    const _CatalogProduct(
      name: 'Linen top',
      brand: 'H&M',
      image: 'assets/images/sleeveless3.webp',
      price: 17,
      rating: 3,
      reviews: 2,
    ),
    const _CatalogProduct(
      name: 'Summer blouse',
      brand: 'Bershka',
      image: 'assets/images/sleeveless4.webp',
      price: 19,
      oldPrice: 25,
      discountPercent: 24,
      rating: 4,
      reviews: 7,
    ),
  ],
  'Shirts': [
    const _CatalogProduct(
      name: 'Check shirt',
      brand: 'Topshop',
      image: 'assets/images/shirt1.jpg',
      price: 51,
      rating: 4,
      reviews: 3,
    ),
    const _CatalogProduct(
      name: 'Denim shirt',
      brand: 'Mango',
      image: 'assets/images/shirt2.jpg',
      price: 39,
      rating: 5,
      reviews: 12,
    ),
    const _CatalogProduct(
      name: 'Classic shirt',
      brand: 'Zara',
      image: 'assets/images/shirt3.jpg',
      price: 28,
      rating: 3,
      reviews: 4,
    ),
    const _CatalogProduct(
      name: 'Loose shirt',
      brand: 'H&M',
      image: 'assets/images/shirt5.jpg',
      price: 24,
      oldPrice: 30,
      discountPercent: 20,
      rating: 4,
      reviews: 8,
    ),
  ],
};

List<String> get _allBrands {
  final brands = <String>{
    'adidas',
    'adidas Originals',
    'Blend',
    'Boutique Moschino',
    'Champion',
    'Diesel',
    'Jack & Jones',
    'Naf Naf',
    'Red Valentino',
    's.Oliver',
  };
  for (final products in _catalogData.values) {
    for (final product in products) {
      brands.add(product.brand);
    }
  }
  final sorted = brands.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
}
