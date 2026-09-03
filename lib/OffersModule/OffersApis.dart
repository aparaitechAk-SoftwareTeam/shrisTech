// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/userdata.dart';

class ProductModel {
  final String id;
  final String name;
  final Map<String, dynamic> rawJson;

  const ProductModel({
    required this.id,
    required this.name,
    this.rawJson = const <String, dynamic>{},
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _readString(json, const ['id', '_id', 'product_id', 'uuid']),
      name: _readString(json, const [
        'product_name',
        'productName',
        'name',
        'title',
      ], fallback: 'Unnamed Product'),
      rawJson: json,
    );
  }

  ProductModel copyWith({String? id, String? name}) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rawJson: rawJson,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'product_name': name};
}

class OfferModel {
  final String id;
  final String uuid;
  final String title;
  final String note;
  final String offerType;
  final double? discount;
  final String bannerImage;
  final List<String> bannerImages;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;
  final List<String> productIds;
  final List<ProductModel> products;
  final bool isNew;
  final bool isActive;
  final bool isExpired;
  final int? daysRemaining;
  final Map<String, dynamic> rawJson;

  const OfferModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.note,
    required this.offerType,
    required this.discount,
    required this.bannerImage,
    required this.bannerImages,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.productIds,
    required this.products,
    required this.isNew,
    required this.isActive,
    required this.isExpired,
    required this.daysRemaining,
    this.rawJson = const <String, dynamic>{},
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final start = _readDateTime(
      _readObject(json, const ['start_date', 'startDate', 'valid_from']),
    );
    final end = _readDateTime(
      _readObject(json, const ['end_date', 'endDate', 'valid_to']),
    );
    final created = _readDateTime(
      _readObject(json, const ['created_at', 'createdAt']),
    );
    final status = _readString(json, const ['status'], fallback: '');
    final banners = _readStringList(json, const [
      'banner_images',
      'bannerImages',
      'images',
    ]);
    final singleBanner = _readString(json, const [
      'banner_image',
      'bannerImage',
      'image',
      'image_url',
    ]);
    final cleanSingleBanner = _sanitizeBannerUrl(singleBanner);
    final cleanBanners = banners
        .map(_sanitizeBannerUrl)
        .where((item) => item.isNotEmpty)
        .toList();
    final allBanners = {
      if (cleanSingleBanner.isNotEmpty) cleanSingleBanner,
      ...cleanBanners,
    }.toList(growable: false);
    final products = _readProducts(json);
    final productIds = _readStringList(json, const [
      'product_ids',
      'productIds',
    ]);
    final normalizedProductIds = <String>{
      ...productIds,
      ...products.map((product) => product.id).where((id) => id.isNotEmpty),
    }.toList(growable: false);
    final flags = _OfferFlags.fromDates(
      createdAt: created,
      startDate: start,
      endDate: end,
      status: status,
    );

