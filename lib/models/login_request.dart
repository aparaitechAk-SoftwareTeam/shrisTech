/// DTO for Login API Request
class LoginRequest {
  final String identity; // Email or User ID
  final String password;
  final bool rememberMe;

  const LoginRequest({
    required this.identity,
    required this.password,
    this.rememberMe = true,
  });

  Map<String, dynamic> toJson() {
    return {'username': identity.trim(), 'password': password};
  }
}
