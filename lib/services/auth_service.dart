import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/userdata.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/forgot_password_models.dart';
import '../repository/auth_repository.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/owner_home_screen.dart';
import '../screens/home/retailer_home_screen.dart';
import 'fcm_service.dart';

/// Singleton Authentication Service managing user session state & operations.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final IAuthRepository _repository = AuthRepository();

  bool get isLoggedIn => UserData.instance.isLoggedIn;
  String? get currentRole => UserData.instance.role;

  /// Handles Login Action using AuthRepository, parses full response,
  /// fills UserData.instance, and persists to SharedPreferences.
  Future<LoginResponse> login({
    required String identity,
    required String password,
    bool rememberMe = true,
  }) async {
    final request = LoginRequest(
      identity: identity,
      password: password,
      rememberMe: rememberMe,
    );

    final response = await _repository.login(request);
    if (response.success) {
      if (response.rawResponse != null) {
        log('Login successful for user Filling 1 .');
        UserData.instance.copyFromResponse(response.rawResponse!);
        log('Login successful: ${UserData.instance.email}.');
      } else if (response.user != null) {
        UserData.instance.copyFromResponse({
          'user': response.user!.toJson(),
          'role': response.role ?? response.user!.role.name,
          'token': response.user!.token,
          'message': response.message,
        });
      }
      await UserData.instance.saveToPreferences();
      // Sync the FCM device token with the backend now that the user UUID is available
      try {
        await FcmService().syncDeviceToken();
      } catch (e) {
        log('Failed to sync FCM token on login: $e');
      }
    }
    return response;
  }

  /// Handles Retailer Registration Action using AuthRepository.
  Future<RegisterResponse> registerRetailer({
    required String name,
    required String mobile,
    required String email,
    required String shopName,
    required String address,
    required String password,
  }) async {
    final request = RegisterRequest(
      name: name,
      mobile: mobile,
      email: email,
      shopName: shopName,
      address: address,
      password: password,
    );

    return await _repository.registerRetailer(request);
  }

  /// Checks persistent login status on app startup.
  /// Returns true if a valid logged-in session exists.
  Future<bool> checkInitialSession() async {
    try {
      final isLoggedIn = await UserData.instance.loadFromPreferences();
      if (!isLoggedIn) return false;

      // Verify the token with the backend
      final isValid = await _repository.verifyToken();
      if (!isValid) {
        log('Session expired, clearing preferences.');
        await logout();
        return false;
      }
      return true;
    } catch (_) {
      UserData.instance.clear();
      return false;
    }
  }

  /// Returns the correct home screen widget based on the user's role.
  Widget getRoleBasedHomeScreen([String? role]) {
    final r = (role ?? UserData.instance.role).trim().toLowerCase();
    if (r == 'owner') {
      return const OwnerHomeScreen();
    }
    return const RetailerHomeScreen();
  }

  /// Navigates user to the appropriate home screen by replacing the entire stack.
  void navigateByRole(BuildContext context, [String? role]) {
    final screen = getRoleBasedHomeScreen(role);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Clears SharedPreferences, detaches FCM token, clears UserData.instance, and navigates to Login.
  Future<void> logout([BuildContext? context]) async {
    try {
      await FcmService().clearDeviceToken();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    log('Cleared SharedPreferences ${UserData.instance.email}.');
    UserData.instance.clear();
    log('UserData cleared. ${UserData.instance.email}.');
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(String user) async {
    return await _repository.forgotPassword(user);
  }

  Future<ResetPasswordResponse> resetPassword(
    String user,
    String newPassword,
  ) async {
    return await _repository.resetPassword(user, newPassword);
  }
}
