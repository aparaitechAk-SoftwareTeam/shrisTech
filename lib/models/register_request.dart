/// DTO for Retailer Registration API Request
class RegisterRequest {
  final String name;
  final String mobile;
  final String email;
  final String shopName;
  final String address;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.mobile,
    required this.email,
    required this.shopName,
    required this.address,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'retailer_id': 'RET001',
      'business_name': shopName.trim(),
      'owner_name': name.trim(),
      'mobile_no': (mobile.trim().toString()),
      'address': address.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'status': 'Pending',
    };
  }
}
