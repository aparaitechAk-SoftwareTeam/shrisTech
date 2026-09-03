/// DTO for Retailer Registration API Response
class RegisterResponse {
  final bool success;
  final String message;
  final String? generatedUserId;

  const RegisterResponse({
    required this.success,
    required this.message,
    this.generatedUserId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: true,
      message: (json['message'] ?? '').toString(),
      generatedUserId: json['generatedUserId']?.toString(),
    );
  }
}
