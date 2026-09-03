// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';

import '../OffersModule/OffersApis.dart';
import '../Order Management Module/OrderApis.dart';
import '../RetailerCatalogue/RetailerCatalogueService.dart';
import '../RetailerWishlist/WishlistApis.dart';
import '../Stock Listing Module/StockApis.dart' as stock_module;
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';

enum RetailerSectionStatus { loading, success, empty, error }

enum RetailerProductRole { owner, retailer }

class SectionResult<T> {
  final RetailerSectionStatus status;
  final List<T> items;
  final String? message;

  const SectionResult.success(this.items)
    : status = RetailerSectionStatus.success,
      message = null;

  const SectionResult.empty([this.message])
    : status = RetailerSectionStatus.empty,
      items = const [];

  const SectionResult.error(this.message)
    : status = RetailerSectionStatus.error,
      items = const [];
}

class RetailerHomeData {
  final SectionResult<RetailerBannerModel> banners;
  final SectionResult<RetailerQuickActionModel> quickActions;
  final SectionResult<RetailerCategoryModel> categories;
  final SectionResult<RetailerProductModel> products;
  final SectionResult<RetailerOfferModel> offers;
  final SectionResult<RetailerOrderPreviewModel> recentOrders;
  final SectionResult<RetailerStatisticModel> statistics;
  final int placedOrdersCount;
  final int deliveredOrdersCount;

  const RetailerHomeData({
    required this.banners,
    required this.quickActions,
    required this.categories,
    required this.products,
    required this.offers,
    required this.recentOrders,
    required this.statistics,
    this.placedOrdersCount = 0,
    this.deliveredOrdersCount = 0,
  });

  RetailerHomeData copyWith({
    SectionResult<RetailerBannerModel>? banners,
    SectionResult<RetailerQuickActionModel>? quickActions,
    SectionResult<RetailerCategoryModel>? categories,
    SectionResult<RetailerProductModel>? products,
    SectionResult<RetailerOfferModel>? offers,
    SectionResult<RetailerOrderPreviewModel>? recentOrders,
    SectionResult<RetailerStatisticModel>? statistics,
    int? placedOrdersCount,
    int? deliveredOrdersCount,
  }) {
    return RetailerHomeData(
      banners: banners ?? this.banners,
      quickActions: quickActions ?? this.quickActions,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      offers: offers ?? this.offers,
      recentOrders: recentOrders ?? this.recentOrders,
      statistics: statistics ?? this.statistics,
      placedOrdersCount: placedOrdersCount ?? this.placedOrdersCount,
      deliveredOrdersCount: deliveredOrdersCount ?? this.deliveredOrdersCount,
    );
  }
}

class RetailerBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color accentColor;
  final String targetOfferId;

  const RetailerBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.accentColor,
    this.targetOfferId = '',
  });
}

class RetailerQuickActionModel {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  const RetailerQuickActionModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class RetailerCategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final String imageUrl;

  const RetailerCategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.imageUrl,
  });
}

class RetailerProductModel {
  final String id;
  final String name;
  final String category;
  final String netWeight;
  final String imageUrl;
  final bool isWishlisted;
  final String variantId;
  final stock_module.ProductModel? rawProduct;

  const RetailerProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.netWeight,
    required this.imageUrl,
    this.isWishlisted = false,
    this.variantId = '',
    this.rawProduct,
  });

  RetailerProductModel copyWith({
    bool? isWishlisted,
  }) {
    return RetailerProductModel(
      id: id,
      name: name,
      category: category,
      netWeight: netWeight,
      imageUrl: imageUrl,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      variantId: variantId,
      rawProduct: rawProduct,
    );
  }
}

class RetailerOfferModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final OfferModel? rawOffer;

  const RetailerOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.rawOffer,
  });
}

class RetailerOrderPreviewModel {
  final String id;
  final String orderNo;
  final String status;
  final String date;
  final Color statusColor;
  final OrderModel? rawOrder;

  const RetailerOrderPreviewModel({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.date,
    required this.statusColor,
    this.rawOrder,
  });
}

class RetailerStatisticModel {
  final String id;
  final IconData icon;
  final String value;
  final String label;

