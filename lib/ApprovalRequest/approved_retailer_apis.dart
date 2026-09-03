import 'dart:developer';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class PendingRequestModel {
  final String id;
  final String requestId;
  final String ownerName;
  final String businessName;
  final String userId;
  final String email;
  final String mobileNumber;
  final String address;
  final String status;
  final String registrationStatus;
  final String accountStatus;
  final Map<String, dynamic> rawJson;

  const PendingRequestModel({
    required this.id,
    required this.requestId,
    required this.ownerName,
    required this.businessName,
    required this.userId,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.status,
    required this.registrationStatus,
    required this.accountStatus,
    required this.rawJson,
  });

  factory PendingRequestModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final retailer = _asMap(json['retailer']);
    final source = {...retailer, ...user, ...json};

    return PendingRequestModel(
      id: _readString(source, const ['id', '_id']),
      requestId: _readString(source, const [
        'request_id',
        'requestId',
        'approval_request_id',
        'id',
        '_id',
      ]),
      ownerName: _readString(source, const [
        'owner_name',
        'ownerName',
        'name',
        'full_name',
        'username',
      ]),
      businessName: _readString(source, const [
        'business_name',
        'businessName',
        'shop_name',
        'shopName',
        'store_name',
      ]),
      userId: _readString(source, const ['user_id', 'userId']),
      email: _readString(source, const ['email', 'email_address']),
      mobileNumber: _readString(source, const [
        'mobile_no',
        'mobile',
        'mobileNumber',
        'phone',
        'phone_no',
      ]),
      address: _readString(source, const [
        'address',
        'shop_address',
        'business_address',
      ]),
      status: _readString(source, const ['status'], fallback: 'Pending'),
      registrationStatus: _readString(source, const [
        'registration_status',
        'registrationStatus',
      ], fallback: _readString(source, const ['status'], fallback: 'Pending')),
      accountStatus: _readString(source, const [
        'account_status',
        'accountStatus',
      ], fallback: 'Pending'),
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request_id': requestId,
    'owner_name': ownerName,
    'business_name': businessName,
    'user_id': userId,
    'email': email,
    'mobile_no': mobileNumber,
    'address': address,
    'status': status,
    'registration_status': registrationStatus,
    'account_status': accountStatus,
  };

  RetailerDetailsData toDetails() {
    return RetailerDetailsData(
      id: id,
      requestId: requestId,
      ownerName: ownerName,
      businessName: businessName,
      userId: userId,
      email: email,
      mobileNumber: mobileNumber,
      address: address,
      status: status,
      registrationStatus: registrationStatus,
      accountStatus: accountStatus,
      rawJson: rawJson,
    );
  }

  bool matches(String query) => _matchesFields(query, [
    ownerName,
    businessName,
    email,
    mobileNumber,
    userId,
  ]);
}

class ApprovedRetailerModel {
  final String id;
  final String requestId;
  final String ownerName;
  final String businessName;
  final String userId;
  final String email;
  final String mobileNumber;
  final String address;
  final String status;
  final String registrationStatus;
  final String accountStatus;
  final Map<String, dynamic> rawJson;

  const ApprovedRetailerModel({
    required this.id,
    required this.requestId,
    required this.ownerName,
    required this.businessName,
    required this.userId,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.status,
    required this.registrationStatus,
    required this.accountStatus,
    required this.rawJson,
  });

  factory ApprovedRetailerModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final source = {...user, ...json};

    final id = _readString(source, const [
      'id',
      '_id',
      'retailer_id',
      'user_id',
    ]);
    final reqId = _readString(source, const [
      'request_id',
      'requestId',
      'approval_request_id',
      'id',
      '_id',
      'user_id',
    ]);

