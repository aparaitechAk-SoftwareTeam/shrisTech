// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/userdata.dart';

/// Data model representing a Retailer Profile in BBS GOLD.
class RetailerProfileModel {
  final String id;
  final String userId;
  final String username;
  final String name;
  final String email;
  final String mobileNumber;
  final String role;
  final String accountStatus;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> rawJson;

  const RetailerProfileModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.role,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
    this.rawJson = const <String, dynamic>{},
  });

  /// Creates a fallback model directly from active session [UserData.instance].
  factory RetailerProfileModel.fromSession() {
    final user = UserData.instance;
    return RetailerProfileModel(
      id: user.id.isNotEmpty ? user.id : user.userId,
      userId: user.userId.isNotEmpty ? user.userId : user.id,
      username: user.username,
      name: user.name,
      email: user.email,
      mobileNumber: user.mobileNumber,
      role: user.role.isNotEmpty ? user.role : 'Retailer',
      accountStatus: user.accountStatus.isNotEmpty ? user.accountStatus : 'Active',
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      rawJson: user.toJson(),
    );
  }

  /// Deserializes a JSON response from `/api/retailer/profile`.
  factory RetailerProfileModel.fromJson(Map<String, dynamic> json) {
    final profileMap = _firstMap(json, const ['profile', 'user', 'retailer', 'data']);
    final source = profileMap.isNotEmpty ? profileMap : json;

    final user = UserData.instance;
    final idVal = _readString(source, const ['id', '_id', 'retailer_id', 'retailerId']);
    final userIdVal = _readString(source, const ['user_id', 'userId', 'id', '_id']);
    final usernameVal = _readString(source, const ['username', 'user_name']);
    final nameVal = _readString(source, const ['name', 'full_name', 'fullName']);
    final emailVal = _readString(source, const ['email', 'email_address']);
    final mobileVal = _readString(source, const ['mobile_no', 'mobile_number', 'mobile', 'phone']);
    final roleVal = _readString(source, const ['role', 'user_role']);
    final statusVal = _readString(source, const ['account_status', 'accountStatus', 'status']);
    final createdVal = _readString(source, const ['created_at', 'createdAt']);
    final updatedVal = _readString(source, const ['updated_at', 'updatedAt']);

    return RetailerProfileModel(
      id: idVal.isNotEmpty ? idVal : (user.id.isNotEmpty ? user.id : user.userId),
      userId: userIdVal.isNotEmpty ? userIdVal : (user.userId.isNotEmpty ? user.userId : user.id),
      username: usernameVal.isNotEmpty ? usernameVal : user.username,
      name: nameVal.isNotEmpty ? nameVal : user.name,
      email: emailVal.isNotEmpty ? emailVal : user.email,
      mobileNumber: mobileVal.isNotEmpty ? mobileVal : user.mobileNumber,
      role: roleVal.isNotEmpty ? roleVal : (user.role.isNotEmpty ? user.role : 'Retailer'),
      accountStatus: statusVal.isNotEmpty ? statusVal : (user.accountStatus.isNotEmpty ? user.accountStatus : 'Active'),
      createdAt: createdVal.isNotEmpty ? createdVal : user.createdAt,
      updatedAt: updatedVal.isNotEmpty ? updatedVal : user.updatedAt,
      rawJson: json,
    );
  }

  RetailerProfileModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? name,
    String? email,
    String? mobileNumber,
    String? role,
    String? accountStatus,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? rawJson,
  }) {
    return RetailerProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'retailer_id': id,
    'name': name.trim(),
    'email': email.trim(),
    'mobile_no': mobileNumber.trim(),
  };
}

/// Abstract Repository contract for Retailer Profile operations.
abstract class IRetailerProfileRepository {
  Future<RetailerProfileModel> fetchProfile({bool forceRefresh = false});
  Future<RetailerProfileModel> updateProfile({
    required String name,
    required String email,
    required String mobileNo,
  });
  RetailerProfileModel? get cachedProfile;
}

/// Singleton/Shared Repository implementation for Retailer Profile.
class RetailerProfileRepository implements IRetailerProfileRepository {
  RetailerProfileRepository({RetailerProfileApis? apis})
      : _apis = apis ?? RetailerProfileApis();

  final RetailerProfileApis _apis;
  RetailerProfileModel? _cachedProfile;

  @override
  RetailerProfileModel? get cachedProfile => _cachedProfile;