  const RetailerStatisticModel({
    required this.id,
    required this.icon,
    required this.value,
    required this.label,
  });
}

abstract class IRetailerHomeRepository {
  Future<RetailerHomeData> fetchHome({bool forceRefresh = false});
  Future<SectionResult<RetailerBannerModel>> fetchBanners();
  Future<SectionResult<RetailerQuickActionModel>> fetchQuickActions();
  Future<SectionResult<RetailerCategoryModel>> fetchCategories();
  Future<SectionResult<RetailerProductModel>> fetchPopularProducts();
  Future<SectionResult<RetailerOfferModel>> fetchLatestOffers();
  Future<SectionResult<RetailerOrderPreviewModel>> fetchRecentOrders();
  Future<SectionResult<RetailerStatisticModel>> fetchStatistics();
}

class RetailerHomeRepository implements IRetailerHomeRepository {
  RetailerHomeRepository({
    RetailerHomeApis? apis,
    stock_module.StockRepository? stockRepository,
    OffersRepository? offersRepository,
    OrderRepository? orderRepository,
    WishlistRepository? wishlistRepository,
  })  : _apis = apis ?? RetailerHomeApis(),
        _stockRepository = stockRepository ?? stock_module.StockRepository.instance,
        _offersRepository = offersRepository ?? OffersRepository(),
        _orderRepository = orderRepository ?? OrderRepository(),
        _wishlistRepository = wishlistRepository ?? WishlistRepository();

  final RetailerHomeApis _apis;
  final stock_module.StockRepository _stockRepository;
  final OffersRepository _offersRepository;
  final OrderRepository _orderRepository;
  final WishlistRepository _wishlistRepository;

  RetailerHomeData? _cache;

