import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton Global User Session Manager for BBS GOLD.
/// Holds authenticated user data across the application lifecycle.
class UserData {
  static final UserData _instance = UserData._internal();
  static UserData get instance => _instance;

  UserData._internal();

  // SharedPreferences Keys
  static const String _keyUserSession = 'bbs_gold_user_session';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  // Fields
  String id = '';
  String userId = '';
  String username = '';
  String name = '';
  String email = '';
  String mobileNumber = '';
  String role = '';
  String accountStatus = '';
  String token = '';
  String createdAt = '';
  String updatedAt = '';
  String message = '';
  bool isLoggedIn = false;

  /// Returns the actual Database UUID of the user.
  String get uuid {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(id.trim())) return id.trim();
    if (uuidRegex.hasMatch(userId.trim())) return userId.trim();
    if (id.trim().isNotEmpty) return id.trim();
    return userId.trim();
  }

  /// Copies and stores all fields from the full Login API response JSON.
  void copyFromResponse(Map<String, dynamic> response) {
    final userMap = response['user'] is Map<String, dynamic>
        ? response['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    id = (userMap['id'] ??
            userMap['_id'] ??
            userMap['retailer_id'] ??
            userMap['retailerId'] ??
            userMap['uuid'] ??
            response['id'] ??
            response['_id'] ??
            response['retailer_id'] ??
            response['uuid'] ??
            '')
        .toString();
    userId =
        (userMap['user_id'] ?? userMap['userId'] ?? response['user_id'] ?? '')
            .toString();
    username = (userMap['username'] ?? response['username'] ?? '').toString();
    name = (userMap['name'] ?? response['name'] ?? '').toString();
    email = (userMap['email'] ?? response['email'] ?? '').toString();
    mobileNumber =
        (userMap['mobile_no'] ??
                userMap['mobile'] ??
                response['mobile_no'] ??
                '')
            .toString();
    role = (response['role'] ?? userMap['role'] ?? '').toString();
    accountStatus =
        (userMap['account_status'] ??
                userMap['accountStatus'] ??
                response['account_status'] ??
                'Active')
            .toString();
    token = (response['token'] ?? userMap['token'] ?? '').toString();
    createdAt = (userMap['created_at'] ?? response['created_at'] ?? '')
        .toString();
    updatedAt = (userMap['updated_at'] ?? response['updated_at'] ?? '')
        .toString();
    message = (response['message'] ?? '').toString();
    isLoggedIn = token.isNotEmpty;
  }

  /// Deserializes user session data from a Map
  void fromJson(Map<String, dynamic> json) {
    id = (json['id'] ??
            json['_id'] ??
            json['retailer_id'] ??
            json['retailerId'] ??
            json['uuid'] ??
            '')
        .toString();
    userId = (json['user_id'] ?? json['userId'] ?? '').toString();
    username = (json['username'] ?? '').toString();
    name = (json['name'] ?? '').toString();
    email = (json['email'] ?? '').toString();
    mobileNumber = (json['mobile_no'] ?? json['mobileNumber'] ?? '').toString();
    role = (json['role'] ?? '').toString();
    accountStatus = (json['account_status'] ?? json['accountStatus'] ?? '')
        .toString();
    token = (json['token'] ?? '').toString();
    createdAt = (json['created_at'] ?? json['createdAt'] ?? '').toString();
    updatedAt = (json['updated_at'] ?? json['updatedAt'] ?? '').toString();
    message = (json['message'] ?? '').toString();
    isLoggedIn = json['isLoggedIn'] ?? (token.isNotEmpty && role.isNotEmpty);
  }

  /// Serializes user session data to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'name': name,
      'email': email,
      'mobile_no': mobileNumber,
      'role': role,
      'account_status': accountStatus,
      'token': token,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'message': message,
      'isLoggedIn': isLoggedIn,
    };
  }

  /// Saves the current user session data to SharedPreferences
  Future<bool> saveToPreferences([SharedPreferences? prefs]) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(toJson());
      await sp.setString(_keyUserSession, jsonStr);
      await sp.setBool(_keyIsLoggedIn, isLoggedIn);
      await sp.setString('id', id);
      await sp.setString('role', role);
      await sp.setString('email', email);
      await sp.setString('username', username);
      await sp.setString('user_id', userId);
      await sp.setString('name', name);
      await sp.setString('mobile_no', mobileNumber);
      await sp.setString('account_status', accountStatus);
      await sp.setString('token', token);
      await sp.setString('created_at', createdAt);
      await sp.setString('updated_at', updatedAt);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads user session data from SharedPreferences
  Future<bool> loadFromPreferences([SharedPreferences? prefs]) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final loggedIn = sp.getBool(_keyIsLoggedIn) ?? false;
      final jsonStr = sp.getString(_keyUserSession);

      if (!loggedIn || jsonStr == null || jsonStr.isEmpty) {
        clear();
        return false;
      }

      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        fromJson(map);

        // Validation check for corrupted/invalid session
        if (token.isEmpty || role.isEmpty) {
          clear();
          await sp.clear();
          return false;
        }
        return true;
      } else {
        clear();
        await sp.clear();
        return false;
      }
    } catch (_) {
      clear();
      return false;
    }
  }

  /// Resets all user session fields to initial state
  void clear() {
    id = '';
    userId = '';
    username = '';
    name = '';
    email = '';
    mobileNumber = '';
    role = '';
    accountStatus = '';
    token = '';
    createdAt = '';
    updatedAt = '';
    message = '';
    isLoggedIn = false;
  }
}