    return ApprovedRetailerModel(
      id: id.isNotEmpty ? id : reqId,
      requestId: reqId.isNotEmpty ? reqId : id,
      ownerName: _readString(source, const [
        'owner_name',
        'ownerName',
        'name',
        'full_name',
        'username',
      ]),
      businessName: _readString(source, const [
        'business_name',
        'businessName',
        'shop_name',
        'shopName',
        'store_name',
      ]),
      userId: _readString(source, const ['user_id', 'userId']),
      email: _readString(source, const ['email', 'email_address']),
      mobileNumber: _readString(source, const [
        'mobile_no',
        'mobile',
        'mobileNumber',
        'phone',
        'phone_no',
      ]),
      address: _readString(source, const [
        'address',
        'shop_address',
        'business_address',
      ]),
      status: _readString(source, const ['status'], fallback: 'Active'),
      registrationStatus: _readString(source, const [
        'registration_status',
        'registrationStatus',
      ], fallback: 'Approved'),
      accountStatus: _readString(source, const [
        'account_status',
        'accountStatus',
      ], fallback: _readString(source, const ['status'], fallback: 'Active')),
      rawJson: json,
    );
  }

  ApprovedRetailerModel copyWith({String? status, String? accountStatus}) {
    return ApprovedRetailerModel(
      id: id,
      requestId: requestId,
      ownerName: ownerName,
      businessName: businessName,
      userId: userId,
      email: email,
      mobileNumber: mobileNumber,
      address: address,
      status: status ?? this.status,
      registrationStatus: registrationStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      rawJson: rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request_id': requestId,
    'owner_name': ownerName,
    'business_name': businessName,
    'user_id': userId,
    'email': email,
    'mobile_no': mobileNumber,
    'address': address,
    'status': status,
    'registration_status': registrationStatus,
    'account_status': accountStatus,
  };

  RetailerDetailsData toDetails() {
    return RetailerDetailsData(
      id: id,
      requestId: requestId,
      ownerName: ownerName,
      businessName: businessName,
      userId: userId,
      email: email,
      mobileNumber: mobileNumber,
      address: address,
      status: status,
      registrationStatus: registrationStatus,
      accountStatus: accountStatus,
      rawJson: rawJson,
    );
  }

  bool matches(String query) => _matchesFields(query, [
    ownerName,
    businessName,
    email,
    mobileNumber,
    userId,
  ]);
}

class RetailerDetailsData {
  final String id;
  final String requestId;
  final String ownerName;
  final String businessName;
  final String userId;
  final String email;
  final String mobileNumber;
  final String address;
  final String status;
  final String registrationStatus;
  final String accountStatus;
  final Map<String, dynamic> rawJson;

  const RetailerDetailsData({
    required this.id,
    required this.requestId,
    required this.ownerName,
    required this.businessName,
    required this.userId,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.status,
    required this.registrationStatus,
    required this.accountStatus,
    required this.rawJson,
  });
}

abstract class IApprovedRetailerRepository {
  Future<List<PendingRequestModel>> fetchPendingRequests();

  Future<void> approveRequest(String requestId);

  Future<void> rejectRequest(String requestId);

  Future<List<ApprovedRetailerModel>> fetchApprovedRetailers();

  Future<ApprovedRetailerModel> activateRetailer(
    ApprovedRetailerModel retailer,
  );

  Future<ApprovedRetailerModel> deactivateRetailer(
    ApprovedRetailerModel retailer,
  );
}

class ApprovedRetailerRepository implements IApprovedRetailerRepository {
  ApprovedRetailerRepository({ApprovedRetailerApis? apis})
    : _apis = apis ?? ApprovedRetailerApis();

  final ApprovedRetailerApis _apis;

  @override
  Future<List<PendingRequestModel>> fetchPendingRequests() {
    return _apis.fetchPendingRequests();
  }

  @override
  Future<void> approveRequest(String requestId) {
    return _apis.approveRequest(requestId);
  }

  @override
  Future<void> rejectRequest(String requestId) {
    return _apis.rejectRequest(requestId);
  }

  @override
  Future<List<ApprovedRetailerModel>> fetchApprovedRetailers() {
    return _apis.fetchApprovedRetailers();
  }

  @override
  Future<ApprovedRetailerModel> activateRetailer(
    ApprovedRetailerModel retailer,
  ) {
    return _apis.activateRetailer(retailer);
  }

