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

class OwnerProfileModel {
  final BusinessInfoModel businessInfo;
  final BankDetailsModel bankDetails;
  final ContactDetailsModel contactDetails;
  final Map<String, dynamic> rawJson;

  const OwnerProfileModel({
    required this.businessInfo,
    required this.bankDetails,
    required this.contactDetails,
    this.rawJson = const <String, dynamic>{},
  });

  bool get hasData =>
      businessInfo.hasData || bankDetails.hasData || contactDetails.hasData;

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = _firstMap(json, const ['profile', 'owner', 'data']);
    final source = profile.isEmpty ? json : profile;
    return OwnerProfileModel(
      businessInfo: BusinessInfoModel.fromJson(
        _firstMap(source, const [
              'business_info',
              'businessInfo',
              'business',
            ]).isNotEmpty
            ? _firstMap(source, const [
                'business_info',
                'businessInfo',
                'business',
              ])
            : source,
      ),
      bankDetails: BankDetailsModel.fromJson(
        _firstMap(source, const [
              'bank_details',
              'bankDetails',
              'bank',
            ]).isNotEmpty
            ? _firstMap(source, const ['bank_details', 'bankDetails', 'bank'])
            : source,
      ),
      contactDetails: ContactDetailsModel.fromJson(
        _firstMap(source, const [
              'contact_details',
              'contactDetails',
              'contact',
            ]).isNotEmpty
            ? _firstMap(source, const [
                'contact_details',
                'contactDetails',
                'contact',
              ])
            : source,
      ),
      rawJson: json,
    );
  }

  OwnerProfileModel copyWith({
    BusinessInfoModel? businessInfo,
    BankDetailsModel? bankDetails,
    ContactDetailsModel? contactDetails,
    Map<String, dynamic>? rawJson,
  }) {
    return OwnerProfileModel(
      businessInfo: businessInfo ?? this.businessInfo,
      bankDetails: bankDetails ?? this.bankDetails,
      contactDetails: contactDetails ?? this.contactDetails,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_info': businessInfo.toJson(),
    'bank_details': bankDetails.toJson(),
    'contact_details': contactDetails.toJson(),
  };
}

class BusinessInfoModel {
  final String businessName;
  final String ownerName;
  final String mobileNumber;
  final String address;

  const BusinessInfoModel({
    required this.businessName,
    required this.ownerName,
    required this.mobileNumber,
    required this.address,
  });

  factory BusinessInfoModel.empty() {
    final user = UserData.instance;
    return BusinessInfoModel(
      businessName: '',
      ownerName: user.name,
      mobileNumber: user.mobileNumber,
      address: '',
    );
  }

  factory BusinessInfoModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return BusinessInfoModel.empty();
    return BusinessInfoModel(
      businessName: _readString(json, const [
        'business_name',
        'businessName',
        'shop_name',
        'shopName',
        'store_name',
      ]),
      ownerName: _readString(json, const [
        'owner_name',
        'ownerName',
        'name',
        'full_name',
      ]),
      mobileNumber: _readString(json, const [
        'mobile_number',
        'mobileNumber',
        'mobile_no',
        'mobile',
        'phone',
      ]),
      address: _readString(json, const [
        'address',
        'business_address',
        'shop_address',
      ]),
    );
  }

  bool get hasData =>
      businessName.isNotEmpty ||
      ownerName.isNotEmpty ||
      mobileNumber.isNotEmpty ||
      address.isNotEmpty;

  BusinessInfoModel copyWith({
    String? businessName,
    String? ownerName,
    String? mobileNumber,
    String? address,
  }) {
    return BusinessInfoModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_name': businessName.trim(),
    'owner_name': ownerName.trim(),
    'mobile_no': mobileNumber.trim(),
    'address': address.trim(),
  };
}

class BankDetailsModel {
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String branchName;
  final String upiId;

  const BankDetailsModel({
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    required this.branchName,
    required this.upiId,
  });

