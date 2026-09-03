class ForgotPasswordResponse {
  final bool success;
  final String message;
  final String? userId;
  final String? email;
  final String? name;

  ForgotPasswordResponse({
    required this.success,
    required this.message,
    this.userId,
    this.email,
    this.name,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return ForgotPasswordResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      userId: userJson != null ? (userJson['userId'] ?? userJson['user_id'] ?? '').toString() : null,
      email: userJson != null ? (userJson['email'] ?? '').toString() : null,
      name: userJson != null ? (userJson['name'] ?? '').toString() : null,
    );
  }
}

class ResetPasswordResponse {
  final bool success;
  final String message;

  ResetPasswordResponse({
    required this.success,
    required this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    // Sometimes message is returned, success is implied by status 200 or custom success field
    return ResetPasswordResponse(
      success: json['success'] != false, // defaults to true if not explicitly false
      message: (json['message'] ?? 'Password reset completed successfully.').toString(),
    );
  }
}
