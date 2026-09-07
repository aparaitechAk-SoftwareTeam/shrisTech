// ignore_for_file: file_names

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import 'AddEditOfferScreen.dart';
import 'OfferDetailedScreen.dart';
import 'OfferScreenWidget.dart';
import 'OffersApis.dart';

class OfferListScreen extends StatefulWidget {
  const OfferListScreen({super.key});

  static const String routeName = '/offers';

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageLimit = 10;
  static double _preservedScrollOffset = 0;
  static String _preservedSearch = '';
  static int _preservedPage = 1;
  static bool _preservedHasMore = true;
  static List<OfferModel> _preservedOffers = const [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOffersRepository _repository = OffersRepository();
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  List<OfferModel> _offers = const [];
  int _page = 1;
  int _footerIndex = -1;
  bool _hasMore = true;
  bool _loadingInitial = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _errorMessage;

  bool get _isOwner {
    final role = UserData.instance.role;
    return role.trim().toLowerCase() == 'owner';
  }

  List<OfferModel> get _filteredOffers {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _offers;
    return _offers
        .where((offer) => offer.matches(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _offers = List<OfferModel>.from(_preservedOffers);
    _page = _preservedPage;
    _hasMore = _preservedHasMore;
    _scrollController = ScrollController(
      initialScrollOffset: _preservedScrollOffset,
    )..addListener(_onScroll);
    _searchController = TextEditingController(text: _preservedSearch)
      ..addListener(_preserveSearch);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    if (_offers.isEmpty) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _preservedScrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : _preservedScrollOffset;
    _preservedSearch = _searchController.text;
    _preservedPage = _page;
    _preservedHasMore = _hasMore;
    _preservedOffers = List<OfferModel>.from(_offers);
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOffers;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: _isOwner
          ? GlobalAppbar(
              onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
              subtitle: 'Offers Management',
            )
          : RetailerGlobalAppbar(
              onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      drawer: _isOwner
          ? GlobalDrawer(selectedIndex: 6, onItemSelected: (_) {})
          : RetailerGlobalDrawer(selectedIndex: 5, onItemSelected: (_) {}),
      bottomNavigationBar: _isOwner
          ? GlobalFooter(
              currentIndex: _footerIndex,
              onTap: _handleFooterNavigation,
            )
          : RetailerGlobalFooter(
              currentIndex: 2,
              onTap: _handleFooterNavigation,
            ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _loadInitial(forceRefresh: true),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isCompact = screenWidth < 360;
                  final isTablet = screenWidth >= 700;
                  final horizontalPadding = isTablet
                      ? 34.0
                      : (isCompact ? 12.0 : 18.0);
                  final maxWidth = screenWidth >= 1100
                      ? 760.0
                      : (screenWidth >= 700 ? 680.0 : screenWidth);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: CustomScrollView(
                        key: const PageStorageKey<String>('offers-feed'),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              isCompact ? 10 : 14,
                              horizontalPadding,
                              isCompact ? 20 : 26,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                OfferSearchBar(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  canCreate: _isOwner,
                                  isCompact: isCompact,
                                  onCreate: _openCreate,
                                ),
                                SizedBox(height: isCompact ? 12 : 18),
                                if (_loadingInitial) ...[
                                  const ShimmerCard(),
                                  SizedBox(height: isCompact ? 12 : 16),
                                  const ShimmerCard(),
                                ] else if (_errorMessage != null) ...[
                                  OfferErrorWidget(
                                    message: _errorMessage!,
                                    onRetry: () =>
                                        _loadInitial(forceRefresh: true),
                                  ),
                                ] else if (filtered.isEmpty) ...[
                                  EmptyWidget(
                                    onRetry: () =>
                                        _loadInitial(forceRefresh: true),
                                  ),
                                ] else ...[
                                  for (int i = 0; i < filtered.length; i++) ...[
                                    OfferCard(
                                      offer: filtered[i],
                                      canManage: _isOwner,
                                      isCompact: isCompact,
                                      onViewDetails: () =>
                                          _openDetails(filtered[i]),
                                      onEdit: _isOwner
                                          ? () => _openEdit(filtered[i])
                                          : null,
                                      onDelete: _isOwner
                                          ? () => _confirmDelete(filtered[i])
                                          : null,
                                      onImageTap: (index) =>
                                          _openImageViewer(filtered[i], index),
                                    ),
                                    SizedBox(height: isCompact ? 12 : 18),
                                  ],
                                  if (_loadingMore)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isCompact ? 12 : 18,
                                      ),
                                      child: const ShimmerCard(),
                                    ),
                                ],
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadInitial({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (_loadingInitial || _refreshing) return;
    if (!silent) {
      setState(() {
        _loadingInitial = _offers.isEmpty;
        _refreshing = forceRefresh;
        _errorMessage = null;
      });
    }
    try {
      final offers = await _repository.fetchOffers(
        page: 1,
        limit: _pageLimit,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _page = 1;
        _hasMore = offers.length >= _pageLimit;
        _errorMessage = null;
      });
      _preserveState();
    } catch (error) {
      log(error.toString());
      if (!mounted) return;
      if (_offers.isEmpty) {
        setState(() => _errorMessage = _errorText(error));
      } else if (!silent) {
        _showSnackBar(_errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingInitial ||
        _loadingMore ||
        !_hasMore ||
        _searchController.text.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final next = await _repository.fetchOffers(
        page: nextPage,
        limit: _pageLimit,
      );
      if (!mounted) return;
      final seen = _offers.map((offer) => offer.id).toSet();
      setState(() {
        _offers = [
          ..._offers,
          ...next.where((offer) => !seen.contains(offer.id)),
        ];
        _page = nextPage;
        _hasMore = next.length >= _pageLimit;
      });
      _preserveState();
    } catch (error) {
      if (mounted) _showSnackBar(_errorText(error));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (!mounted) return;
    try {
      _preservedScrollOffset = _scrollController.offset;
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 420) {
        _loadMore();
      }
    } catch (_) {
      // Ignore transient scroll state issues while the view is being built.
    }
  }

  void _preserveSearch() {
    _preservedSearch = _searchController.text;
  }

  void _preserveState() {
    _preservedSearch = _searchController.text;
    _preservedPage = _page;
    _preservedHasMore = _hasMore;
    _preservedOffers = List<OfferModel>.from(_offers);
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<OfferFormResult>(
      MaterialPageRoute<OfferFormResult>(
        settings: const RouteSettings(name: '/offers/create'),
        builder: (_) => const AddEditOfferScreen(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _offers = [
        result.offer,
        ..._offers.where((o) => o.id != result.offer.id),
      ];
      _errorMessage = null;
    });
    _preserveState();
    _showSnackBar(result.message, success: true);
    _loadInitial(forceRefresh: true, silent: true);
  }

  Future<void> _openEdit(OfferModel offer) async {
    final result = await Navigator.of(context).push<OfferFormResult>(
      MaterialPageRoute<OfferFormResult>(
        settings: const RouteSettings(name: '/offers/edit'),
        builder: (_) => AddEditOfferScreen(offer: offer),
      ),
    );
    if (result == null || !mounted) return;
    _applyUpdatedOffer(result.offer);
    _showSnackBar(result.message, success: true);
    _loadInitial(forceRefresh: true, silent: true);
  }

  Future<void> _openDetails(OfferModel offer) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        settings: const RouteSettings(name: '/offers/details'),
        builder: (_) => OfferDetailedScreen(offer: offer, canManage: _isOwner),
      ),
    );
    if (result == null || !mounted) return;
    if (result is OfferFormResult) {
      _applyUpdatedOffer(result.offer);
      _showSnackBar(result.message, success: true);
      _loadInitial(forceRefresh: true, silent: true);
    } else if (result is OfferDeleteResult) {
      _removeOffer(result.offer.id);
      _showSnackBar(result.message, success: true);
      _loadInitial(forceRefresh: true, silent: true);
    }
  }

  Future<void> _openImageViewer(OfferModel offer, int index) async {
    if (offer.bannerImages.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewer(
          images: offer.bannerImages,
          initialIndex: index,
          heroPrefix: 'offer-${offer.id}-image',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(OfferModel offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('This offer will be removed from the feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final index = _offers.indexWhere((item) => item.id == offer.id);
    if (index == -1) return;
    final previous = List<OfferModel>.from(_offers);
    _removeOffer(offer.id);
    try {
      await _repository.deleteOffer(offer.id);
      if (!mounted) return;
      _showSnackBar('Offer deleted successfully.', success: true);
      _loadInitial(forceRefresh: true, silent: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _offers = previous);
      _preserveState();
      _showSnackBar(_errorText(error));
    }
  }

  void _applyUpdatedOffer(OfferModel offer) {
    final index = _offers.indexWhere((item) => item.id == offer.id);
    setState(() {
      if (index == -1) {
        _offers = [offer, ..._offers];
      } else {
        _offers = List<OfferModel>.from(_offers)..[index] = offer;
      }
    });
    _preserveState();
  }

  void _removeOffer(String offerId) {
    setState(() {
      _offers = _offers.where((offer) => offer.id != offerId).toList();
    });
    _preserveState();
  }

  void _handleFooterNavigation(int index) {
    if (!_isOwner) {
      switch (index) {
        case 0:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
          break;
        case 1:
          Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
          break;
        case 2:
          break;
        case 3:
          Navigator.of(context).pushNamed(AppRoutes.orderManagement);
          break;
        case 4:
          Navigator.of(context).pushNamed(AppRoutes.retailerCart);
          break;
      }
      return;
    }
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.stockListing);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.addProduct);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.orderManagement);
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushNamed(AppRoutes.orderHistory);
      return;
    }
    setState(() => _footerIndex = index);
    _showSnackBar('This section will be connected soon.', success: true);
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    if (error is SocketException) {
      return 'Please check your internet connection.';
    }
    return 'Something went wrong.';
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? AppColors.accentGold : AppColors.surfaceWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