    return OfferModel(
      id: _readString(json, const ['id', '_id', 'offer_id', 'offerId']),
      uuid: _readString(json, const ['uuid', 'offer_uuid']),
      title: _readString(json, const [
        'title',
        'offer_title',
        'name',
      ], fallback: 'Untitled Offer'),
      note: _readString(json, const [
        'note',
        'description',
        'message',
      ], fallback: 'No description available.'),
      offerType: _normalizeOfferType(
        _readString(json, const [
          'offer_type',
          'offerType',
          'type',
        ], fallback: 'Percentage'),
      ),
      discount: _readDiscount(
        json,
        _normalizeOfferType(
          _readString(json, const [
            'offer_type',
            'offerType',
            'type',
          ], fallback: 'Percentage'),
        ),
      ),
      bannerImage: allBanners.isEmpty ? '' : allBanners.first,
      bannerImages: allBanners,
      startDate: start,
      endDate: end,
      createdAt: created,
      updatedAt: _readDateTime(
        _readObject(json, const ['updated_at', 'updatedAt']),
      ),
      status: status,
      productIds: normalizedProductIds,
      products: products,
      isNew: flags.isNew,
      isActive: flags.isActive,
      isExpired: flags.isExpired,
      daysRemaining: flags.daysRemaining,
      rawJson: json,
    );
  }

  factory OfferModel.optimistic({
    required OfferRequestModel request,
    required String temporaryId,
  }) {
    return OfferModel.fromJson({
      'id': temporaryId,
      'uuid': temporaryId,
      ...request.toJson(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'Active',
    });
  }

  OfferModel copyWith({
    String? id,
    String? uuid,
    String? title,
    String? note,
    String? offerType,
    double? discount,
    String? bannerImage,
    List<String>? bannerImages,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    List<String>? productIds,
    List<ProductModel>? products,
    Map<String, dynamic>? rawJson,
  }) {
    final nextStatus = status ?? this.status;
    final flags = _OfferFlags.fromDates(
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: nextStatus,
    );
    final nextBannerImages = bannerImages ?? this.bannerImages;
    return OfferModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      note: note ?? this.note,
      offerType: offerType ?? this.offerType,
      discount: discount ?? this.discount,
      bannerImage:
          bannerImage ??
          (nextBannerImages.isEmpty
              ? this.bannerImage
              : nextBannerImages.first),
      bannerImages: nextBannerImages,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: nextStatus,
      productIds: productIds ?? this.productIds,
      products: products ?? this.products,
      isNew: flags.isNew,
      isActive: flags.isActive,
      isExpired: flags.isExpired,
      daysRemaining: flags.daysRemaining,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return title.toLowerCase().contains(normalized) ||
        note.toLowerCase().contains(normalized) ||
        offerType.toLowerCase().contains(normalized);
  }

  /// The correct identifier to use for update/delete API calls.
  /// Prefers the UUID returned by the GET endpoint; falls back to [id].
  String get apiId => uuid.isNotEmpty ? uuid : id;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'offer_type': offerType,
    'discount': discount,
    'banner_image': bannerImage,
    'start_date': startDate?.toUtc().toIso8601String(),
    'end_date': endDate?.toUtc().toIso8601String(),
    'created_at': createdAt?.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    'status': status,
    'product_ids': productIds,
    'products': products.map((product) => product.toJson()).toList(),
  };
}

class OfferRequestModel {
  final String title;
  final String note;
  final String bannerImage;
  final String offerType;
  final double discount;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> productIds;

  const OfferRequestModel({
    required this.title,
    required this.note,
    required this.bannerImage,
    required this.offerType,
    required this.discount,
    required this.startDate,
    required this.endDate,
    required this.productIds,
  });

  factory OfferRequestModel.fromJson(Map<String, dynamic> json) {
    return OfferRequestModel(
      title: _readString(json, const ['title']),
      note: _readString(json, const ['note', 'description']),
      bannerImage: _readString(json, const ['banner_image', 'bannerImage']),
      offerType: _normalizeOfferType(
        _readString(json, const ['offer_type', 'offerType']),
      ),
      discount:
          _readNullableDouble(
            _readObject(json, const ['discount_percentage']),
          ) ??
          0,
      startDate:
          _readDateTime(_readObject(json, const ['start_date', 'startDate'])) ??
          DateTime.now(),
      endDate:
          _readDateTime(_readObject(json, const ['end_date', 'endDate'])) ??
          DateTime.now(),
      productIds: _readStringList(json, const ['product_ids', 'productIds']),
    );
  }

  OfferRequestModel copyWith({
    String? title,
    String? note,
    String? bannerImage,
    String? offerType,
    double? discount,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? productIds,
  }) {
    return OfferRequestModel(
      title: title ?? this.title,
      note: note ?? this.note,
      bannerImage: bannerImage ?? this.bannerImage,
      offerType: offerType ?? this.offerType,
      discount: discount ?? this.discount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      productIds: productIds ?? this.productIds,
    );
  }

  Map<String, dynamic> toJson() {
    final isFlat = offerType.trim().toLowerCase() == 'flat';
    return {
      'title': title.trim(),
      'note': note.trim(),
      'banner_image': bannerImage.trim(),
      'offer_type': offerType.trim(),
      if (isFlat) 'discount_amount': discount,
      if (!isFlat) 'discount_percentage': discount,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'product_ids': productIds,
    };
  }
}

