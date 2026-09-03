// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import '../screens/auth/forgot_password_screen.dart';
import 'OwnerProfileApis.dart';
import 'OwnerProfileDetailsScreen.dart';
import 'OwnerProfileWidgets.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen>
    with SingleTickerProviderStateMixin {
  final IOwnerProfileRepository _repository = OwnerProfileRepository();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  OwnerProfileModel? _profile;
  String? _error;
  bool _loading = true;
  int _footerIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Owner Profile',
      ),
      drawer: GlobalDrawer(selectedIndex: 7, onItemSelected: (_) {}),
      bottomNavigationBar: GlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRoyalBlue,
          onRefresh: () => _loadProfile(forceRefresh: true),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isCompact = screenWidth < 360;
              final isTablet = screenWidth >= 700;
              final horizontalPadding = isTablet
                  ? 34.0
                  : (isCompact ? 12.0 : 18.0);
              final maxWidth = screenWidth >= 1100
                  ? 760.0
                  : (screenWidth >= 700 ? 680.0 : screenWidth);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 14 : 22,
                          horizontalPadding,
                          26,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _fade,
                            child: _buildBody(isCompact),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isCompact) {
    if (_loading && _profile == null) return const SkeletonLoader();
    if (_error != null && _profile == null) {
      return OwnerProfileErrorWidget(message: _error!, onRetry: _loadProfile);
    }
    final profile = _profile;
    if (profile == null || !profile.hasData) {
      return OwnerProfileEmptyWidget(onRetry: _loadProfile);
    }
    return Column(
      children: [
        ProfileHeader(
          profile: profile,
          onEdit: () => _openDetails(ProfileSectionType.business),
          onRefresh: () => _loadProfile(forceRefresh: true),
        ),
        SizedBox(height: isCompact ? 12 : 18),
        _ResponsiveGrid(
          isCompact: isCompact,
          children: [
            ProfileCard(
              icon: Icons.business_center_rounded,
              title: 'Business Information',
              subtitle: 'Business name, owner name, mobile and address',
              onTap: () => _openDetails(ProfileSectionType.business),
            ),
            ProfileCard(
              icon: Icons.account_balance_rounded,
              title: 'Bank Details',
              subtitle: 'Settlement account, IFSC, branch and UPI',
              onTap: () => _openDetails(ProfileSectionType.bank),
            ),
            ProfileCard(
              icon: Icons.support_agent_rounded,
              title: 'Contact Details',
              subtitle: 'Support person and contact numbers',
              onTap: () => _openDetails(ProfileSectionType.contact),
            ),
            ProfileCard(
              icon: Icons.lock_reset_rounded,
              title: 'Reset Password',
              subtitle: 'Password update screen is ready for API wiring',
              onTap: _openResetPassword,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    if (_loading && _profile != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.fetchProfile(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetails(ProfileSectionType section) async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.of(context).push<OwnerProfileModel>(
      PageRouteBuilder<OwnerProfileModel>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OwnerProfileDetailsScreen(
              section: section,
              profile: profile,
              repository: _repository,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  void _openResetPassword() async {
    final prefillUser = UserData.instance.userId.isNotEmpty
        ? UserData.instance.userId
        : UserData.instance.email;

    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ForgotPasswordScreen(initialUser: prefillUser),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password has been reset successfully.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          backgroundColor: AppColors.primaryRoyalBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.stockListing);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.addProduct);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.orderManagement);
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushNamed(AppRoutes.orderHistory);
      return;
    }
    setState(() => _footerIndex = index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This section will be connected soon.'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: AppColors.primaryRoyalBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final bool isCompact;

  const _ResponsiveGrid({required this.children, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (int index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  SizedBox(height: isCompact ? 10 : 12),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth >= 900 ? 3.4 : 3.0,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
