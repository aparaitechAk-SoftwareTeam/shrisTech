// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../RetailerGlobalCode/RetailerGlobalAppbar.dart';
import '../RetailerGlobalCode/RetailerGlobalDrawer.dart';
import '../RetailerGlobalCode/RetailerGlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/userdata.dart';
import '../navigation/app_routes.dart';
import 'RetailerProfileApis.dart';
import 'RetailerProfileWidgets.dart';

/// Retailer Profile Screen for BBS GOLD B2B Wholesale Platform.
/// Provides viewing, editing, updating session & preferences, validation,
/// shimmer loading, error states, and responsive luxury UI.
class RetailerProfileScreen extends StatefulWidget {
  final IRetailerProfileRepository? repository;

  const RetailerProfileScreen({super.key, this.repository});

  @override
  State<RetailerProfileScreen> createState() => _RetailerProfileScreenState();
}

class _RetailerProfileScreenState extends State<RetailerProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final IRetailerProfileRepository _repository;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isEditing = false;
  int _footerIndex = 0;
  String? _error;
  RetailerProfileModel? _profile;

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s]+$");
  static final RegExp _emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  static final RegExp _mobileRegex = RegExp(r"^\d{10}$");

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? sharedRetailerProfileRepository;

    final user = UserData.instance;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _mobileController = TextEditingController(text: user.mobileNumber);

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _repository.fetchProfile(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _mobileController.text = profile.mobileNumber;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final fallbackProfile = RetailerProfileModel.fromSession();
      setState(() {
        _profile = fallbackProfile;
        _nameController.text = fallbackProfile.name;
        _emailController.text = fallbackProfile.email;
        _mobileController.text = fallbackProfile.mobileNumber;
        _error = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() {
    if (_isSubmitting) return;

    if (_isEditing) {
      // Cancel edit mode -> restore values from current profile state
      final p = _profile ?? RetailerProfileModel.fromSession();
      _nameController.text = p.name;
      _emailController.text = p.email;
      _mobileController.text = p.mobileNumber;
      _formKey.currentState?.reset();
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_isSubmitting || !_isEditing) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showSnackBar('Please fix the errors highlighted in the form.');
      return;
    }

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newMobile = _mobileController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedProfile = await _repository.updateProfile(
        name: newName,
        email: newEmail,
        mobileNo: newMobile,
      );

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
        _nameController.text = updatedProfile.name;
        _emailController.text = updatedProfile.email;
        _mobileController.text = updatedProfile.mobileNumber;
        _isEditing = false;
        _isSubmitting = false;
      });

      _showSnackBar('Profile updated successfully.', success: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(_errorMessage(error));
    }
  }

  void _handleFooterNavigation(int index) {
    if (index == _footerIndex) return;

    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.retailerHome, (route) => false);
        break;
      case 1:
        Navigator.of(context).pushNamed(AppRoutes.retailerCatalogue);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.offers);
        break;
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.orderManagement);
        break;
      case 4:
        Navigator.of(context).pushNamed(AppRoutes.retailerCart);
        break;
      default:
        setState(() => _footerIndex = index);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: success ? AppColors.accentGold : AppColors.surfaceWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Connection failed. Please check your network and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? RetailerProfileModel.fromSession();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceWhite,
      appBar: RetailerGlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RetailerGlobalDrawer(selectedIndex: 6, onItemSelected: (_) {}),
      bottomNavigationBar: RetailerGlobalFooter(
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
              final isTablet = screenWidth >= 650;
              final horizontalPadding = isTablet
                  ? 28.0
                  : (isCompact ? 12.0 : 16.0);
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
                          isCompact ? 14 : 20,
                          horizontalPadding,
                          isCompact ? 20 : 28,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildBodyContent(profile, isCompact),
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

  Widget _buildBodyContent(RetailerProfileModel profile, bool isCompact) {
    if (_isLoading) {
      return ShimmerProfileCard(isCompact: isCompact);
    }

    if (_error != null && _profile == null) {
      return ErrorState(
        message: _error!,
        isCompact: isCompact,
        onRetry: () => _loadProfile(forceRefresh: true),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          ProfileHeaderCard(
            profile: profile,
            isEditing: _isEditing,
            isCompact: isCompact,
            onEditToggle: _toggleEditMode,
          ),
          SizedBox(height: isCompact ? 16 : 22),

          // Section Title
          SectionHeader(
            title: 'Profile Information',
            subtitle: 'Manage your verified business contact details.',
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 10 : 14),

          // Information Card Container
          ProfileInfoCard(
            isCompact: isCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable: Name
                EditableTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  enabled: _isEditing && !_isSubmitting,
                  isCompact: isCompact,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Name is required.';
                    if (text.length < 3) {
                      return 'Name must be at least 3 characters.';
                    }
                    if (!_nameRegex.hasMatch(text)) {
                      return 'Name can only contain letters and spaces.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isCompact ? 12 : 16),

                // Editable: Email
                EditableTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _isEditing && !_isSubmitting,
                  isCompact: isCompact,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Email address is required.';
                    if (!_emailRegex.hasMatch(text)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isCompact ? 12 : 16),

                // Editable: Mobile Number
                EditableTextField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  enabled: _isEditing && !_isSubmitting,
                  isCompact: isCompact,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Mobile number is required.';
                    if (!_mobileRegex.hasMatch(text)) {
                      return 'Mobile number must be exactly 10 digits.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isCompact ? 16 : 20),

                // Divider
                Container(
                  height: 1,
                  color: AppColors.borderLight.withValues(alpha: 0.6),
                ),
                SizedBox(height: isCompact ? 16 : 20),

                // Read-Only Section Header
                Text(
                  'Account Details (Read Only)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11.5 : 12.5,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 14),

                // Read-Only: User ID
                ReadOnlyTextField(
                  label: 'User ID',
                  value: profile.userId.isNotEmpty
                      ? profile.userId
                      : profile.id,
                  icon: Icons.badge_outlined,
                  isCompact: isCompact,
                ),
                SizedBox(height: isCompact ? 12 : 14),

                // Read-Only: Username
                ReadOnlyTextField(
                  label: 'Username',
                  value: profile.username.isNotEmpty
                      ? profile.username
                      : profile.email,
                  icon: Icons.alternate_email_rounded,
                  isCompact: isCompact,
                ),
                SizedBox(height: isCompact ? 12 : 14),

                // Read-Only: Role
                ReadOnlyTextField(
                  label: 'Role',
                  value: profile.role,
                  icon: Icons.admin_panel_settings_outlined,
                  isCompact: isCompact,
                ),
                SizedBox(height: isCompact ? 12 : 14),

                // Read-Only: Account Status
                ReadOnlyTextField(
                  label: 'Account Status',
                  value: profile.accountStatus,
                  icon: Icons.verified_user_outlined,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 16 : 22),

          // Action Buttons (Visible only in Edit Mode)
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: CancelButton(
                    onPressed: _toggleEditMode,
                    enabled: !_isSubmitting,
                    isCompact: isCompact,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
                Expanded(
                  child: SaveButton(
                    onPressed: _saveProfile,
                    isLoading: _isSubmitting,
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 20 : 28),
          ],
        ],
      ),
    );
  }
}
