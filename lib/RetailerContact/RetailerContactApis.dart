// ignore_for_file: file_names

import 'dart:developer';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class RetailerContactModel {
  final String ownerId;
  final String ownerName;
  final String phone;
  final String whatsapp;
  final String email;

  const RetailerContactModel({
    required this.ownerId,
    required this.ownerName,
    required this.phone,
    required this.whatsapp,
    required this.email,
  });

  const RetailerContactModel.empty()
      : ownerId = '',
        ownerName = '',
        phone = '',
        whatsapp = '',
        email = '';

  factory RetailerContactModel.fromJson(Map<String, dynamic> json) {
    // API returns contact inside "contact" field or top-level. Let's handle both.
    final data = json['contact'] is Map<String, dynamic>
        ? json['contact'] as Map<String, dynamic>
        : json;

    return RetailerContactModel(
      ownerId: (data['owner_id'] ?? '').toString(),
      ownerName: (data['owner_name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      whatsapp: (data['whatsapp'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'owner_name': ownerName,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
    };
  }
}

abstract class IRetailerContactRepository {
  Future<RetailerContactModel> fetchContactInformation({bool forceRefresh = false});
}

class RetailerContactRepository implements IRetailerContactRepository {
  final ApiClient _apiClient;
  RetailerContactModel? _cachedContact;

  RetailerContactRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<RetailerContactModel> fetchContactInformation({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedContact != null) {
      return _cachedContact!;
    }

    try {
      const String ownerId = '082ab0bb-0a20-47fc-8ed9-7a1daf9119cd';
      final endpoint = '/api/contact-information?owner_id=$ownerId';
      log('Fetching Retailer Contact details from: $endpoint');

      final response = await _apiClient.get(endpoint);
      if (response['success'] == true) {
        _cachedContact = RetailerContactModel.fromJson(response);
        return _cachedContact!;
      } else {
        throw ApiException(response['message'] ?? 'Failed to fetch contact details.');
      }
    } catch (e) {
      log('Error fetching contact details: $e');
      rethrow;
    }
  }
}