  const BankDetailsModel.empty()
    : bankName = '',
      accountNumber = '',
      ifsc = '',
      branchName = '',
      upiId = '';

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const BankDetailsModel.empty();
    return BankDetailsModel(
      bankName: _readString(json, const ['bank_name', 'bankName', 'bank']),
      accountNumber: _readString(json, const [
        'account_number',
        'accountNumber',
        'account_no',
      ]),
      ifsc: _readString(json, const [
        'ifsc_code',
        'ifscCode',
        'ifsc',
      ]).toUpperCase(),
      branchName: _readString(json, const [
        'branch_name',
        'branchName',
        'branch',
      ]),
      upiId: _readString(json, const ['upi_id', 'upiId', 'upi']),
    );
  }

  bool get hasData =>
      bankName.isNotEmpty ||
      accountNumber.isNotEmpty ||
      ifsc.isNotEmpty ||
      branchName.isNotEmpty ||
      upiId.isNotEmpty;

  String get maskedAccountNumber {
    final value = accountNumber.trim();
    if (value.isEmpty) return '';
    if (value.length <= 4) return value;
    return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
  }

  BankDetailsModel copyWith({
    String? bankName,
    String? accountNumber,
    String? ifsc,
    String? branchName,
    String? upiId,
  }) {
    return BankDetailsModel(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
    );
  }

  Map<String, dynamic> toJson() => {
    'bank_name': bankName.trim(),
    'account_number': accountNumber.trim(),
    'ifsc_code': ifsc.trim().toUpperCase(),
    'branch_name': branchName.trim(),
    'upi_id': upiId.trim(),
  };
}

class ContactDetailsModel {
  /// Matches API field: contact_person
  final String contactPerson;

  /// Matches API field: phone
  final String phone;

  /// Matches API field: whatsapp
  final String whatsapp;

  /// Matches API field: email
  final String email;

  const ContactDetailsModel({
    required this.contactPerson,
    required this.phone,
    this.whatsapp = '',
    this.email = '',
  });

  const ContactDetailsModel.empty()
    : contactPerson = '',
      phone = '',
      whatsapp = '',
      email = '';

  factory ContactDetailsModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const ContactDetailsModel.empty();
    // Support both top-level and nested 'contact' key from GET /api/contact-information
    final source = json['contact'] is Map<String, dynamic>
        ? json['contact'] as Map<String, dynamic>
        : json;
    return ContactDetailsModel(
      contactPerson: _readString(source, const [
        'owner_name',
        'contactPerson',
        'name',
        'contact_name',
      ]),
      phone: _readString(source, const [
        'phone',
        'mobile_number',
        'mobileNumber',
        'mobile_no',
        'mobile',
      ]),
      whatsapp: _readString(source, const [
        'whatsapp',
        'alternative_no',

        'whatsappNumber',
      ]),
      email: _readString(source, const ['email', 'email_id', 'emailId']),
    );
  }

  bool get hasData =>
      contactPerson.isNotEmpty ||
      phone.isNotEmpty ||
      whatsapp.isNotEmpty ||
      email.isNotEmpty;

  ContactDetailsModel copyWith({
    String? contactPerson,
    String? phone,
    String? whatsapp,
    String? email,
  }) {
    return ContactDetailsModel(
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
    );
  }

  /// Serialises to the PUT /api/contact-information body format.
  Map<String, dynamic> toJson() => {
    'owner_name': contactPerson.trim(),
    'phone': phone.trim(),
    'whatsapp': whatsapp.trim(),
    'email': email.trim(),
  };
}

abstract class IOwnerProfileRepository {
  Future<OwnerProfileModel> fetchProfile({bool forceRefresh = false});

  Future<OwnerProfileModel> refreshProfile();

  Future<void> updateProfile(Map<String, dynamic> payload);

  Future<void> updateContactInformation(Map<String, dynamic> payload);

  OwnerProfileModel? get cachedProfile;
}

class OwnerProfileRepository implements IOwnerProfileRepository {
  OwnerProfileRepository({OwnerProfileApis? apis})
    : _apis = apis ?? OwnerProfileApis();

  final OwnerProfileApis _apis;
  OwnerProfileModel? _cachedProfile;

  @override
  OwnerProfileModel? get cachedProfile => _cachedProfile;