  @override
  Future<RetailerProfileModel> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) {
      return _cachedProfile!;
    }
    try {
      _cachedProfile = await _apis.fetchProfile();
    } catch (_) {
      // Fallback to active session user data if backend fetch encounters issues
      _cachedProfile ??= RetailerProfileModel.fromSession();
    }
    return _cachedProfile!;
  }

  @override
  Future<RetailerProfileModel> updateProfile({
    required String name,
    required String email,
    required String mobileNo,
  }) async {
    final updated = await _apis.updateProfile(
      name: name,
      email: email,
      mobileNo: mobileNo,
    );

    // Update active UserData session instance
    final user = UserData.instance;
    user.name = updated.name.isNotEmpty ? updated.name : name.trim();
    user.email = updated.email.isNotEmpty ? updated.email : email.trim();
    user.mobileNumber = updated.mobileNumber.isNotEmpty
        ? updated.mobileNumber
        : mobileNo.trim();
    if (updated.updatedAt.isNotEmpty) {
      user.updatedAt = updated.updatedAt;
    }
    await user.saveToPreferences();

    _cachedProfile = updated;
    return updated;
  }
}

/// Shared instance of the Retailer Profile Repository.
final sharedRetailerProfileRepository = RetailerProfileRepository();

/// API service layer for Retailer Profile network calls.
class RetailerProfileApis {
  RetailerProfileApis({ApiClient? apiClient, http.Client? client})
      : _apiClient = apiClient ?? ApiClient(),
        _client = client ?? http.Client();

  static const String profileEndpoint = '/api/retailer/profile';

  final ApiClient _apiClient;
  final http.Client _client;

  String _getRetailerId() {
    final user = UserData.instance;
    final id = user.id.trim().isNotEmpty ? user.id.trim() : user.userId.trim();
    return id;
  }

  /// Fetches Retailer Profile from GET `/api/retailer/profile?retailer_id=<id>`
  Future<RetailerProfileModel> fetchProfile() async {
    final retailerId = _getRetailerId();
    final endpoint = retailerId.isNotEmpty
        ? '$profileEndpoint?retailer_id=${Uri.encodeComponent(retailerId)}'
        : profileEndpoint;

    try {
      final responseMap = await _apiClient.get(endpoint);
      _throwIfApiFailed(responseMap);
      return RetailerProfileModel.fromJson(responseMap);
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
      return RetailerProfileModel.fromSession();
    }
  }

  /// Updates Retailer Profile via PUT `/api/retailer/profile`
  Future<RetailerProfileModel> updateProfile({
    required String name,
    required String email,
    required String mobileNo,
  }) async {
    final retailerId = _getRetailerId();
    final payload = <String, dynamic>{
      if (retailerId.isNotEmpty) 'retailer_id': retailerId,
      'name': name.trim(),
      'email': email.trim(),
      'mobile_no': mobileNo.trim(),
    };

    try {
      final uri = _buildUri(profileEndpoint);
      log('PUT Profile Request: $uri\nHeaders: ${_headers()}\nBody: ${jsonEncode(payload)}');

      final response = await _client
          .put(
            uri,
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(ApiConstants.requestTimeout);

      log('PUT Profile Response [${response.statusCode}]: ${response.body}');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded);

      // Return parsed response or merged model
      final profileMap = _firstMap(decoded, const ['profile', 'user', 'retailer', 'data']);
      if (profileMap.isNotEmpty) {
        return RetailerProfileModel.fromJson(profileMap);
      }
      
      // Fallback: construct from session and updated values
      final current = RetailerProfileModel.fromSession();
      return current.copyWith(
        name: name.trim(),
        email: email.trim(),
        mobileNumber: mobileNo.trim(),
        updatedAt: DateTime.now().toIso8601String(),
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
      throw const ApiException('Something went wrong. Please try again.');
    }
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
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const <String, dynamic>{'success': true};
      }
      throw ApiException(
        _fallbackMessageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid response received from server.',
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
        return 'Bad request. Please check your profile details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to update this profile.';
      case 404:
        return 'Profile endpoint was not found.';
      case 409:
        return 'Email or mobile number is already in use.';
      case 422:
        return 'Please check the highlighted profile details.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

Map<String, dynamic> _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
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

void _throwIfApiFailed(Map<String, dynamic> response) {
  if (response['success'] != false) return;
  final message = response['message'] ?? response['error'];
  throw ApiException(
    message is String && message.trim().isNotEmpty
        ? message
        : 'Something went wrong. Please try again.',
  );
}
