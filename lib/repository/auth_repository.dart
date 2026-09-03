import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/forgot_password_models.dart';

abstract class IAuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<RegisterResponse> registerRetailer(RegisterRequest request);
  Future<String?> fetchServerGeneratedUserId();
  Future<ForgotPasswordResponse> forgotPassword(String user);
  Future<ResetPasswordResponse> resetPassword(String user, String newPassword);
}

class AuthRepository implements IAuthRepository {
  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final json = await _apiClient.post(
      ApiConstants.loginEndpoint,
      body: request.toJson(),
    );
    return LoginResponse.fromJson(json);
  }

  @override
  Future<RegisterResponse> registerRetailer(RegisterRequest request) async {
    final json = await _apiClient.post(
      ApiConstants.registerRetailerEndpoint,
      body: request.toJson(),
    );
    return RegisterResponse.fromJson(json);
  }

  @override
  Future<String?> fetchServerGeneratedUserId() async {
    return null;
  }

  @override
  Future<ForgotPasswordResponse> forgotPassword(String user) async {
    final json = await _apiClient.post(
      ApiConstants.apiForgotPasswordEndpoint,
      body: {'user': user},
    );
    return ForgotPasswordResponse.fromJson(json);
  }

  @override
  Future<ResetPasswordResponse> resetPassword(String user, String newPassword) async {
    final json = await _apiClient.post(
      ApiConstants.apiResetPasswordEndpoint,
      body: {
        'user': user,
        'newPassword': newPassword,
      },
    );
    return ResetPasswordResponse.fromJson(json);
  }
}
