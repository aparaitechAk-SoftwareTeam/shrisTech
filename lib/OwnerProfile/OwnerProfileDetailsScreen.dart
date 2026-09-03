// ignore_for_file: file_names

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import 'OwnerProfileApis.dart';
import 'OwnerProfileWidgets.dart';

enum ProfileSectionType { business, bank, contact }

class OwnerProfileDetailsScreen extends StatefulWidget {
  final ProfileSectionType section;
  final OwnerProfileModel profile;
  final IOwnerProfileRepository? repository;
  final bool isReadOnly;

  const OwnerProfileDetailsScreen({
    super.key,
    required this.section,
    required this.profile,
    this.repository,
    this.isReadOnly = false,
  });

  @override
  State<OwnerProfileDetailsScreen> createState() =>
      _OwnerProfileDetailsScreenState();
}

class _OwnerProfileDetailsScreenState extends State<OwnerProfileDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _firstFocusNode = FocusNode();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};

  late OwnerProfileModel _profile;
  bool _editing = false;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _setControllersFromProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstFocusNode.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _sectionMeta(widget.section);
    return PopScope(
      canPop: !_editing || !_changed,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) Navigator.of(context).pop(_profile);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.primaryRoyalBlue,
          foregroundColor: AppColors.surfaceWhite,
          title: Text(meta.title),
          actions: [
            if (!widget.isReadOnly)
              IconButton(
                tooltip: _editing ? 'Cancel edit' : 'Edit',
                onPressed: _saving
                    ? null
                    : (_editing ? _cancelEdit : _enableEdit),
                icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isCompact = screenWidth < 360;
              final isTablet = screenWidth >= 700;
              final horizontalPadding = isTablet
                  ? 34.0
                  : (isCompact ? 12.0 : 18.0);
              final maxWidth = screenWidth >= 900
                  ? 780.0
                  : constraints.maxWidth;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isCompact ? 14 : 22,
                      horizontalPadding,
                      26,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _editing
                          ? _buildEditContent(meta, isCompact)
                          : _buildReadOnlyContent(meta, isCompact),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyContent(_SectionMeta meta, bool isCompact) {
    return Column(
      key: const ValueKey('readonly'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSurfaceCard(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: SectionHeader(
            icon: meta.icon,
            title: meta.title,
            subtitle: meta.subtitle,
            onEdit: widget.isReadOnly || _saving ? null : _enableEdit,
            isEditing: false,
            isSaving: _saving,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        ProfileSurfaceCard(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _readOnlyTiles(meta),
          ),
        ),
      ],
    );
  }

  Widget _buildEditContent(_SectionMeta meta, bool isCompact) {
    final fields = _editableFields(meta);
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('edit'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSurfaceCard(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            child: SectionHeader(
              icon: meta.icon,
              title: 'Edit ${meta.title}',
              subtitle: meta.editSubtitle,
              onEdit: _saving ? null : _cancelEdit,
              isEditing: true,
              isSaving: _saving,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          ProfileSurfaceCard(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            child: Column(
              children: [
                for (int index = 0; index < fields.length; index++) ...[
                  fields[index],
                  if (index < fields.length - 1)
                    SizedBox(height: isCompact ? 10 : 14),
                ],
              ],
            ),
          ),
          SizedBox(height: isCompact ? 14 : 18),
          _ActionButtons(saving: _saving, onSave: _save, onCancel: _cancelEdit),
        ],
      ),
    );
  }

  List<Widget> _readOnlyTiles(_SectionMeta meta) {
    switch (widget.section) {
      case ProfileSectionType.business:
        final data = _profile.businessInfo;
        return [
          InfoTile(
            icon: Icons.storefront_rounded,
            label: 'Business Name',
            value: data.businessName,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.person_rounded,
            label: 'Owner Name',
            value: data.ownerName,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.phone_rounded,
            label: 'Mobile Number',
            value: data.mobileNumber,
            trailing: data.mobileNumber.trim().isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Call',
                        onPressed: () => _actionCall(data.mobileNumber),
                        icon: const Icon(Icons.phone_in_talk_rounded),
                        color: AppColors.primaryRoyalBlue,
                        iconSize: 20,
                      ),
                      CopyButton(
                        value: data.mobileNumber,
                        onCopied: _showCopiedSnackBar,
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: data.address,
            trailing: data.address.trim().isNotEmpty
                ? CopyButton(value: data.address, onCopied: _showCopiedSnackBar)
                : null,
          ),
        ];
      case ProfileSectionType.bank:
        final data = _profile.bankDetails;
        return [
          InfoTile(
            icon: Icons.account_balance_rounded,
            label: 'Bank Name',
            value: data.bankName,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.credit_card_rounded,
            label: 'Account Number',
            value: data.accountNumber,
            trailing: CopyButton(
              value: data.accountNumber,
              onCopied: _showCopiedSnackBar,
            ),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.confirmation_number_rounded,
            label: 'IFSC',
            value: data.ifsc,
            trailing: CopyButton(
              value: data.ifsc,
              onCopied: _showCopiedSnackBar,
            ),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.location_city_rounded,
            label: 'Branch Name',
            value: data.branchName,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.payments_rounded,
            label: 'UPI ID',
            value: data.upiId,
            trailing: CopyButton(
              value: data.upiId,
              onCopied: _showCopiedSnackBar,
            ),
          ),
        ];
      case ProfileSectionType.contact:
        final data = _profile.contactDetails;
        log('Contact Details: ${data.whatsapp.toString()}');
        return [
          InfoTile(
            icon: Icons.person_rounded,
            label: 'Contact Person',
            value: data.contactPerson,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: data.phone,
            trailing: data.phone.trim().isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Call',
                        onPressed: () => _actionCall(data.phone),
                        icon: const Icon(Icons.phone_in_talk_rounded),
                        color: AppColors.primaryRoyalBlue,
                        iconSize: 20,
                      ),
                      CopyButton(
                        value: data.phone,
                        onCopied: _showCopiedSnackBar,
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            value: data.whatsapp,
            trailing: data.whatsapp.trim().isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'WhatsApp',
                        onPressed: () => _actionWhatsApp(data.whatsapp),
                        icon: const Icon(Icons.chat_bubble_rounded),
                        color: const Color(0xFF25D366),
                        iconSize: 20,
                      ),
                      CopyButton(
                        value: data.whatsapp,
                        onCopied: _showCopiedSnackBar,
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.email_rounded,
            label: 'Email',
            value: data.email,
            trailing: data.email.trim().isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Email',
                        onPressed: () => _actionEmail(data.email),
                        icon: const Icon(Icons.alternate_email_rounded),
                        color: const Color(0xFFEA4335),
                        iconSize: 20,
                      ),
                      CopyButton(
                        value: data.email,
                        onCopied: _showCopiedSnackBar,
                      ),
                    ],
                  )
                : null,
          ),
        ];
    }
  }

  List<Widget> _editableFields(_SectionMeta meta) {
    switch (widget.section) {
      case ProfileSectionType.business:
        return [
          _field('businessName', 'Business Name', Icons.storefront_rounded),
          _field('ownerName', 'Owner Name', Icons.person_rounded),
          _field(
            'mobileNumber',
            'Mobile Number',
            Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          _field(
            'address',
            'Address',
            Icons.location_on_rounded,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ];
      case ProfileSectionType.bank:
        return [
          _field('bankName', 'Bank Name', Icons.account_balance_rounded),
          _field(
            'accountNumber',
            'Account Number',
            Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _field('ifsc', 'IFSC', Icons.confirmation_number_rounded),
          _field('branchName', 'Branch Name', Icons.location_city_rounded),
          _field(
            'upiId',
            'UPI ID',
            Icons.payments_rounded,
            textInputAction: TextInputAction.done,
          ),
        ];
      case ProfileSectionType.contact:
        return [
          _field('contactPerson', 'Contact Person', Icons.person_rounded),
          _field(
            'phone',
            'Phone',
            Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          _field(
            'whatsapp',
            'WhatsApp Number',
            Icons.chat_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          _field(
            'email',
            'Email',
            Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ];
    }
  }

  Widget _field(
    String key,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return EditableField(
      controller: _controllers[key]!,
      focusNode: key == _firstFieldKey ? _firstFocusNode : null,
      label: label,
      hint: label,
      icon: icon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      errorText: _errors[key],
      onChanged: (_) {
        _changed = true;
        if (_errors[key] != null) {
          setState(() => _errors[key] = _validateField(key));
        }
      },
    );
  }

  Future<void> _save() async {
    final errors = _validateSection();
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((error) => error != null)) return;
    if (_saving) return;

    final repo = widget.repository;
    if (repo == null) {
      setState(() => _saving = false);
      return;
    }

    try {
      if (widget.section == ProfileSectionType.contact) {
        await repo.updateContactInformation(_payload());
      } else {
        await repo.updateProfile(_payload());
      }
      final refreshed = await repo.refreshProfile();
      if (!mounted) return;
      setState(() {
        _profile = refreshed;
        _editing = false;
        _changed = false;
      });
      _setControllersFromProfile();
      _showSnackBar('Profile Updated Successfully.', success: true);
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _enableEdit() {
    setState(() {
      _editing = true;
      _changed = false;
      _errors.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _firstFocusNode.requestFocus();
      final focusContext = _firstFocusNode.context;
      if (focusContext == null) return;
      Scrollable.ensureVisible(
        focusContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _cancelEdit() async {
    if (_changed) {
      final discard = await _confirmDiscard();
      if (!discard) return;
    }
    if (!mounted) return;
    setState(() {
      _editing = false;
      _changed = false;
      _errors.clear();
    });
    _setControllersFromProfile();
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Your unsaved profile edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _setControllersFromProfile() {
    final values = _currentValues();
    for (final entry in values.entries) {
      _controllers.putIfAbsent(entry.key, TextEditingController.new).text =
          entry.value;
    }
  }

  Map<String, String> _currentValues() {
    switch (widget.section) {
      case ProfileSectionType.business:
        final data = _profile.businessInfo;
        return {
          'businessName': data.businessName,
          'ownerName': data.ownerName,
          'mobileNumber': data.mobileNumber,
          'address': data.address,
        };
      case ProfileSectionType.bank:
        final data = _profile.bankDetails;
        return {
          'bankName': data.bankName,
          'accountNumber': data.accountNumber,
          'ifsc': data.ifsc,
          'branchName': data.branchName,
          'upiId': data.upiId,
        };
      case ProfileSectionType.contact:
        final data = _profile.contactDetails;
        return {
          'contactPerson': data.contactPerson,
          'phone': data.phone,
          'whatsapp': data.whatsapp,
          'email': data.email,
        };
    }
  }

  Map<String, dynamic> _payload() {
    switch (widget.section) {
      case ProfileSectionType.business:
        return {
          'business_info': _profile.businessInfo
              .copyWith(
                businessName: _text('businessName'),
                ownerName: _text('ownerName'),
                mobileNumber: _text('mobileNumber'),
                address: _text('address'),
              )
              .toJson(),
          'bank_details': _profile.bankDetails.toJson(),
        };
      case ProfileSectionType.bank:
        return {
          'business_info': _profile.businessInfo.toJson(),
          'bank_details': _profile.bankDetails
              .copyWith(
                bankName: _text('bankName'),
                accountNumber: _text('accountNumber'),
                ifsc: _text('ifsc'),
                branchName: _text('branchName'),
                upiId: _text('upiId'),
              )
              .toJson(),
        };
      case ProfileSectionType.contact:
        // Sends exactly what PUT /api/contact-information expects:
        // { owner_id, contact_person, phone, whatsapp, email }
        return ContactDetailsModel(
          contactPerson: _text('contactPerson'),
          phone: _text('phone'),
          whatsapp: _text('whatsapp'),
          email: _text('email'),
        ).toJson();
    }
  }

  Map<String, String?> _validateSection() {
    return {for (final key in _currentValues().keys) key: _validateField(key)};
  }

  String? _validateField(String key) {
    final value = _text(key);
    switch (key) {
      case 'businessName':
        return value.isEmpty ? 'Business Name is required.' : null;
      case 'ownerName':
        return value.isEmpty ? 'Owner Name is required.' : null;
      case 'address':
        return value.isEmpty ? 'Address is required.' : null;
      case 'mobileNumber':
        if (value.isEmpty) return 'Mobile Number is required.';
        return _isTenDigitMobile(value)
            ? null
            : 'Enter a valid 10 digit mobile number.';
      case 'bankName':
        return value.isEmpty ? 'Bank Name is required.' : null;
      case 'accountNumber':
        return value.isEmpty ? 'Account Number is required.' : null;
      case 'ifsc':
        if (value.isEmpty) return 'IFSC is required.';
        return _isValidIfsc(value) ? null : 'Enter a valid IFSC.';
      case 'upiId':
        if (value.isEmpty) return null;
        return _isValidUpi(value) ? null : 'Enter a valid UPI ID.';
      case 'contactPerson':
        return value.isEmpty ? 'Contact Person is required.' : null;
      case 'phone':
        if (value.isEmpty) return 'Phone number is required.';
        return _isTenDigitMobile(value)
            ? null
            : 'Enter a valid 10 digit phone number.';
      case 'whatsapp':
        if (value.isEmpty) return null;
        return _isTenDigitMobile(value)
            ? null
            : 'Enter a valid 10 digit WhatsApp number.';
      case 'email':
        if (value.isEmpty) return null;
        return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)
            ? null
            : 'Enter a valid email address.';
      default:
        return null;
    }
  }

  String _text(String key) => _controllers[key]?.text.trim() ?? '';

  String get _firstFieldKey {
    switch (widget.section) {
      case ProfileSectionType.business:
        return 'businessName';
      case ProfileSectionType.bank:
        return 'bankName';
      case ProfileSectionType.contact:
        return 'contactPerson';
    }
  }

  void _showCopiedSnackBar() {
    _showSnackBar('Copied Successfully', success: true);
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
      ),
    );
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
    _showSnackBar('Phone number copied to clipboard: $phone', success: true);
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
    _showSnackBar(
      'WhatsApp number copied to clipboard: $whatsapp',
      success: true,
    );
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
    _showSnackBar('Email copied to clipboard: $clean', success: true);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}

class _ActionButtons extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ActionButtons({
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerProfilePrimaryButton(
                label: 'Save',
                icon: Icons.check_circle_rounded,
                isLoading: saving,
                onPressed: onSave,
              ),
              const SizedBox(height: 10),
              OwnerProfileSecondaryButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onPressed: saving ? null : onCancel,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: OwnerProfileSecondaryButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onPressed: saving ? null : onCancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OwnerProfilePrimaryButton(
                label: 'Save',
                icon: Icons.check_circle_rounded,
                isLoading: saving,
                onPressed: onSave,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionMeta {
  final String title;
  final String subtitle;
  final String editSubtitle;
  final IconData icon;

  const _SectionMeta({
    required this.title,
    required this.subtitle,
    required this.editSubtitle,
    required this.icon,
  });
}

_SectionMeta _sectionMeta(ProfileSectionType section) {
  switch (section) {
    case ProfileSectionType.business:
      return const _SectionMeta(
        title: 'Business Information',
        subtitle: 'Verified business identity used across the owner account.',
        editSubtitle: 'Update only business profile information.',
        icon: Icons.business_center_rounded,
      );
    case ProfileSectionType.bank:
      return const _SectionMeta(
        title: 'Bank Details',
        subtitle: 'Settlement account information for business operations.',
        editSubtitle: 'Account number is visible while editing.',
        icon: Icons.account_balance_rounded,
      );
    case ProfileSectionType.contact:
      return const _SectionMeta(
        title: 'Contact Details',
        subtitle: 'Support contact information for business communication.',
        editSubtitle: 'Update only owner contact details.',
        icon: Icons.support_agent_rounded,
      );
  }
}

bool _isTenDigitMobile(String value) => RegExp(r'^[0-9]{10}$').hasMatch(value);

bool _isValidIfsc(String value) {
  return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.trim().toUpperCase());
}

bool _isValidUpi(String value) {
  return RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(value);
}
