import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validation_helper.dart';
import '../../core/widgets/card_container.dart';
import '../../core/widgets/concentric_pattern_painter.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/password_checklist_widget.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/success_dialog.dart';
import '../../services/auth_service.dart';

/// Ultra-Luxury Retailer Registration Screen for BBS GOLD.
/// Features synchronized background pattern graphics, real-time multi-field validation,
/// strict input formatting, live SaaS password checklist & strength meter,
/// animated rounded corners, disabled button logic,
/// button loading animation, and luxury success dialog modal.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _shopNameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  // Real-time field error messages
  String? _nameError;
  String? _mobileError;
  String? _emailError;
  String? _shopNameError;
  String? _addressError;
  String? _passwordError;

  // Real-time button enablement flag
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _nameController.addListener(_validateInputs);
    _mobileController.addListener(_validateInputs);
    _emailController.addListener(_validateInputs);
    _shopNameController.addListener(_validateInputs);
    _addressController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();

    _nameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _shopNameFocusNode.dispose();
    _addressFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Evaluates all inputs in real-time to determine field error messages and form validity
  void _validateInputs() {
    final name = _nameController.text;
    final mobile = _mobileController.text;
    final email = _emailController.text;
    final shopName = _shopNameController.text;
    final address = _addressController.text;
    final password = _passwordController.text;

    final nameErr = ValidationHelper.validateName(name);
    final mobileErr = ValidationHelper.validateMobile(mobile);
    final emailErr = ValidationHelper.validateEmail(email);
    final shopErr = ValidationHelper.validateShopName(shopName);
    final addressErr = ValidationHelper.validateAddress(address);
    final passErr = ValidationHelper.validateRegistrationPassword(password);

    setState(() {
      _nameError = name.isNotEmpty ? nameErr : null;
      _mobileError = mobile.isNotEmpty ? mobileErr : null;
      _emailError = email.isNotEmpty ? emailErr : null;
      _shopNameError = shopName.isNotEmpty ? shopErr : null;
      _addressError = address.isNotEmpty ? addressErr : null;
      _passwordError = password.isNotEmpty ? passErr : null;

      _isFormValid =
          name.isNotEmpty &&
          mobile.isNotEmpty &&
          email.isNotEmpty &&
          shopName.isNotEmpty &&
          address.isNotEmpty &&
          password.isNotEmpty &&
          nameErr == null &&
          mobileErr == null &&
          emailErr == null &&
          shopErr == null &&
          addressErr == null &&
          passErr == null;
    });
  }

  void _onSendRequestPressed() async {
    if (!_isFormValid || _isLoading) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService().registerRetailer(
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        shopName: _shopNameController.text,
        address: _addressController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        final message = response.message.trim().isEmpty
            ? AppConstants.verificationDialogMessage
            : response.message;

        SuccessDialog.show(
          context: context,
          message: message,
          onOkPressed: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        _showErrorSnackBar(
          response.message.trim().isEmpty
              ? 'Something went wrong.7'
              : response.message,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Something went wrong.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryRoyalBlue,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Retailer Registration',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primaryRoyalBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Synchronized Background Concentric Graphics
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConcentricPatternPainter(
                    progress: _animController.value,
                  ),
                );
              },
            ),
          ),

          // Main Form Content
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 16.0,
                      vertical: 12.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 560 : double.infinity,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Section
                                const SectionTitle(
                                  title: AppConstants.registerTitle,
                                  subtitle: AppConstants.registerSubtitle,
                                ),
                                const SizedBox(height: 20),

                                // Registration Form Container Card
                                CardContainer(
                                  borderRadius: 24.0,
                                  showGoldGlowBorder: _isFormValid,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1. Full Name
                                      CustomTextField(
                                        label: AppConstants.fullNameLabel,
                                        hintText: AppConstants.fullNameHint,
                                        controller: _nameController,
                                        focusNode: _nameFocusNode,
                                        prefixIcon: Icons.badge_outlined,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        errorText: _nameError,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z\s]'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),

                                      // 2. Mobile Number
                                      CustomTextField(
                                        label: AppConstants.mobileLabel,
                                        hintText: AppConstants.mobileHint,
                                        controller: _mobileController,
                                        focusNode: _mobileFocusNode,
                                        prefixIcon:
                                            Icons.phone_android_outlined,
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.next,
                                        errorText: _mobileError,
                                        maxLength: 10,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                      const SizedBox(height: 18),

                                      // 3. Email
                                      CustomTextField(
                                        label: AppConstants.emailLabel,
                                        hintText: AppConstants.emailHint,
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        errorText: _emailError,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                            RegExp(r'\s'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),

                                      // 4. Shop Name
                                      CustomTextField(
                                        label: AppConstants.shopNameLabel,
                                        hintText: AppConstants.shopNameHint,
                                        controller: _shopNameController,
                                        focusNode: _shopNameFocusNode,
                                        prefixIcon: Icons.storefront_outlined,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        errorText: _shopNameError,
                                      ),
                                      const SizedBox(height: 18),

                                      // 5. Address
                                      CustomTextField(
                                        label: AppConstants.addressLabel,
                                        hintText: AppConstants.addressHint,
                                        controller: _addressController,
                                        focusNode: _addressFocusNode,
                                        prefixIcon: Icons.location_on_outlined,
                                        maxLines: 3,
                                        maxLength: 200,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        textInputAction: TextInputAction.next,
                                        errorText: _addressError,
                                      ),
                                      const SizedBox(height: 18),

                                      // 6. Password
                                      CustomTextField(
                                        label: AppConstants.regPasswordLabel,
                                        hintText: AppConstants.regPasswordHint,
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        prefixIcon: Icons.lock_outline_rounded,
                                        isObscured: _isPasswordObscured,
                                        textInputAction: TextInputAction.done,
                                        errorText: _passwordError,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordObscured
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.textMuted,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordObscured =
                                                  !_isPasswordObscured;
                                            });
                                          },
                                        ),
                                      ),

                                      // Live SaaS Password Criteria Checklist & Strength Meter
                                      PasswordChecklistWidget(
                                        password: _passwordController.text,
                                      ),

                                      const SizedBox(height: 28),

                                      // Send Registration Request CTA Button
                                      PrimaryButton(
                                        text: AppConstants.sendRequestButton,
                                        isEnabled: _isFormValid,
                                        isLoading: _isLoading,
                                        onPressed: _onSendRequestPressed,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
