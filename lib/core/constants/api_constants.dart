/// API Endpoint Constants and Architecture Placeholders for BBS GOLD.
/// Ready for instant backend integration.
abstract class ApiConstants {
  // Base URLs
  static const String baseUrlProduction = 'https://bbs-gold-app.vercel.app';
  static const String baseUrlStaging = 'https://bbs-gold-app.vercel.app';
  static const String activeBaseUrl = baseUrlProduction;

  // Timeouts
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const Duration requestTimeout = Duration(milliseconds: 30000);

  // Endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerRetailerEndpoint = '/api/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String apiForgotPasswordEndpoint = '/api/forgot-password';
  static const String apiResetPasswordEndpoint = '/api/reset-password';
  static const String verifyTokenEndpoint = '/auth/verify-token';
  static const String generateUserIdEndpoint = '/auth/generate-user-id';
  static const String approvalRequestsEndpoint = '/api/approval-requests';
  static const String retailersEndpoint = '/api/retailers';
  static const String fcmTokenEndpoint = '/api/fcm-token';
  static const String notificationsEndpoint = '/api/notifications';
  static const String markAllNotificationsReadEndpoint = '/api/notifications/read-all';

  // Header Keys
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String contentTypeJson = 'application/json';

  // Storage Keys
  static const String keyAuthToken = 'bbs_auth_token';
  static const String keyRefreshToken = 'bbs_refresh_token';
  static const String keyUserData = 'bbs_user_data';
  static const String keyUserRole = 'bbs_user_role';
  static const String keyIsLoggedIn = 'bbs_is_logged_in';
  static const String keyRememberMe = 'bbs_remember_me';
}
