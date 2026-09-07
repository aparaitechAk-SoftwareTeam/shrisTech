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

class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isParent => parentId == null || parentId!.trim().isEmpty;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final parentValue = json['parent_id'] ?? json['parentId'];
    final parentText = parentValue?.toString().trim();
    return CategoryModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      parentId: parentText == null || parentText.isEmpty ? null : parentText,
      isActive: _readBool(
        json['is_active'] ?? json['isActive'],
        fallback: true,
      ),
      createdAt: _readDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class AddProductRequestModel {
  final String productName;
  final String productCode;
  final String description;
  final double grossWeight;
  final double stoneWeight;
  final double stoneCharge;
  final double netWeight;
  final int availableQuantity;
  final int minimumOrderQuantity;
  final bool isFeatured;
  final List<String> images;

  const AddProductRequestModel({
    required this.productName,
    required this.productCode,
    required this.description,
    required this.grossWeight,
    required this.stoneWeight,
    required this.stoneCharge,
    this.netWeight = 0,
    required this.availableQuantity,
    required this.minimumOrderQuantity,
    required this.isFeatured,
    required this.images,
  });

  factory AddProductRequestModel.fromJson(Map<String, dynamic> json) {
    final gross = _readDouble(json, 'gross_weight');
    final stone = _readDouble(json, 'stone_weight');
    final net = _readDouble(json, 'net_weight');
    return AddProductRequestModel(
      productName: _readString(
        json,
        'product_name',
        fallback: _readString(json, 'name'),
      ),
      productCode: _readString(
        json,
        'product_code',
        fallback: _readString(json, 'code'),
      ),
      description: _readString(json, 'description'),
      grossWeight: gross,
      stoneWeight: stone,
      stoneCharge: _readDouble(json, 'stone_charge'),
      netWeight: net > 0 ? net : (gross - stone),
      availableQuantity: _readInt(
        json,
        'available_quantity',
        fallback: _readInt(json, 'quantity', fallback: 1),
      ),
      minimumOrderQuantity: _readInt(
        json,
        'minimum_order_quantity',
        fallback: _readInt(json, 'min_order_quantity', fallback: 1),
      ),
      isFeatured: json['is_featured'] == true,
      images: (json['images'] is List)
          ? (json['images'] as List).map((item) => item.toString()).toList()
          : const <String>[],
    );
  }

  AddProductRequestModel copyWith({
    String? productName,
    String? productCode,
    String? description,
    double? grossWeight,
    double? stoneWeight,
    double? stoneCharge,
    double? netWeight,
    int? availableQuantity,
    int? minimumOrderQuantity,
    bool? isFeatured,
    List<String>? images,
  }) {
    return AddProductRequestModel(
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      description: description ?? this.description,
      grossWeight: grossWeight ?? this.grossWeight,
      stoneWeight: stoneWeight ?? this.stoneWeight,
      stoneCharge: stoneCharge ?? this.stoneCharge,
      netWeight: netWeight ?? this.netWeight,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    final computedNet = netWeight > 0 ? netWeight : (grossWeight - stoneWeight);
    final effectiveQty = availableQuantity > 0 ? availableQuantity : 1;
    final effectiveMoq = minimumOrderQuantity > 0 ? minimumOrderQuantity : 1;
    final effectiveCode = productCode.trim().isNotEmpty
        ? productCode.trim()
        : 'BBS-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveDesc = description.trim().isNotEmpty
        ? description.trim()
        : productName.trim();

    return {
      'product_name': productName.trim(),
      'name': productName.trim(),
      'product_code': effectiveCode,
      'code': effectiveCode,
      'description': effectiveDesc,
      'gross_weight': grossWeight,
      'stone_weight': stoneWeight,
      'stone_charge': stoneCharge,
      'net_weight': computedNet > 0 ? computedNet : 0.0,
      'available_quantity': effectiveQty,
      'quantity': effectiveQty,
      'minimum_order_quantity': effectiveMoq,
      'min_order_quantity': effectiveMoq,
      'is_featured': isFeatured,
      'is_active': true,
      'images': images,
    };
  }
}

class AddProductResponseModel {
  final String message;
  final String productId;
  final String variantId;
  final double netWeight;

  const AddProductResponseModel({
    required this.message,
    required this.productId,
    required this.variantId,
    required this.netWeight,
  });

  factory AddProductResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['product'] is Map<String, dynamic>
              ? json['product'] as Map<String, dynamic>
              : json);

    return AddProductResponseModel(
      message: _readString(
        json,
        'message',
        fallback: 'Product created successfully.',
      ),
      productId: _readString(
        data,
        'product_id',
        fallback: _readString(data, 'id'),
      ),
      variantId: _readString(
        data,
        'variant_id',
        fallback: _readString(data, 'variantId'),
      ),
      netWeight: _readDouble(data, 'net_weight'),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'product_id': productId,
    'variant_id': variantId,
    'net_weight': netWeight,
  };
}