  @override
  Future<RetailerHomeData> fetchHome({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    int placedOrders = 0;
    int deliveredOrders = 0;
    try {
      final orders = await _orderRepository.fetchRetailerOrders(
        forceRefresh: forceRefresh,
      );
      placedOrders = orders.length;
      deliveredOrders = orders
          .where((o) => normalizeOrderStatus(o.status) == 'Delivered')
          .length;
    } catch (_) {}

    final results = await Future.wait([
      fetchBanners(),
      fetchQuickActions(),
      fetchCategories(),
      fetchPopularProducts(),
      fetchLatestOffers(),
      fetchRecentOrders(),
      fetchStatistics(),
    ]);

    final data = RetailerHomeData(
      banners: results[0] as SectionResult<RetailerBannerModel>,
      quickActions: results[1] as SectionResult<RetailerQuickActionModel>,
      categories: results[2] as SectionResult<RetailerCategoryModel>,
      products: results[3] as SectionResult<RetailerProductModel>,
      offers: results[4] as SectionResult<RetailerOfferModel>,
      recentOrders: results[5] as SectionResult<RetailerOrderPreviewModel>,
      statistics: results[6] as SectionResult<RetailerStatisticModel>,
      placedOrdersCount: placedOrders,
      deliveredOrdersCount: deliveredOrders,
    );

    _cache = data;
    return data;
  }

  @override
  Future<SectionResult<RetailerBannerModel>> fetchBanners() async {
    try {
      final liveOffers = await _offersRepository.fetchOffers();
      if (liveOffers.isNotEmpty) {
        final bannerList = liveOffers.take(4).map((offer) {
          final rawImg = offer.bannerImage.trim().isNotEmpty
              ? offer.bannerImage.trim()
              : (offer.bannerImages.isNotEmpty ? offer.bannerImages.first : '');
          final img = _sanitizeImageUrl(rawImg);

          return RetailerBannerModel(
            id: offer.id,
            title: offer.title,
            subtitle: offer.note.trim().isNotEmpty
                ? offer.note
                : 'Special wholesale campaign offer',
            imageUrl: img.isNotEmpty ? img : RetailerHomeApis.defaultBannerImage,
            accentColor: AppColors.accentGold,
            targetOfferId: offer.id,
          );
        }).toList();
        return SectionResult.success(bannerList);
      }
    } catch (e) {
      log('fetchBanners live error: $e');
    }
    return _safe(() => _apis.fetchBanners());
  }

  @override
  Future<SectionResult<RetailerQuickActionModel>> fetchQuickActions() =>
      _safe(() => _apis.fetchQuickActions());

  @override
  Future<SectionResult<RetailerCategoryModel>> fetchCategories() async {
    try {
      final stockProducts = await _stockRepository.fetchProducts();
      if (stockProducts.isNotEmpty) {
        final groups = _stockRepository.groupByProductName(stockProducts);
        if (groups.isNotEmpty) {
          final catList = groups.take(8).map((group) {
            return RetailerCategoryModel(
              id: 'cat-${group.productName.replaceAll(' ', '-').toLowerCase()}',
              title: group.productName,
              icon: Icons.diamond_rounded,
              imageUrl: group.imageUrl.isNotEmpty
                  ? group.imageUrl
                  : RetailerHomeApis.defaultProductImage,
            );
          }).toList();
          return SectionResult.success(catList);
        }
      }
    } catch (e) {
      log('fetchCategories live error: $e');
    }
    return _safe(() => _apis.fetchCategories());
  }

  @override
  Future<SectionResult<RetailerProductModel>> fetchPopularProducts() async {
    try {
      final stockProducts = await _stockRepository.fetchProducts();
      if (stockProducts.isNotEmpty) {
        await RetailerWishlistService.instance.ensureLoaded();
        final mappedList = stockProducts.take(10).map((product) {
          final variantId = product.id;
          final isWish = RetailerWishlistService.instance.isWishlisted(product.id);
          final weight = product.weights.netWeight > 0
              ? '${product.weights.netWeight.toStringAsFixed(3)} g'
              : 'N/A';

          return RetailerProductModel(
            id: product.id,
            name: product.productName,
            category: product.productCode.isNotEmpty
                ? 'Code: ${product.productCode}'
                : 'Jewellery SKU',
            netWeight: weight,
            imageUrl: product.primaryImageUrl.isNotEmpty
                ? product.primaryImageUrl
                : RetailerHomeApis.defaultProductImage,
            isWishlisted: isWish,
            variantId: variantId,
            rawProduct: product,
          );
        }).toList();

        return SectionResult.success(mappedList);
      }
    } catch (e) {
      log('fetchPopularProducts live error: $e');
    }
    return _safe(() => _apis.fetchPopularProducts());
  }

  @override
  Future<SectionResult<RetailerOfferModel>> fetchLatestOffers() async {
    try {
      final liveOffers = await _offersRepository.fetchOffers();
      if (liveOffers.isNotEmpty) {
        final offerList = liveOffers.map((offer) {
          final rawImg = offer.bannerImage.trim().isNotEmpty
              ? offer.bannerImage.trim()
              : (offer.bannerImages.isNotEmpty ? offer.bannerImages.first : '');
          final img = _sanitizeImageUrl(rawImg);

          return RetailerOfferModel(
            id: offer.id,
            title: offer.title,
            description: offer.note.trim().isNotEmpty
                ? offer.note
                : 'Special wholesale campaign placeholder.',
            imageUrl: img.isNotEmpty ? img : RetailerHomeApis.defaultBannerImage,
            rawOffer: offer,
          );
        }).toList();

        return SectionResult.success(offerList);
      }
    } catch (e) {
      log('fetchLatestOffers live error: $e');
    }
    return _safe(() => _apis.fetchLatestOffers());
  }

  @override
  Future<SectionResult<RetailerOrderPreviewModel>> fetchRecentOrders() async {
    try {
      final liveOrders = await _orderRepository.fetchRetailerOrders();
      if (liveOrders.isNotEmpty) {
        final recentList = liveOrders.take(5).map((order) {
          final statusText = order.status;
          final color = _statusColor(statusText);

          return RetailerOrderPreviewModel(
            id: order.id,
            orderNo: order.orderNumber,
            status: statusText,
            date: _formatOrderDate(order.orderDate),
            statusColor: color,
            rawOrder: order,
          );
        }).toList();

        return SectionResult.success(recentList);
      }
    } catch (e) {
      log('fetchRecentOrders live error: $e');
    }
    return _safe(() => _apis.fetchRecentOrders());
  }

  @override
  Future<SectionResult<RetailerStatisticModel>> fetchStatistics() async {
    try {
      final retailerId = UserData.instance.id.isNotEmpty
          ? UserData.instance.id
          : UserData.instance.userId;

      int wishlistCount = 0;
      int ordersCount = 0;
      int offersCount = 0;
      int cartCount = 0;

      try {
        final wishlist = await _wishlistRepository.fetchWishlist(retailerId);
        wishlistCount = wishlist.length;
      } catch (_) {
        await RetailerWishlistService.instance.ensureLoaded();
      }

      try {
        final orders = await _orderRepository.fetchRetailerOrders();
        ordersCount = orders.length;
      } catch (_) {}

      try {
        final offers = await _offersRepository.fetchOffers();
        offersCount = offers.length;
      } catch (_) {}

      try {
        final cart = await RetailerCartService.instance.fetchCart(retailerId);
        cartCount = cart.totalItems;
      } catch (_) {}

      final stats = [
        RetailerStatisticModel(
          id: 'stat-wishlist',
          icon: Icons.favorite_rounded,
          value: wishlistCount.toString().padLeft(2, '0'),
          label: RetailerHomeApis.wishlist,
        ),
        RetailerStatisticModel(
          id: 'stat-orders',
          icon: Icons.receipt_long_rounded,
          value: ordersCount.toString().padLeft(2, '0'),
          label: RetailerHomeApis.orders,
        ),
        RetailerStatisticModel(
          id: 'stat-offers',
          icon: Icons.local_offer_rounded,
          value: offersCount.toString().padLeft(2, '0'),
          label: RetailerHomeApis.offers,
        ),
        RetailerStatisticModel(
          id: 'stat-cart',
          icon: Icons.shopping_cart_rounded,
          value: cartCount.toString().padLeft(2, '0'),
          label: RetailerHomeApis.cart,
        ),
      ];

      return SectionResult.success(stats);
    } catch (e) {
      log('fetchStatistics error: $e');
    }
    return _safe(() => _apis.fetchStatistics());
  }

  Future<SectionResult<T>> _safe<T>(Future<List<T>> Function() loader) async {
    try {
      final items = await loader();
      if (items.isEmpty) {
        return const SectionResult.empty('Nothing to show yet.');
      }
      return SectionResult.success(items);
    } catch (_) {
      return const SectionResult.error('Unable to load this section.');
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'accepted':
        return const Color(0xFF16A34A);
      case 'processing':
      case 'in-process':
        return const Color(0xFF2563EB);
      case 'dispatched':
        return const Color(0xFF9333EA);
      case 'delivered':
        return const Color(0xFFD4AF37);
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFEAB308);
    }
  }