  @override
  Future<OwnerProfileModel> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) return _cachedProfile!;
    _cachedProfile = await _apis.fetchProfile();
    return _cachedProfile!;
  }

  @override
  Future<OwnerProfileModel> refreshProfile() {
    return fetchProfile(forceRefresh: true);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> payload) async {
    await _apis.updateProfile(payload);
    _cachedProfile = null;
  }

  @override
  Future<void> updateContactInformation(Map<String, dynamic> payload) async {
    await _apis.updateContactInformation(payload);
    _cachedProfile = null;
  }
}

class OwnerProfileApis {
  OwnerProfileApis({ApiClient? apiClient, http.Client? client})
    : _apiClient = apiClient ?? ApiClient(),
      _client = client ?? http.Client();

  static const String profileEndpoint = '/api/owner-profile';
  static const String contactInfoEndpoint = '/api/contact-information';

  final ApiClient _apiClient;
  final http.Client _client;

  static const String defaultOwnerId = '082ab0bb-0a20-47fc-8ed9-7a1daf9119cd';

  String _getOwnerId() {
    return defaultOwnerId;
  }

  Future<OwnerProfileModel> fetchProfile() async {
    final ownerId = _getOwnerId();
    final profileEndpointWithQuery = ownerId.isNotEmpty
        ? '$profileEndpoint?owner_id=$ownerId'
        : profileEndpoint;
    final contactEndpointWithQuery = ownerId.isNotEmpty
        ? '$contactInfoEndpoint?owner_id=$ownerId'
        : contactInfoEndpoint;

    final profileResponseFuture = _apiClient.get(profileEndpointWithQuery);
    final contactResponseFuture = _apiClient
        .get(contactEndpointWithQuery)
        .catchError((_) => <String, dynamic>{});

    final results = await Future.wait([
      profileResponseFuture,
      contactResponseFuture,
    ]);
    final profileResponse = results[0];
    final contactResponse = results[1];

    _throwIfApiFailed(profileResponse);

    final merged = Map<String, dynamic>.from(profileResponse);
    if (contactResponse.isNotEmpty && contactResponse['success'] != false) {
      // The GET /api/contact-information response has the nested 'contact' key
      // Pass the full contactResponse so ContactDetailsModel.fromJson can read it
      merged['contact_details'] = contactResponse;
    }

    return OwnerProfileModel.fromJson(merged);
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    if (payload.isEmpty) {
      throw const ApiException('No profile changes to update.');
    }

    final ownerId = _getOwnerId();
    final bodyPayload = Map<String, dynamic>.from(payload);
    if (ownerId.isNotEmpty && !bodyPayload.containsKey('owner_id')) {
      bodyPayload['owner_id'] = ownerId;
    }

    try {
      log(
        'Update Profile Request: ${_buildUri(profileEndpoint)}\nHeaders: ${_headers()}\nBody: ${jsonEncode(bodyPayload)}',
      );
      final response = await _client
          .patch(
            _buildUri(profileEndpoint),
            headers: _headers(),
            body: jsonEncode(bodyPayload),
          )
          .timeout(ApiConstants.requestTimeout);
      log('Update Profile Response: ${response.body}');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded);
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

  Future<void> updateContactInformation(Map<String, dynamic> payload) async {
    if (payload.isEmpty) {
      throw const ApiException('No contact info changes to update.');
    }

    final ownerId = _getOwnerId();

    // Build final body: { owner_id, contact_person, phone, whatsapp, email }
    final bodyPayload = <String, dynamic>{'owner_id': ownerId};
    bodyPayload.addAll(payload);

    try {
      log(
        'Update ContactInfo Request: ${_buildUri(contactInfoEndpoint)}\nBody: ${jsonEncode(bodyPayload)}',
      );
      final response = await _client
          .put(
            _buildUri(contactInfoEndpoint),
            headers: _headers(),
            body: jsonEncode(bodyPayload),
          )
          .timeout(ApiConstants.requestTimeout);
      log('Update ContactInfo Response: ${response.body}');
      final decoded = _decodeResponse(response);
      _throwIfApiFailed(decoded);
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
        return 'Bad request. Please check the profile details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to update this profile.';
      case 404:
        return 'Profile data was not found.';
      case 409:
        return 'Profile details already exist.';
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