class ProductImageUploadItem {
  final String path;
  final String fileName;
  final int rotationDegrees;

  const ProductImageUploadItem({
    required this.path,
    required this.fileName,
    this.rotationDegrees = 0,
  });
}

abstract class IAddProductRepository {
  Future<List<CategoryModel>> fetchCategories({bool forceRefresh = false});

  Future<CategoryModel> createCategory({required String name});

  Future<CategoryModel> createSubCategory({
    required String name,
    required String parentId,
  });

  Future<AddProductResponseModel> createProduct({
    required AddProductRequestModel request,
  });

  Future<List<String>> uploadImages(List<ProductImageUploadItem> images);

  AddProductRequestModel prepareRequest({
    required String productName,
    required double grossWeight,
    required double stoneWeight,
    required double stoneCharge,
    required List<String> images,
    double? netWeight,
    String description,
    String productCode,
    int availableQuantity,
    int minimumOrderQuantity,
    bool isFeatured,
  });
}

class AddProductRepository implements IAddProductRepository {
  AddProductRepository({AddProductFormApis? apis})
    : _apis = apis ?? AddProductFormApis();

  final AddProductFormApis _apis;
  List<CategoryModel>? _cachedCategories;

  @override
  Future<List<CategoryModel>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCategories != null) {
      return List<CategoryModel>.unmodifiable(_cachedCategories!);
    }
    final categories = await _apis.fetchCategories();
    _cachedCategories = categories;
    return List<CategoryModel>.unmodifiable(categories);
  }

  @override
  Future<CategoryModel> createCategory({required String name}) async {
    final category = await _apis.createCategory(name: name);
    _cachedCategories = null;
    return category;
  }

  @override
  Future<CategoryModel> createSubCategory({
    required String name,
    required String parentId,
  }) async {
    final subCategory = await _apis.createSubCategory(
      name: name,
      parentId: parentId,
    );
    _cachedCategories = null;
    return subCategory;
  }

  @override
  Future<AddProductResponseModel> createProduct({
    required AddProductRequestModel request,
  }) {
    return _apis.createProduct(request);
  }

  @override
  Future<List<String>> uploadImages(List<ProductImageUploadItem> images) {
    return _apis.uploadImages(images);
  }

  @override
  AddProductRequestModel prepareRequest({
    required String productName,
    required double grossWeight,
    required double stoneWeight,
    required double stoneCharge,
    required List<String> images,
    double? netWeight,
    String description = '',
    String productCode = '',
    int availableQuantity = 0,
    int minimumOrderQuantity = 1,
    bool isFeatured = false,
  }) {
    return _apis.prepareRequest(
      productName: productName,
      productCode: productCode,
      description: description,
      grossWeight: grossWeight,
      stoneWeight: stoneWeight,
      stoneCharge: stoneCharge,
      netWeight: netWeight,
      availableQuantity: availableQuantity,
      minimumOrderQuantity: minimumOrderQuantity,
      isFeatured: isFeatured,
      images: images,
    );
  }
}

class AddProductFormApis {
  AddProductFormApis({http.Client? client}) : _client = client ?? http.Client();

  static const String createProductEndpoint = 'api/owner/products';
  static const String categoriesEndpoint = 'api/categories';
  static const String ownerCategoriesEndpoint = 'api/owner/categories';
  static const int imageQuality = 78;
  static const int maxImageWidth = 1600;
  static const int maxImageHeight = 1600;

  final http.Client _client;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _client
          .get(_buildUri(categoriesEndpoint), headers: _headers())
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final categories = decoded['categories'];
      if (categories is! List) {
        throw ApiException(
          'Invalid categories response received from server.',
          statusCode: response.statusCode,
        );
      }
      return categories
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .where(
            (category) => category.id.isNotEmpty && category.name.isNotEmpty,
          )
          .toList(growable: false);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<CategoryModel> createCategory({required String name}) {
    return _createCategory(name: name, parentId: null);
  }