  @override
  Future<ApprovedRetailerModel> deactivateRetailer(
    ApprovedRetailerModel retailer,
  ) {
    return _apis.deactivateRetailer(retailer);
  }
}

class ApprovedRetailerApis {
  ApprovedRetailerApis({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PendingRequestModel>> fetchPendingRequests() async {
    final response = await _apiClient.get(
      ApiConstants.approvalRequestsEndpoint,
    );
    final requests = _readList(response, 'requests');

    return requests
        .whereType<Map<String, dynamic>>()
        .map(PendingRequestModel.fromJson)
        .where((request) {
          final status = request.status.toLowerCase();
          final registrationStatus = request.registrationStatus.toLowerCase();
          final accountStatus = request.accountStatus.toLowerCase();
          return status == 'pending' ||
              registrationStatus == 'pending' ||
              accountStatus == 'pending';
        })
        .toList(growable: false);
  }

  Future<void> approveRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw const ApiException('Request ID is missing.');
    }
    await _apiClient.put(
      '${ApiConstants.approvalRequestsEndpoint}/$requestId',
      body: const {'status': 'Active'},
    );
  }

  Future<void> rejectRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw const ApiException('Request ID is missing.');
    }
    await _apiClient.put(
      '${ApiConstants.approvalRequestsEndpoint}/$requestId',
      body: const {'status': 'Rejected'},
    );
  }

  Future<List<ApprovedRetailerModel>> fetchApprovedRetailers() async {
    final response = await _apiClient.get(ApiConstants.retailersEndpoint);
    final retailers = _readList(response, 'retailers');

    return retailers
        .whereType<Map<String, dynamic>>()
        .map(ApprovedRetailerModel.fromJson)
        .where((retailer) {
          final status = retailer.status.toLowerCase();
          final regStatus = retailer.registrationStatus.toLowerCase();
          final accountStatus = retailer.accountStatus.toLowerCase();
          return status != 'pending' &&
              regStatus != 'pending' &&
              accountStatus != 'pending';
        })
        .toList(growable: false);
  }

  Future<ApprovedRetailerModel> activateRetailer(
    ApprovedRetailerModel retailer,
  ) async {
    // Use userId (e.g. BBS002) as the path param — this is the PUT /api/retailers/{user_id} endpoint
    final userId = retailer.userId.isNotEmpty ? retailer.userId : retailer.id;

    if (userId.trim().isEmpty) {
      throw const ApiException('Retailer User ID is missing.');
    }

    try {
      await _apiClient.put(
        ApiConstants.retailersEndpoint,
        body: {'user_id': userId, 'status': 'Active'},
      );
    } catch (e) {
      log('activateRetailer error: $e');
      rethrow;
    }

    return retailer.copyWith(status: 'Active', accountStatus: 'Active');
  }

  Future<ApprovedRetailerModel> deactivateRetailer(
    ApprovedRetailerModel retailer,
  ) async {
    // Use userId (e.g. BBS002) as the path param — this is the PUT /api/retailers/{user_id} endpoint
    final userId = retailer.userId.isNotEmpty ? retailer.userId : retailer.id;
    log('message: ${retailer.accountStatus}');

    if (userId.trim().isEmpty) {
      throw const ApiException('Retailer User ID is missing.');
    }
    try {
      await _apiClient.put(
        ApiConstants.retailersEndpoint,
        body: {'user_id': userId, 'status': 'Inactive'},
      );
    } catch (e) {
      log('deactivateRetailer error: $e');
      rethrow;
    }

    return retailer.copyWith(status: 'Inactive', accountStatus: 'Inactive');
  }
}

List<dynamic> _readList(Map<String, dynamic> response, String key) {
  final value = response[key];
  if (value is List) return value;
  if (value == null) return const [];
  throw const ApiException('Invalid response received from server.');
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
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

bool _matchesFields(String query, List<String> fields) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return fields.any((field) => field.toLowerCase().contains(normalized));
}
