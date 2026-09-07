import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'GlobalCode/DrawerScreens.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/home/owner_home_screen.dart';
import 'screens/home/retailer_home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'HomeScreen/HomeScreen.dart';
import 'ApprovalRequest/approval_request_screen.dart';
import 'OwnerProfile/OwnerProfileScreen.dart';
import 'OffersModule/OfferListScreen.dart';
import 'Order Management Module/OrderListScreen.dart';
import 'Order Management Module/RetailerOrderListScreen.dart';
import 'RetailerCart/CartListScreen.dart';
import 'RetailerCatalogue/RetailerProductNameListScreen.dart';
import 'RetailerWishlist/WishListScreen.dart';
import 'core/userdata.dart';
import 'RetailerContact/RetailerContactScreen.dart';
import 'NotificationModule/NotificationScreen.dart';
import 'RetailerProfile/RetailerProfileScreen.dart';
import 'OwnerOrderHistory/OwnerOrderHistoryScreen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAyr11RAmmgEsTkb49pZJQhxeWPN7niFoY',
        appId: '1:135465818327:web:30dd94ef2b70796970f892',
        messagingSenderId: '135465818327',
        projectId: 'bbs-gold',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAyr11RAmmgEsTkb49pZJQhxeWPN7niFoY',
        appId: '1:135465818327:web:30dd94ef2b70796970f892',
        messagingSenderId: '135465818327',
        projectId: 'bbs-gold',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const BbsGoldApp());
}

class BbsGoldApp extends StatelessWidget {
  const BbsGoldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBS GOLD',
      navigatorKey: AppRoutes.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegistrationScreen(),
        AppRoutes.ownerHome: (context) => _roleSafeOwnerHome(),
        AppRoutes.retailerHome: (context) => _roleSafeRetailerHome(),
        AppRoutes.retailerCatalogue: (context) =>
            _retailerOnly(const RetailerProductNameListScreen()),
        AppRoutes.retailerWishlist: (context) =>
            _retailerOnly(const WishListScreen()),
        AppRoutes.retailerCart: (context) =>
            _retailerOnly(const CartListScreen()),

        // Drawer Screens
        AppRoutes.approvalRequests: (context) =>
            _ownerOnly(const ApprovalRequestScreen()),
        AppRoutes.addProduct: (context) => _ownerOnly(const AddProductScreen()),
        AppRoutes.stockListing: (context) =>
            _ownerOnly(const StockListingScreen()),
        AppRoutes.retailers: (context) => _ownerOnly(const RetailersScreen()),
        AppRoutes.orderManagement: (context) =>
            UserData.instance.role.trim().toLowerCase() == 'owner'
            ? const OrderListScreen()
            : const RetailerOrderListScreen(),
        AppRoutes.offers: (context) => const OfferListScreen(),
        AppRoutes.profile: (context) =>
            UserData.instance.role.trim().toLowerCase() == 'owner'
            ? const OwnerProfileScreen()
            : const RetailerProfileScreen(),
        AppRoutes.retailerContact: (context) =>
            _retailerOnly(const RetailerContactScreen()),
        AppRoutes.notifications: (context) => const NotificationScreen(),
        AppRoutes.orderHistory: (context) =>
            _ownerOnly(const OwnerOrderHistoryScreen()),
      },
    );
  }

  Widget _roleSafeOwnerHome() {
    return _isOwner ? const OwnerHomeScreen() : const RetailerHomeScreen();
  }

  Widget _roleSafeRetailerHome() {
    return _isOwner ? const OwnerHomeScreen() : const RetailerHomeScreen();
  }

  Widget _ownerOnly(Widget ownerScreen) {
    return _isOwner ? ownerScreen : const RetailerHomeScreen();
  }

  Widget _retailerOnly(Widget retailerScreen) {
    return _isOwner ? const OwnerHomeScreen() : retailerScreen;
  }

  bool get _isOwner => UserData.instance.role.trim().toLowerCase() == 'owner';
}
