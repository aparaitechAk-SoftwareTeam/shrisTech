import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../userdata.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      log('GET: $uri');
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(ApiConstants.requestTimeout);
      log('Response ${response.statusCode}: ${response.body}');
      return _decodeResponse(response);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out.\nPlease try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      log(e.toString());
      throw const ApiException('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      log('message Post');
      final baseUrl = ApiConstants.activeBaseUrl;
      final separator = baseUrl.endsWith('/') || endpoint.startsWith('/')
          ? ''
          : '/';
      final uri = Uri.parse('$baseUrl$separator$endpoint');
      log('POST: $uri');
      final response = await _client
          .post(
            uri,
            headers: const {
              ApiConstants.headerContentType: ApiConstants.contentTypeJson,
              ApiConstants.headerAccept: ApiConstants.contentTypeJson,
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      log('Response ${response.statusCode}: ${response.body}');
      return _decodeResponse(response);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out.\nPlease try again.');
    } on FormatException {
      throw const ApiException('Something went wrong. 1');
    } on ApiException {
      rethrow;
    } catch (e) {
      log('Fatal API Error: ${e.toString()}');
      throw ApiException(
        'Network Request Blocked. If testing on Chrome, CORS may be preventing the connection. Original error: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      log('PUT: $uri');
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      log('Response ${response.statusCode}: ${response.body}');
      return _decodeResponse(response);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out.\nPlease try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      log(e.toString());
      throw const ApiException('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      log('PATCH: $uri');
      final response = await _client
          .patch(uri, headers: _buildHeaders(), body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);
      log('Response ${response.statusCode}: ${response.body}');
      return _decodeResponse(response);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out.\nPlease try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      log(e.toString());
      throw const ApiException('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      log('DELETE: $uri');
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      log('Response ${response.statusCode}: ${response.body}');
      return _decodeResponse(response);
    } on SocketException {
      throw const ApiException('Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out.\nPlease try again.');
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      log(e.toString());
      throw const ApiException('Something went wrong. Please try again.');
    }
  }

  Uri _buildUri(String endpoint) {
    final baseUrl = ApiConstants.activeBaseUrl;
    final separator = baseUrl.endsWith('/') || endpoint.startsWith('/')
        ? ''
        : '/';
    return Uri.parse('$baseUrl$separator$endpoint');
  }

  Map<String, String> _buildHeaders() {
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

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'Invalid response received from server.',
        statusCode: response.statusCode,
      );
    }

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
        return 'Bad request. Please check the submitted details.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested data was not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