  String _formatOrderDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }
}

class RetailerHomeApis {
  static const productCatalogue = 'Product Catalogue';
  static const wishlist = 'Wishlist';
  static const orders = 'Orders';
  static const offers = 'Offers';
  static const cart = 'Cart';
  static const contact = 'Contact';

  static const defaultBannerImage =
      'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?auto=format&fit=crop&w=900&q=80';
  static const defaultProductImage =
      'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=700&q=80';

  Future<List<RetailerBannerModel>> fetchBanners() async {
    return const [
      RetailerBannerModel(
        id: 'banner-new-arrivals',
        title: 'New 22K Bridal Collection',
        subtitle: 'Curated premium designs for verified retailers.',
        imageUrl:
            'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?auto=format&fit=crop&w=900&q=80',
        accentColor: Color(0xFFD4AF37),
      ),
      RetailerBannerModel(
        id: 'banner-festive',
        title: 'Festive Wholesale Offers',
        subtitle: 'Special making charge previews for bulk ordering.',
        imageUrl:
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
        accentColor: Color(0xFF1E3A8A),
      ),
    ];
  }

  Future<List<RetailerQuickActionModel>> fetchQuickActions() async {
    return const [
      RetailerQuickActionModel(
        id: 'catalogue',
        icon: Icons.diamond_rounded,
        title: productCatalogue,
        subtitle: 'Explore wholesale jewellery.',
      ),
      RetailerQuickActionModel(
        id: 'wishlist',
        icon: Icons.favorite_rounded,
        title: wishlist,
        subtitle: 'Review saved designs.',
      ),
      RetailerQuickActionModel(
        id: 'orders',
        icon: Icons.receipt_long_rounded,
        title: orders,
        subtitle: 'Track order activity.',
      ),
      RetailerQuickActionModel(
        id: 'offers',
        icon: Icons.local_offer_rounded,
        title: offers,
        subtitle: 'View active campaigns.',
      ),
      RetailerQuickActionModel(
        id: 'cart',
        icon: Icons.shopping_cart_rounded,
        title: cart,
        subtitle: 'Prepare buying list.',
      ),
      RetailerQuickActionModel(
        id: 'contact',
        icon: Icons.support_agent_rounded,
        title: contact,
        subtitle: 'Reach BBS support.',
      ),
    ];
  }

