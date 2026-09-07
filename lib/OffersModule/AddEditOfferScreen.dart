// ignore_for_file: file_names

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../Product Module/AddProductFormWidget.dart';
import '../core/network/api_exception.dart';
import '../core/permissions/permission_manager.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import 'OfferScreenWidget.dart';
import 'OffersApis.dart';

class OfferFormResult {
  final OfferModel offer;
  final String message;
  final bool created;

  const OfferFormResult({
    required this.offer,
    required this.message,
    required this.created,
  });
}

class AddEditOfferScreen extends StatefulWidget {
  final OfferModel? offer;

  const AddEditOfferScreen({super.key, this.offer});

  bool get isEditing => offer != null;

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen>
    with SingleTickerProviderStateMixin {
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IOffersRepository _repository = OffersRepository();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String _offerType = 'Percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  _SelectedBanner? _banner;
  bool _saving = false;
  bool _submitted = false;
  int _footerIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _prefill();
    _titleController.addListener(_refreshForm);
    _noteController.addListener(_refreshForm);
    _priceController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _isFormValid && !_saving;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: 'Offers Management',
      ),
      drawer: GlobalDrawer(selectedIndex: 6, onItemSelected: (_) {}),
      bottomNavigationBar: GlobalFooter(
        currentIndex: _footerIndex,
        onTap: _handleFooterNavigation,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
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
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                isCompact ? 8 : 10,
                                horizontalPadding,
                                isCompact ? 20 : 26,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _BannerPicker(
                                    banner: _banner,
                                    submitted: _submitted,
                                    isCompact: isCompact,
                                    isTablet: isTablet,
                                    onGallery: _pickFromGallery,
                                    onCamera: _pickFromCamera,
                                    onReplace: _replaceBanner,
                                    onCrop: _canEditCurrentBanner
                                        ? _cropBanner
                                        : null,
                                    onRotate: _canEditCurrentBanner
                                        ? _rotateBanner
                                        : null,
                                    onDelete: _deleteBanner,
                                    onOpen: _openBannerViewer,
                                  ),
                                  SizedBox(height: isCompact ? 12 : 18),
                                  AddProductFormCard(
                                    padding: EdgeInsets.all(
                                      isCompact ? 12 : 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AddProductSectionHeader(
                                          icon: Icons.local_offer_rounded,
                                          title: 'Offer Details',
                                          subtitle:
                                              'Enter the announcement content exactly as retailers should see it.',
                                        ),
                                        SizedBox(height: isCompact ? 12 : 18),
                                        AddProductTextInput(
                                          controller: _titleController,
                                          label: 'Title',
                                          hint: 'Festive gold making offer',
                                          icon: Icons.title_rounded,
                                          errorText: _submitted
                                              ? _titleError
                                              : null,
                                        ),
                                        SizedBox(height: isCompact ? 10 : 14),
                                        AddProductTextInput(
                                          controller: _noteController,
                                          label: 'Note',
                                          hint:
                                              'Describe validity, terms and products.',
                                          icon: Icons.notes_rounded,
                                          maxLines: 4,
                                          textInputAction:
                                              TextInputAction.newline,
                                          errorText: _submitted
                                              ? _noteError
                                              : null,
                                        ),
                                        SizedBox(height: isCompact ? 10 : 14),
                                        AddProductDropdown<String>(
                                          label: 'Offer Type',
                                          icon: Icons.discount_rounded,
                                          value: _offerType,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Percentage',
                                              child: Text('Percentage (%)'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Flat',
                                              child: Text('Flat Amount (₹)'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _offerType = value;
                                            });
                                          },
                                          errorText: _submitted
                                              ? _offerTypeError
                                              : null,
                                        ),
                                        SizedBox(height: isCompact ? 10 : 14),
                                        AddProductTextInput(
                                          controller: _priceController,
                                          label: _isPercentage
                                              ? 'Discount Percentage'
                                              : 'Flat Discount Amount',
                                          hint: _isPercentage
                                              ? 'e.g. 10'
                                              : 'e.g. 500',
                                          icon: _isPercentage
                                              ? Icons.percent_rounded
                                              : Icons.currency_rupee_rounded,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d*'),
                                            ),
                                          ],
                                          suffixText: _isPercentage ? '% ' : null,
                                          prefixText: _isFlat ? '₹ ' : null,
                                          errorText: _submitted
                                              ? _priceError
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 12 : 18),
                                  AddProductFormCard(
                                    padding: EdgeInsets.all(
                                      isCompact ? 12 : 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const AddProductSectionHeader(
                                          icon: Icons.event_rounded,
                                          title: 'Validity',
                                          subtitle:
                                              'Date comparisons use parsed DateTime values in the device timezone.',
                                        ),
                                        SizedBox(height: isCompact ? 12 : 18),
                                        _ResponsiveTwoColumn(
                                          children: [
                                            _DateField(
                                              label: 'Start Date',
                                              date: _startDate,
                                              errorText: _submitted
                                                  ? _startDateError
                                                  : null,
                                              onTap: () =>
                                                  _pickDate(isStart: true),
                                            ),
                                            _DateField(
                                              label: 'End Date',
                                              date: _endDate,
                                              errorText: _submitted
                                                  ? _endDateError
                                                  : null,
                                              onTap: () =>
                                                  _pickDate(isStart: false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 14 : 20),
                                  _OfferPrimaryButton(
                                    label: widget.isEditing
                                        ? 'Update Offer'
                                        : 'Save Offer',
                                    isLoading: _saving,
                                    isCompact: isCompact,
                                    onPressed: canSave
                                        ? _saveOffer
                                        : _submitInvalid,
                                  ),
                                  const SizedBox(height: 10),
                                ]),
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
            if (_saving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: AddProductLoadingWidget(label: 'Saving offer'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canEditCurrentBanner => _banner != null && !_banner!.isRemote;

  bool get _isPercentage => _offerType.trim().toLowerCase() == 'percentage';
  bool get _isFlat => _offerType.trim().toLowerCase() == 'flat';

  bool get _isFormValid {
    return _titleError == null &&
        _noteError == null &&
        _bannerError == null &&
        _offerTypeError == null &&
        _priceError == null &&
        _startDateError == null &&
        _endDateError == null;
  }

  String? get _titleError {
    return _titleController.text.trim().isEmpty ? 'Title is required.' : null;
  }

  String? get _noteError {
    return _noteController.text.trim().isEmpty ? 'Note is required.' : null;
  }

  String? get _bannerError {
    return _banner == null ? 'Banner is required.' : null;
  }

  String? get _offerTypeError {
    return _offerType.trim().isEmpty ? 'Offer type is required.' : null;
  }

  String? get _priceError {
    final text = _priceController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) {
      return 'Please enter a valid number.';
    }
    if (value <= 0) {
      return _isPercentage
          ? 'Percentage must be greater than 0.'
          : 'Amount must be greater than 0.';
    }
    if (_isPercentage && value > 100) {
      return 'Percentage cannot exceed 100%.';
    }
    return null;
  }

  String? get _startDateError {
    return _startDate == null ? 'Start date is required.' : null;
  }

  String? get _endDateError {
    if (_endDate == null) return 'End date is required.';
    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
      return 'End date must be after start date.';
    }
    return null;
  }

  void _prefill() {
    final offer = widget.offer;
    if (offer == null) return;
    _titleController.text = offer.title == 'Untitled Offer' ? '' : offer.title;
    _noteController.text = offer.note == 'No description available.'
        ? ''
        : offer.note;
    _offerType = offer.offerType;
    if (offer.discount != null && offer.discount! > 0) {
      final d = offer.discount!;
      _priceController.text =
          (d % 1 == 0) ? d.toInt().toString() : d.toString();
    }
    _startDate = offer.startDate;
    _endDate = offer.endDate;
    if (offer.bannerImage.trim().isNotEmpty) {
      _banner = _SelectedBanner.remote(offer.bannerImage);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return;
      _setPickedBanner(picked.path);
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _pickFromCamera() async {
    final hasPermission = await PermissionManager.instance
        .requestCameraPermission(context: context);
    if (!hasPermission) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (picked == null) return;
      _setPickedBanner(picked.path);
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _replaceBanner() => _pickFromGallery();

  Future<void> _cropBanner() async {
    final banner = _banner;
    if (banner == null || banner.isRemote) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: banner.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Offer Banner',
            toolbarColor: AppColors.primaryRoyalBlue,
            toolbarWidgetColor: AppColors.surfaceWhite,
            activeControlsWidgetColor: AppColors.accentGold,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Offer Banner',
            rotateButtonsHidden: false,
            resetButtonHidden: false,
          ),
        ],
      );
      if (cropped == null) return;
      setState(() {
        _banner = banner.copyWith(
          path: cropped.path,
          fileName: p.basename(cropped.path),
          quarterTurns: 0,
        );
      });
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  void _rotateBanner() {
    final banner = _banner;
    if (banner == null || banner.isRemote) return;
    setState(() {
      _banner = banner.copyWith(quarterTurns: (banner.quarterTurns + 1) % 4);
    });
  }

  void _deleteBanner() {
    setState(() => _banner = null);
  }

  void _setPickedBanner(String path) {
    if (!_isAllowedImage(path)) {
      _showSnackBar('Only JPG, JPEG, PNG and WEBP images are supported.');
      return;
    }
    setState(() {
      _banner = _SelectedBanner.local(path: path, fileName: p.basename(path));
    });
  }

  bool _isAllowedImage(String path) {
    return _allowedExtensions.contains(p.extension(path).toLowerCase()) &&
        File(path).existsSync();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryRoyalBlue,
              secondary: AppColors.accentGold,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _openBannerViewer() async {
    final banner = _banner;
    if (banner == null) return;
    if (banner.isRemote) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageViewer(
            images: [banner.path],
            initialIndex: 0,
            heroPrefix: 'offer-form-banner',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LocalBannerViewer(banner: banner),
      ),
    );
  }

  Future<void> _saveOffer() async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_isFormValid) {
      _showSnackBar('Please complete the required offer details.');
      return;
    }

    setState(() => _saving = true);
    try {
      final banner = _banner!;
      final bannerImage = banner.isRemote
          ? banner.path
          : await _repository.uploadBanner(
              OfferBannerUploadItem(
                path: banner.path,
                fileName: banner.fileName,
                rotationDegrees: banner.quarterTurns * 90,
              ),
            );
      final priceValue = double.tryParse(_priceController.text.trim()) ?? 0;
      final request = OfferRequestModel(
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        bannerImage: bannerImage,
        offerType: _offerType,
        discount: priceValue,
        startDate: _startDate!,
        endDate: _endDate!,
        productIds: widget.offer?.productIds ?? const [],
      );
      log(
        'Start Date: ${_startDate.toString()}  End date: ${_endDate.toString()}',
      );
      log('Request: $request');
      final response = widget.isEditing
          ? await _repository.updateOffer(widget.offer!.apiId, request)
          : await _repository.createOffer(request);
      final fallbackOffer = OfferModel.optimistic(
        request: request,
        temporaryId:
            widget.offer?.id ??
            'offer-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        OfferFormResult(
          offer: response.offer ?? fallbackOffer,
          message: response.message,
          created: !widget.isEditing,
        ),
      );
    } catch (error) {
      log(error.toString());
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _firstValidationError {
    if (_bannerError != null) return 'Please select an offer banner.';
    if (_titleError != null) return 'Please enter an offer title.';
    if (_noteError != null) return 'Please enter offer notes/terms.';
    if (_offerTypeError != null) return 'Please select an offer type.';
    if (_priceError != null) return _priceError!;
    if (_startDateError != null) return 'Please select a start date.';
    if (_endDateError != null) return 'Please select an end date.';
    return 'Please complete the required offer details.';
  }

  void _submitInvalid() {
    setState(() => _submitted = true);
    _showSnackBar(_firstValidationError);
  }

  void _refreshForm() {
    if (mounted) setState(() {});
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
    if (index != _footerIndex) return;
    _showSnackBar('This section will be connected soon.', success: true);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is SocketException) {
      return 'Please check your internet connection.';
    }
    return 'Something went wrong.';
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? AppColors.accentGold : AppColors.surfaceWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: success
            ? AppColors.primaryRoyalBlue
            : Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _BannerPicker extends StatelessWidget {
  final _SelectedBanner? banner;
  final bool submitted;
  final bool isCompact;
  final bool isTablet;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onReplace;
  final VoidCallback? onCrop;
  final VoidCallback? onRotate;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _BannerPicker({
    required this.banner,
    required this.submitted,
    required this.isCompact,
    required this.isTablet,
    required this.onGallery,
    required this.onCamera,
    required this.onReplace,
    required this.onCrop,
    required this.onRotate,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = banner != null;
    final aspectRatio = isTablet
        ? (16 / 7)
        : (isCompact ? (16 / 11) : (16 / 10));

    return AddProductFormCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AddProductSectionHeader(
            icon: Icons.photo_library_rounded,
            title: 'Offer Banner',
            subtitle: 'Add a clear premium banner for the promotional feed.',
          ),
          SizedBox(height: isCompact ? 12 : 16),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Material(
              color: AppColors.surfaceCardSubtle,
              borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: hasBanner ? onOpen : onGallery,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
                    border: Border.all(
                      color: submitted && !hasBanner
                          ? Theme.of(context).colorScheme.error
                          : AppColors.borderLight,
                    ),
                  ),
                  child: hasBanner
                      ? banner!.isRemote
                            ? OfferImage(
                                imageUrl: banner!.path,
                                heroTag: 'offer-form-banner-0',
                              )
                            : Hero(
                                tag: 'offer-form-banner-0',
                                child: RotatedBox(
                                  quarterTurns: banner!.quarterTurns,
                                  child: Image.file(
                                    File(banner!.path),
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const OfferPlaceholder(),
                                  ),
                                ),
                              )
                      : const OfferPlaceholder(),
                ),
              ),
            ),
          ),
          if (submitted && !hasBanner) ...[
            const SizedBox(height: 8),
            Text(
              'Banner is required.',
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          SizedBox(height: isCompact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _ImageActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  isCompact: isCompact,
                  onPressed: onGallery,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 10),
              Expanded(
                child: _ImageActionButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Camera',
                  isCompact: isCompact,
                  onPressed: onCamera,
                ),
              ),
            ],
          ),
          if (hasBanner) ...[
            SizedBox(height: isCompact ? 8 : 12),
            Wrap(
              spacing: isCompact ? 6 : 8,
              runSpacing: isCompact ? 6 : 8,
              children: [
                _ToolChip(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Replace',
                  onPressed: onReplace,
                ),
                _ToolChip(
                  icon: Icons.crop_rotate_rounded,
                  label: 'Crop',
                  onPressed: onCrop,
                ),
                _ToolChip(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  label: 'Rotate',
                  onPressed: onRotate,
                ),
                _ToolChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  isDanger: true,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompact;
  final VoidCallback? onPressed;

  const _ImageActionButton({
    required this.icon,
    required this.label,
    this.isCompact = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isCompact ? 16 : 18),
      label: FittedBox(child: Text(label)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, isCompact ? 42 : 48),
        foregroundColor: AppColors.primaryRoyalBlue,
        side: const BorderSide(color: AppColors.borderGold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback? onPressed;

  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryRoyalBlue;
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(icon, color: color, size: 17),
      label: Text(label),
      labelStyle: AppTypography.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: isDanger
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
          : AppColors.primaryLightBlue,
      side: BorderSide(
        color: isDanger
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.25)
            : AppColors.borderLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? errorText;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primaryRoyalBlue,
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          filled: true,
          fillColor: AppColors.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.accentGold,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.4,
            ),
          ),
        ),
        child: Text(
          date == null ? 'Select $label' : formatOfferDate(date!),
          style: AppTypography.bodyMedium.copyWith(
            color: date == null ? AppColors.textMuted : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OfferPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isCompact;
  final VoidCallback? onPressed;

  const _OfferPrimaryButton({
    required this.label,
    required this.isLoading,
    this.isCompact = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isCompact ? 48 : 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.surfaceWhite,
                ),
              )
            : const Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          isLoading ? 'Saving Offer' : label,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryRoyalBlue,
          foregroundColor: AppColors.surfaceWhite,
          disabledBackgroundColor: AppColors.textMuted,
          disabledForegroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveTwoColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _LocalBannerViewer extends StatelessWidget {
  final _SelectedBanner banner;

  const _LocalBannerViewer({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'offer-form-banner-0',
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: RotatedBox(
                    quarterTurns: banner.quarterTurns,
                    child: Image.file(
                      File(banner.path),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const OfferPlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedBanner {
  final String path;
  final String fileName;
  final int quarterTurns;
  final bool isRemote;

  const _SelectedBanner({
    required this.path,
    required this.fileName,
    required this.quarterTurns,
    required this.isRemote,
  });

  factory _SelectedBanner.local({
    required String path,
    required String fileName,
  }) {
    return _SelectedBanner(
      path: path,
      fileName: fileName,
      quarterTurns: 0,
      isRemote: false,
    );
  }

  factory _SelectedBanner.remote(String url) {
    return _SelectedBanner(
      path: url,
      fileName: p.basename(Uri.tryParse(url)?.path ?? 'banner.jpg'),
      quarterTurns: 0,
      isRemote: true,
    );
  }

  _SelectedBanner copyWith({
    String? path,
    String? fileName,
    int? quarterTurns,
  }) {
    return _SelectedBanner(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      isRemote: isRemote,
    );
  }
}