class OfferMutationResponse {
  final String message;
  final OfferModel? offer;

  const OfferMutationResponse({required this.message, this.offer});
}

class OfferBannerUploadItem {
  final String path;
  final String fileName;
  final int rotationDegrees;

  const OfferBannerUploadItem({
    required this.path,
    required this.fileName,
    this.rotationDegrees = 0,
  });
}

abstract class IOffersRepository {
  Future<List<OfferModel>> fetchOffers({
    String? status,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  });

  Future<OfferMutationResponse> createOffer(OfferRequestModel request);

  Future<OfferMutationResponse> updateOffer(
    String offerId,
    OfferRequestModel request,
  );

  Future<void> deleteOffer(String offerId);

  Future<List<ProductModel>> fetchProducts({bool forceRefresh = false});

  Future<String> uploadBanner(OfferBannerUploadItem banner);

  void updateCache(List<OfferModel> offers);
}

class OffersRepository implements IOffersRepository {
  OffersRepository({OffersApis? apis}) : _apis = apis ?? OffersApis();

  final OffersApis _apis;
  final Map<String, List<OfferModel>> _offerCache = {};
  List<ProductModel>? _productsCache;

  @override
  Future<List<OfferModel>> fetchOffers({
    String? status,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = '${status ?? ''}:$page:$limit';
    if (!forceRefresh && _offerCache[key] != null) {
      return List<OfferModel>.unmodifiable(_offerCache[key]!);
    }
    final offers = await _apis.fetchOffers(
      status: status,
      page: page,
      limit: limit,
    );
    _offerCache[key] = offers;
    return List<OfferModel>.unmodifiable(offers);
  }

  @override
  Future<OfferMutationResponse> createOffer(OfferRequestModel request) async {
    final response = await _apis.createOffer(request);
    _offerCache.clear();
    return response;
  }

  @override
  Future<OfferMutationResponse> updateOffer(
    String offerId,
    OfferRequestModel request,
  ) async {
    final response = await _apis.updateOffer(offerId, request);
    _offerCache.clear();
    return response;
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    await _apis.deleteOffer(offerId);
    _offerCache.clear();
  }

  @override
  Future<List<ProductModel>> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _productsCache != null) {
      return List<ProductModel>.unmodifiable(_productsCache!);
    }
    final products = await _apis.fetchProducts();
    _productsCache = products;
    return List<ProductModel>.unmodifiable(products);
  }

  @override
  Future<String> uploadBanner(OfferBannerUploadItem banner) {
    return _apis.uploadBanner(banner);
  }

  @override
  void updateCache(List<OfferModel> offers) {
    _offerCache.clear();
    _offerCache[':1:${offers.length}'] = List<OfferModel>.from(offers);
  }
}

class OffersApis {
  OffersApis({http.Client? client}) : _client = client ?? http.Client();

  static const String offersEndpoint = '/api/offers';
  static const String ownerOffersEndpoint = '/api/offers';
  static const String productsEndpoint = '/api/products';
  static const String uploadBannerEndpoint = '/api/offers/upload-banner';
  static const int imageQuality = 78;
  static const int maxImageWidth = 1800;
  static const int maxImageHeight = 1800;

  final http.Client _client;