  Future<List<RetailerCategoryModel>> fetchCategories() async {
    return const [
      RetailerCategoryModel(
        id: 'rings',
        title: 'Gold Rings',
        icon: Icons.radio_button_checked_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=600&q=80',
      ),
      RetailerCategoryModel(
        id: 'necklace',
        title: 'Necklace',
        icon: Icons.workspace_premium_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80',
      ),
      RetailerCategoryModel(
        id: 'bangles',
        title: 'Bangles',
        icon: Icons.circle_outlined,
        imageUrl:
            'https://images.unsplash.com/photo-1611652022419-a9419f74343d?auto=format&fit=crop&w=600&q=80',
      ),
      RetailerCategoryModel(
        id: 'chains',
        title: 'Chains',
        icon: Icons.link_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1629224316810-9d8805b95e76?auto=format&fit=crop&w=600&q=80',
      ),
    ];
  }

  Future<List<RetailerProductModel>> fetchPopularProducts() async {
    return const [
      RetailerProductModel(
        id: 'prd-101',
        name: 'Classic Floral Ring',
        category: 'Gold Rings',
        netWeight: '8.420 g',
        imageUrl:
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=700&q=80',
        isWishlisted: true,
      ),
      RetailerProductModel(
        id: 'prd-102',
        name: 'Temple Necklace Set',
        category: 'Necklace',
        netWeight: '42.850 g',
        imageUrl:
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=700&q=80',
      ),
    ];
  }

  Future<List<RetailerOfferModel>> fetchLatestOffers() async {
    return const [
      RetailerOfferModel(
        id: 'off-101',
        title: 'Bridal Season Preview',
        description: 'Priority access to new bridal SKUs this week.',
        imageUrl:
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=600&q=80',
      ),
    ];
  }

  Future<List<RetailerOrderPreviewModel>> fetchRecentOrders() async {
    return const [
      RetailerOrderPreviewModel(
        id: 'ord-2451',
        orderNo: 'BBS-2451',
        status: 'Accepted',
        date: '03 Aug 2026',
        statusColor: Color(0xFF16A34A),
      ),
    ];
  }

  Future<List<RetailerStatisticModel>> fetchStatistics() async {
    return const [
      RetailerStatisticModel(
        id: 'stat-wishlist',
        icon: Icons.favorite_rounded,
        value: '00',
        label: wishlist,
      ),
      RetailerStatisticModel(
        id: 'stat-orders',
        icon: Icons.receipt_long_rounded,
        value: '00',
        label: orders,
      ),
      RetailerStatisticModel(
        id: 'stat-offers',
        icon: Icons.local_offer_rounded,
        value: '00',
        label: offers,
      ),
      RetailerStatisticModel(
        id: 'stat-cart',
        icon: Icons.shopping_cart_rounded,
        value: '00',
        label: cart,
      ),
    ];
  }
}

String _sanitizeImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('data:image')) return trimmed;
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return '';
  }
  final host = uri.host.toLowerCase();
  if (host.contains('provider.com') ||
      host.contains('example.com') ||
      host == 'localhost' ||
      host == '127.0.0.1') {
    return '';
  }
  return trimmed;
}
