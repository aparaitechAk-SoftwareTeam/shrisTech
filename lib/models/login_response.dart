import 'auth_model.dart';

/// DTO for Login API Response
class LoginResponse {
  final bool success;
  final String message;
  final AuthModel? user;
  final String? role;
  final Map<String, dynamic>? rawResponse;

  const LoginResponse({
    required this.success,
    required this.message,
    this.user,
    this.role,
    this.rawResponse,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return LoginResponse(
      success: userJson is Map<String, dynamic> || json['token'] != null,
      message: (json['message'] ?? '').toString(),
      user: userJson is Map<String, dynamic>
          ? AuthModel.fromJson(userJson)
          : null,
      role: json['role']?.toString() ??
          (userJson is Map<String, dynamic> ? userJson['role']?.toString() : null),
      rawResponse: json,
    );
  }
}