  Future<CategoryModel> createSubCategory({
    required String name,
    required String parentId,
  }) {
    return _createCategory(name: name, parentId: parentId);
  }

  Future<AddProductResponseModel> createProduct(
    AddProductRequestModel request,
  ) async {
    try {
      log('createProduct payload: ${jsonEncode(request.toJson())}');
      final response = await _client
          .post(
            _buildUri(createProductEndpoint),
            headers: _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);
      log('createProduct status: ${response.statusCode}');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      return AddProductResponseModel.fromJson(decoded);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<CategoryModel> _createCategory({
    required String name,
    required String? parentId,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri(ownerCategoriesEndpoint),
            headers: _headers(),
            body: jsonEncode({'name': name.trim(), 'parent_id': parentId}),
          )
          .timeout(ApiConstants.requestTimeout);
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded, response.statusCode);
      final data = decoded['category'];
      if (data is Map<String, dynamic>) return CategoryModel.fromJson(data);
      if (decoded['id'] != null && decoded['name'] != null) {
        return CategoryModel.fromJson(decoded);
      }
      return CategoryModel(
        id: _readString(decoded, 'id'),
        name: _readString(decoded, 'name', fallback: name.trim()),
        parentId: parentId,
      );
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (error) {
      log(error.toString());
      throw const ApiException('Something went wrong.');
    }
  }

  Future<List<String>> uploadImages(List<ProductImageUploadItem> images) async {
    if (images.isEmpty) {
      throw const ApiException('Please add at least one product image.');
    }

    final encodedImages = <String>[];
    for (final image in images) {
      final file = File(image.path);
      if (!await file.exists()) {
        throw const ApiException('Selected image was not found.');
      }

      final bytes = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: maxImageWidth,
        minHeight: maxImageHeight,
        quality: imageQuality,
        rotate: image.rotationDegrees,
        format: CompressFormat.jpeg,
      );

      if (bytes == null || bytes.isEmpty) {
        throw const ApiException('Unable to prepare selected image.');
      }

      encodedImages.add('data:image/jpeg;base64,${base64Encode(bytes)}');
    }

    return encodedImages;
  }

  AddProductRequestModel prepareRequest({
    required String productName,
    required double grossWeight,
    required double stoneWeight,
    required double stoneCharge,
    required List<String> images,
    double? netWeight,
    required int availableQuantity,
    required int minimumOrderQuantity,
    required bool isFeatured,
    String productCode = '',
    String description = '',
  }) {
    final computedNet = netWeight ?? (grossWeight - stoneWeight);
    return AddProductRequestModel(
      productName: productName.trim(),
      productCode: productCode.trim().isEmpty
          ? 'BBS-${DateTime.now().millisecondsSinceEpoch}'
          : productCode.trim(),
      description: description.trim().isNotEmpty
          ? description.trim()
          : productName.trim(),
      grossWeight: grossWeight,
      stoneWeight: stoneWeight,
      stoneCharge: stoneCharge,
      netWeight: computedNet > 0 ? computedNet : 0.0,
      availableQuantity: availableQuantity > 0 ? availableQuantity : 1,
      minimumOrderQuantity: minimumOrderQuantity > 0 ? minimumOrderQuantity : 1,
      isFeatured: isFeatured,
      images: images,
    );
  }

  Uri _buildUri(String endpoint) {
    final separator =
        ApiConstants.activeBaseUrl.endsWith('/') || endpoint.startsWith('/')
        ? ''
        : '/';
    return Uri.parse('${ApiConstants.activeBaseUrl}$separator$endpoint');
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
      throw ApiException(
        _fallbackMessageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    log('API Response (${response.statusCode}): $decoded');
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid response received from server.',
        statusCode: response.statusCode,
      );
    }

    if (decoded['success'] == false) {
      final message = decoded['message'] ?? decoded['error'];
      throw ApiException(
        message is String && message.trim().isNotEmpty
            ? message
            : _fallbackMessageForStatus(response.statusCode),
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
        return 'Bad request. Please check the product details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to add products.';
      case 404:
        return 'Requested data was not found.';
      case 409:
        return 'This record already exists.';
      case 422:
        return 'Please check the highlighted product details.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong.';
    }
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

bool _readBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
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
