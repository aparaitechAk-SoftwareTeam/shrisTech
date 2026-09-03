// ignore_for_file: file_names

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../OwnerProfile/OwnerProfileApis.dart';
import '../OwnerProfile/OwnerProfileDetailsScreen.dart';
import '../OwnerProfile/OwnerProfileWidgets.dart';
import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';

class RetailerContactScreen extends StatefulWidget {
  const RetailerContactScreen({super.key});

  @override
  State<RetailerContactScreen> createState() => _RetailerContactScreenState();
}

class _RetailerContactScreenState extends State<RetailerContactScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOwnerProfileRepository _repository = OwnerProfileRepository();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  OwnerProfileModel? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      log('Error loading contact owner profile: $e');
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _loading = false;
      });
    }
  }

  String _errorMessage(Object error) {
    log(error.toString());
    if (error is ApiException) return error.message;
    return 'Failed to load contact information. Please try again.';
  }

  Future<void> _actionCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) {
      _showSnackBar('No phone number available');
      return;
    }

    final telUri = Uri(scheme: 'tel', path: clean);

    try {
      if (await launchUrl(telUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (await launchUrl(telUri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {}

    // Fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: phone));
    _showSnackBar('Phone number copied to clipboard: $phone');
  }

  Future<void> _actionWhatsApp(String whatsapp) async {
    final digits = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      _showSnackBar('No WhatsApp number available');
      return;
    }

    // Ensure country code prefix (e.g. 91 for India if 10-digit)
    final phoneWithCountry = digits.length == 10 ? '91$digits' : digits;

    // 1. WhatsApp Native URL scheme
    final nativeUri = Uri.parse('whatsapp://send?phone=$phoneWithCountry');
    // 2. Direct wa.me Web Link
    final webUri = Uri.parse('https://wa.me/$phoneWithCountry');
    // 3. API WhatsApp Web Link
    final apiUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$phoneWithCountry',
    );

    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (await launchUrl(apiUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (await launchUrl(webUri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {}

    // Fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: whatsapp));
    _showSnackBar('WhatsApp number copied to clipboard: $whatsapp');
  }

  Future<void> _actionEmail(String email) async {
    final clean = email.trim();
    if (clean.isEmpty) {
      _showSnackBar('No email address available');
      return;
    }

    final mailtoUri = Uri(scheme: 'mailto', path: clean);

    try {
      if (await launchUrl(mailtoUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (await launchUrl(mailtoUri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {}

    // Fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: clean));
    _showSnackBar('Email copied to clipboard: $clean');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryRoyalBlue,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _handleFooterTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.retailerCatalogue);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.offers);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.orderManagement);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.retailerCart);
        break;
    }
  }

  void _openDetails(ProfileSectionType section) {
    final profile = _profile;
    if (profile == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OwnerProfileDetailsScreen(
              section: section,
              profile: profile,
              repository: _repository,
              isReadOnly: true,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const RetailerGlobalDrawer(selectedIndex: 4),
      bottomNavigationBar: RetailerGlobalFooter(
        currentIndex: -1,
        onTap: _handleFooterTap,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
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
                    child: RefreshIndicator(
                      color: AppColors.accentGold,
                      backgroundColor: AppColors.surfaceWhite,
                      onRefresh: () => _loadProfile(forceRefresh: true),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              isCompact ? 14 : 20,
                              horizontalPadding,
                              26,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _buildBody(isCompact),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isCompact) {
    if (_loading && _profile == null) return const SkeletonLoader();
    if (_error != null && _profile == null) {
      return OwnerProfileErrorWidget(
        message: _error!,
        onRetry: () => _loadProfile(forceRefresh: true),
      );
    }
    final profile = _profile;
    if (profile == null || !profile.hasData) {
      return OwnerProfileEmptyWidget(
        onRetry: () => _loadProfile(forceRefresh: true),
      );
    }

    final phone = profile.contactDetails.phone.isNotEmpty
        ? profile.contactDetails.phone
        : profile.businessInfo.mobileNumber;
    final whatsapp = profile.contactDetails.whatsapp.isNotEmpty
        ? profile.contactDetails.whatsapp
        : phone;
    final email = profile.contactDetails.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        ProfileHeader(
          profile: profile,
          onEdit: null,
          onRefresh: () => _loadProfile(forceRefresh: true),
        ),
        if (phone.isNotEmpty || whatsapp.isNotEmpty || email.isNotEmpty) ...[
          SizedBox(height: isCompact ? 12 : 16),
          _buildQuickActionsBar(
            phone: phone,
            whatsapp: whatsapp,
            email: email,
            isCompact: isCompact,
          ),
        ],
        SizedBox(height: isCompact ? 14 : 18),
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
              subtitle: 'Support person, phone, WhatsApp and email',
              onTap: () => _openDetails(ProfileSectionType.contact),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(bool isCompact) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: AppColors.primaryRoyalBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.support_agent_rounded,
            color: AppColors.primaryRoyalBlue,
            size: isCompact ? 22 : 26,
          ),
        ),
        SizedBox(width: isCompact ? 10 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact BBS GOLD',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                fontSize: isCompact ? 18 : 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Official business, bank & contact details',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 11 : 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsBar({
    required String phone,
    required String whatsapp,
    required String email,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (phone.isNotEmpty)
            _buildQuickActionItem(
              icon: Icons.phone_in_talk_rounded,
              label: 'Call',
              color: AppColors.primaryRoyalBlue,
              isCompact: isCompact,
              onTap: () => _actionCall(phone),
            ),
          if (whatsapp.isNotEmpty) ...[
            Container(height: 28, width: 1, color: AppColors.borderLight),
            _buildQuickActionItem(
              icon: Icons.chat_bubble_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              isCompact: isCompact,
              onTap: () => _actionWhatsApp(whatsapp),
            ),
          ],
          if (email.isNotEmpty) ...[
            Container(height: 28, width: 1, color: AppColors.borderLight),
            _buildQuickActionItem(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              color: const Color(0xFFEA4335),
              isCompact: isCompact,
              onTap: () => _actionEmail(email),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isCompact ? 16 : 18),
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 12 : 13.5,
              ),
            ),
          ],
        ),
      ),
    );
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
