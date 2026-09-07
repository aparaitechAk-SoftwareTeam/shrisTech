/// User role enum for BBS GOLD platform
enum UserRole { owner, retailer, dealer }

/// Data model representing authenticated user session details
class AuthModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String mobile;
  final String shopName;
  final String address;
  final UserRole role;
  final bool isApproved;
  final String token;

  const AuthModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.shopName,
    required this.address,
    required this.role,
    required this.isApproved,
    required this.token,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final roleValue = (json['role'] ?? '').toString().toLowerCase();

    return AuthModel(
      id: (json['id'] ?? json['_id'] ?? json['retailer_id'] ?? json['uuid'] ?? '')
          .toString(),
      userId: (json['userId'] ?? json['user_id'] ?? json['username'] ?? '')
          .toString(),
      name: (json['name'] ?? json['owner_name'] ?? json['business_name'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      mobile: (json['mobile'] ?? json['mobile_no'] ?? '').toString(),
      shopName: (json['shopName'] ?? json['business_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == roleValue,
        orElse: () => UserRole.retailer,
      ),
      isApproved: json['isApproved'] ?? json['account_status'] == 'active',
      token: (json['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'shopName': shopName,
      'address': address,
      'role': role.name,
      'isApproved': isApproved,
      'token': token,
    };
  }
}