  Future<List<OfferModel>> fetchOffers({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      log('Fetching offers: status=$status, page=$page, limit=$limit');
      final response = await _client
          .get(
            _buildUri(
              offersEndpoint,
              queryParameters: {
                if (status != null && status.trim().isNotEmpty)
                  'status': status.trim(),
                'page': page.toString(),
                'limit': limit.toString(),
              },
            ),
            headers: _headers(),
          )
          .timeout(ApiConstants.requestTimeout);

      log('API Response: ${response.statusCode} - ${response.body}');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final offers = _readResponseList(decoded, const [
        'offers',
        'data',
        'items',
        'results',
      ]);
      final parsed = offers
          .whereType<Map<String, dynamic>>()
          .map(OfferModel.fromJson)
          .where((offer) => offer.id.isNotEmpty)
          .toList(growable: false);
      return [...parsed]..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server 1.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<OfferMutationResponse> createOffer(OfferRequestModel request) async {
    return _sendOffer(
      endpoint: ownerOffersEndpoint,
      method: _HttpMethod.post,
      request: request,
      fallbackMessage: 'Offer created successfully.',
    );
  }

  Future<OfferMutationResponse> updateOffer(
    String offerId,
    OfferRequestModel request,
  ) async {
    if (offerId.trim().isEmpty) {
      throw const ApiException('Offer ID is missing.');
    }
    return _sendOffer(
      endpoint: '$ownerOffersEndpoint/${Uri.encodeComponent(offerId)}',
      method: _HttpMethod.put,
      request: request,
      fallbackMessage: 'Offer updated successfully.',
    );
  }

  Future<void> deleteOffer(String offerId) async {
    if (offerId.trim().isEmpty) {
      throw const ApiException('Offer ID is missing.');
    }
    try {
      final response = await _client
          .delete(
            _buildUri('$ownerOffersEndpoint/${Uri.encodeComponent(offerId)}'),
            headers: _headers(),
          )
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server 2.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await _client
          .get(_buildUri(productsEndpoint), headers: _headers())
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final products = _readResponseList(decoded, const [
        'products',
        'data',
        'items',
        'results',
      ]);
      return products
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .where((product) => product.id.isNotEmpty)
          .toList(growable: false);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server 3.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<String> uploadBanner(OfferBannerUploadItem banner) async {
    final file = File(banner.path);
    if (!await file.exists()) {
      throw const ApiException('Selected banner was not found.');
    }

    final bytes = await FlutterImageCompress.compressWithFile(
      banner.path,
      minWidth: maxImageWidth,
      minHeight: maxImageHeight,
      quality: imageQuality,
      rotate: banner.rotationDegrees,
      format: CompressFormat.jpeg,
    );

    if (bytes == null || bytes.isEmpty) {
      throw const ApiException('Unable to prepare selected banner.');
    }

    final encoded = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    try {
      final response = await _client
          .post(
            _buildUri(uploadBannerEndpoint),
            headers: _headers(),
            body: jsonEncode({
              'file_name': banner.fileName,
              'banner_image': encoded,
            }),
          )
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final uploaded = _readString(decoded, const [
        'banner_image',
        'bannerImage',
        'url',
        'image_url',
        'secure_url',
      ]);
      return uploaded.isNotEmpty ? uploaded : encoded;
    } on ApiException catch (error) {
      log('Banner upload endpoint fallback: $error');
      return encoded;
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.4');
    }
  }

  Future<OfferMutationResponse> _sendOffer({
    required String endpoint,
    required _HttpMethod method,
    required OfferRequestModel request,
    required String fallbackMessage,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final body = jsonEncode(request.toJson());
      final response = method == _HttpMethod.post
          ? await _client
                .post(uri, headers: _headers(), body: body)
                .timeout(ApiConstants.requestTimeout)
          : await _client
                .put(uri, headers: _headers(), body: body)
                .timeout(ApiConstants.requestTimeout);
      log('API Request: ${method.name.toUpperCase()} $uri - $body');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final offerMap = _readFirstMap(decoded, const ['offer', 'data', 'item']);
      final offer = offerMap.isEmpty ? null : OfferModel.fromJson(offerMap);
      final message = _readString(decoded, const [
        'message',
        'success_message',
      ], fallback: fallbackMessage);
      return OfferMutationResponse(message: message, offer: offer);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.5');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Uri _buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    final separator =
        ApiConstants.activeBaseUrl.endsWith('/') || endpoint.startsWith('/')
        ? ''
        : '/';
    final uri = Uri.parse('${ApiConstants.activeBaseUrl}$separator$endpoint');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers() {
    final token = UserData.instance.token.trim();
    return {
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      if (token.isNotEmpty) ApiConstants.headerAuthorization: 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const <String, dynamic>{'success': true};
      }
      throw ApiException(
        _fallbackMessageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    log('API Response: ${response.statusCode} - $decoded');
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid response received from server.6',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['message'] ?? decoded['error'];
    throw ApiException(
      message is String && message.trim().isNotEmpty
          ? message
          : _fallbackMessageForStatus(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _fallbackMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check the offer details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to manage offers.';
      case 404:
        return 'Offer data was not found.';
      case 409:
        return 'This offer already exists.';
      case 422:
        return 'Please check the highlighted offer details.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong.';
    }
  }
}

enum _HttpMethod { post, put }

class _OfferFlags {
  final bool isNew;
  final bool isActive;
  final bool isExpired;
  final int? daysRemaining;

  const _OfferFlags({
    required this.isNew,
    required this.isActive,
    required this.isExpired,
    required this.daysRemaining,
  });

  factory _OfferFlags.fromDates({
    required DateTime? createdAt,
    required DateTime? startDate,
    required DateTime? endDate,
    required String status,
  }) {
    final now = DateTime.now();
    final createdLocal = createdAt?.toLocal();
    final startLocal = startDate?.toLocal();
    final endLocal = endDate?.toLocal();
    final normalizedStatus = status.trim().toLowerCase();
    final backendActive = normalizedStatus == 'active';
    final backendExpired = normalizedStatus == 'expired';
    final dateActive =
        startLocal != null &&
        endLocal != null &&
        !now.isBefore(startLocal) &&
        !now.isAfter(endLocal);
    final dateExpired = endLocal != null && now.isAfter(endLocal);
    final remaining = endLocal?.difference(now).inDays;

    return _OfferFlags(
      isNew: createdLocal != null && now.difference(createdLocal).inDays <= 5,
      isActive: normalizedStatus.isEmpty
          ? dateActive
          : backendActive || (!backendExpired && dateActive),
      isExpired: normalizedStatus.isEmpty ? dateExpired : backendExpired,
      daysRemaining: remaining == null || remaining < 0 ? null : remaining,
    );
  }
}

List<ProductModel> _readProducts(Map<String, dynamic> json) {
  final products = _readResponseList(json, const ['products', 'product_list']);
  return products
      .whereType<Map<String, dynamic>>()
      .map(ProductModel.fromJson)
      .where((product) => product.id.isNotEmpty || product.name.isNotEmpty)
      .toList(growable: false);
}

List<dynamic> _readResponseList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final nested = _readResponseList(value, keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

Map<String, dynamic> _readFirstMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

Object? _readObject(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _readString(item, const [
                'id',
                '_id',
                'product_id',
                'url',
              ]);
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const <String>[];
}

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

double? _readDiscount(Map<String, dynamic> json, String offerType) {
  final isFlat = offerType.toLowerCase() == 'flat';
  final primaryKeys = isFlat
      ? const [
          'discount_amount',
          'discount_percentage',
          'discount_value',
          'discountValue',
          'discount',
        ]
      : const [
          'discount_percentage',
          'discount_amount',
          'discount_value',
          'discountValue',
          'discount',
        ];

  for (final key in primaryKeys) {
    if (!json.containsKey(key)) continue;
    final parsed = _readNullableDouble(json[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) return null;
  try {
    final parsed = DateTime.tryParse(value.toString().trim());
    return parsed?.toLocal();
  } catch (error) {
    log('Invalid offer date ignored: $value');
    return null;
  }
}

String _normalizeOfferType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'flat' || normalized == 'amount') return 'Flat';
  return 'Percentage';
}

void _throwIfApiFailed(Map<String, dynamic> decoded, int statusCode) {
  if (decoded['success'] != false) return;
  final message = decoded['message'] ?? decoded['error'];
  throw ApiException(
    message is String && message.trim().isNotEmpty
        ? message
        : 'Something went wrong.',
    statusCode: statusCode,
  );
}

String _sanitizeBannerUrl(String url) {
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
