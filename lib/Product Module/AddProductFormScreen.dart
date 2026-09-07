// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../GlobalCode/GlobalAppbar.dart';
import '../GlobalCode/GlobalDrawer.dart';
import '../GlobalCode/GlobalFooter.dart';
import '../core/network/api_exception.dart';
import '../core/permissions/permission_manager.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../navigation/app_routes.dart';
import '../Stock Listing Module/StockApis.dart' as stock;
import 'AddProductFormApis.dart';
import 'AddProductFormWidget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key})
    : initialProductData = null,
      onProductUpdated = null;

  const AddProductScreen.edit({
    super.key,
    required this.initialProductData,
    this.onProductUpdated,
  });

  static const String routeName = '/add_product';

  final stock.ProductModel? initialProductData;
  final ValueChanged<stock.ProductModel>? onProductUpdated;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxImageCount = 8;
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IAddProductRepository _repository = AddProductRepository();
  final stock.IStockRepository _stockRepository =
      stock.StockRepository.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _grossWeightController = TextEditingController();
  final TextEditingController _stoneWeightController = TextEditingController(
    text: '0',
  );
  final TextEditingController _stoneChargeController = TextEditingController(
    text: '0',
  );
  final TextEditingController _netWeightController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  List<SelectedProductImage> _images = const [];
  int _selectedImageIndex = 0;
  int _footerIndex = 2;
  bool _submitted = false;
  bool _saving = false;
  List<String> _productNameOptions = const [];
  bool _loadingProductNames = false;

  bool get _isEditMode => widget.initialProductData != null;

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
    _prefillEditProduct();
    _productNameController.addListener(_refreshForm);
    _grossWeightController.addListener(_updateNetWeight);
    _stoneWeightController.addListener(_updateNetWeight);
    _stoneChargeController.addListener(_refreshForm);
    _updateNetWeight();
    _fetchProductNameOptions();
  }

  Future<void> _fetchProductNameOptions() async {
    if (_isEditMode) return;
    setState(() => _loadingProductNames = true);
    try {
      final products = await _stockRepository.fetchProducts(forceRefresh: true);
      final names = <String>{};
      for (final p in products) {
        final name = p.productName.trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }
      final sorted = names.toList()..sort((a, b) => a.compareTo(b));
      if (!mounted) return;
      setState(() {
        _productNameOptions = sorted;
        _loadingProductNames = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProductNames = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _productNameController.dispose();
    _grossWeightController.dispose();
    _stoneWeightController.dispose();
    _stoneChargeController.dispose();
    _netWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = (_isEditMode ? _isEditFormValid : _isFormValid) && !_saving;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: GlobalAppbar(
        onLogoTap: () => _scaffoldKey.currentState?.openDrawer(),
        subtitle: _isEditMode ? 'Edit Product' : 'Add Product',
      ),
      drawer: GlobalDrawer(selectedIndex: 2, onItemSelected: (_) {}),
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
                                isCompact ? 16 : 22,
                                horizontalPadding,
                                26,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  if (!_isEditMode)
                                    AddProductImagePicker(
                                      images: _images,
                                      selectedIndex: _selectedImageIndex,
                                      maxImageCount: _maxImageCount,
                                      onSelect: (index) {
                                        setState(
                                          () => _selectedImageIndex = index,
                                        );
                                      },
                                      onOpenViewer: _openImageViewer,
                                      onAddFromGallery: _pickFromGallery,
                                      onAddFromCamera: _pickFromCamera,
                                      onReplace: _images.isEmpty
                                          ? null
                                          : _replaceImage,
                                      onDelete: _images.isEmpty
                                          ? null
                                          : _deleteImage,
                                      onCrop: _images.isEmpty
                                          ? null
                                          : _cropImage,
                                      onRotate: _images.isEmpty
                                          ? null
                                          : _rotateImage,
                                      onReorder: _reorderImages,
                                    ),
                                  if (!_isEditMode &&
                                      _submitted &&
                                      _images.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    const _InlineError(
                                      message:
                                          'Please add at least one product image.',
                                    ),
                                  ],
                                  SizedBox(height: isCompact ? 14 : 18),
                                  AddProductFormCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AddProductSectionHeader(
                                          icon: Icons.diamond_rounded,
                                          title: 'Product Details',
                                          subtitle: _isEditMode
                                              ? 'Review fixed catalogue details. Only weights are updated from this screen.'
                                              : 'Enter only the details needed to create this catalogue product.',
                                        ),
                                        SizedBox(height: isCompact ? 14 : 18),
                                        AddProductProductNameDropdown(
                                          controller: _productNameController,
                                          label: 'Product Name',
                                          hint: 'Select or type product name',
                                          icon: Icons.workspace_premium_rounded,
                                          readOnly: _isEditMode,
                                          options: _productNameOptions,
                                          loadingOptions: _loadingProductNames,
                                          errorText: _submitted
                                              ? _productNameError
                                              : null,
                                          onChanged: (_) => _refreshForm(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 14 : 18),
                                  AddProductFormCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AddProductSectionHeader(
                                          icon: Icons.scale_rounded,
                                          title: 'Weight & Charges',
                                          subtitle: _isEditMode
                                              ? 'Update weights and stone charge. Net weight is recalculated by the backend.'
                                              : 'Net weight updates instantly from gross and stone weight.',
                                        ),
                                        SizedBox(height: isCompact ? 14 : 18),
                                        _ResponsiveTwoColumn(
                                          children: [
                                            AddProductWeightInput(
                                              controller:
                                                  _grossWeightController,
                                              label: 'Gross Weight',
                                              hint: '25.50',
                                              errorText: _submitted
                                                  ? _grossWeightError
                                                  : null,
                                            ),
                                            AddProductWeightInput(
                                              controller:
                                                  _stoneWeightController,
                                              label: 'Stone Weight',
                                              hint: '0',
                                              errorText: _submitted
                                                  ? _stoneWeightError
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isCompact ? 10 : 14),
                                        _ResponsiveTwoColumn(
                                          children: [
                                            AddProductTextInput(
                                              controller:
                                                  _stoneChargeController,
                                              label: 'Stone Charge',
                                              hint: '0',
                                              icon:
                                                  Icons.currency_rupee_rounded,
                                              readOnly: false,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              errorText: _submitted
                                                  ? _stoneChargeError
                                                  : null,
                                            ),
                                            AddProductWeightInput(
                                              controller: _netWeightController,
                                              label: 'Net Weight',
                                              hint: 'Auto calculated',
                                              readOnly: true,
                                              errorText: _submitted
                                                  ? _netWeightError
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 16 : 20),
                                  AddProductPrimaryButton(
                                    label: _isEditMode
                                        ? 'Update Product'
                                        : 'Save Product',
                                    icon: Icons.check_circle_rounded,
                                    isLoading: _saving,
                                    onPressed: canSave
                                        ? _saveProduct
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
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x33000000),
                  child: AddProductLoadingWidget(
                    label: _isEditMode
                        ? 'Updating product'
                        : 'Creating product',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _isFormValid {
    return _images.isNotEmpty &&
        _productNameError == null &&
        _grossWeightError == null &&
        _stoneWeightError == null &&
        _stoneChargeError == null &&
        _netWeightError == null;
  }

  bool get _isEditFormValid {
    return widget.initialProductData?.id.trim().isNotEmpty == true &&
        _grossWeightError == null &&
        _stoneWeightError == null &&
        _netWeightError == null;
  }

  double get _grossWeight => _parseDecimal(_grossWeightController.text);
  double get _stoneWeight => _parseDecimal(_stoneWeightController.text);
  double get _stoneCharge => _parseDecimal(_stoneChargeController.text);
  double get _netWeight => _grossWeight - _stoneWeight;

  String? get _productNameError {
    if (_productNameController.text.trim().isEmpty) {
      return 'Product name is required.';
    }
    return null;
  }

  String? get _grossWeightError {
    if (_grossWeightController.text.trim().isEmpty) {
      return 'Gross weight is required.';
    }
    if (_grossWeight <= 0) return 'Gross weight must be greater than 0.';
    return null;
  }

  String? get _stoneWeightError {
    if (_stoneWeightController.text.trim().isEmpty) return null;
    if (_stoneWeight < 0) return 'Stone weight cannot be negative.';
    if (_stoneWeight > _grossWeight) {
      return 'Stone weight cannot exceed gross weight.';
    }
    return null;
  }

  String? get _stoneChargeError {
    if (_stoneChargeController.text.trim().isEmpty) return null;
    if (_stoneCharge < 0) return 'Stone charge cannot be negative.';
    return null;
  }

  String? get _netWeightError {
    if (_netWeight <= 0) return 'Net weight must be greater than 0.';
    return null;
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImageCount - _images.length;
    if (remaining <= 0) {
      _showSnackBar('Maximum $_maxImageCount images are allowed.');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: remaining,
      );
      if (picked.isEmpty) return;
      _appendImages(picked.take(remaining));
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= _maxImageCount) {
      _showSnackBar('Maximum $_maxImageCount images are allowed.');
      return;
    }

    final hasPermission = await PermissionManager.instance
        .requestCameraPermission(context: context);
    if (!hasPermission) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (picked == null) return;
      _appendImages([picked]);
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  void _appendImages(Iterable<XFile> files) {
    final added = <SelectedProductImage>[];
    for (final file in files) {
      if (!_isAllowedImage(file.path)) continue;
      added.add(
        SelectedProductImage(
          id: '${DateTime.now().microsecondsSinceEpoch}-${added.length}',
          path: file.path,
          fileName: p.basename(file.path),
        ),
      );
    }

    if (added.isEmpty) {
      _showSnackBar('Please select valid JPG, PNG, or WEBP images.');
      return;
    }

    setState(() {
      _images = [..._images, ...added];
      _selectedImageIndex = _images.length - 1;
    });
  }

  Future<void> _replaceImage() async {
    if (_images.isEmpty) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return;
      if (!_isAllowedImage(picked.path)) {
        _showSnackBar('Please select a valid image.');
        return;
      }

      final updated = List<SelectedProductImage>.from(_images);
      final current = updated[_selectedImageIndex];
      updated[_selectedImageIndex] = current.copyWith(
        path: picked.path,
        fileName: p.basename(picked.path),
      );
      setState(() => _images = updated);
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  void _deleteImage() {
    if (_images.isEmpty) return;
    final updated = List<SelectedProductImage>.from(_images)
      ..removeAt(_selectedImageIndex);
    setState(() {
      _images = updated;
      _selectedImageIndex = updated.isEmpty
          ? 0
          : _selectedImageIndex.clamp(0, updated.length - 1);
    });
  }

  Future<void> _cropImage() async {
    if (_images.isEmpty) return;
    final current = _images[_selectedImageIndex];
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: current.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Product Image',
            toolbarColor: AppColors.primaryRoyalBlue,
            toolbarWidgetColor: AppColors.surfaceWhite,
            activeControlsWidgetColor: AppColors.accentGold,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Product Image'),
        ],
      );
      if (cropped == null) return;
      final updated = List<SelectedProductImage>.from(_images);
      updated[_selectedImageIndex] = current.copyWith(
        path: cropped.path,
        fileName: p.basename(cropped.path),
      );
      setState(() => _images = updated);
    } catch (error) {
      _showSnackBar(_errorMessage(error));
    }
  }

  void _rotateImage() {
    if (_images.isEmpty) return;
    final updated = List<SelectedProductImage>.from(_images);
    final current = updated[_selectedImageIndex];
    updated[_selectedImageIndex] = current.copyWith(
      quarterTurns: (current.quarterTurns + 1) % 4,
    );
    setState(() => _images = updated);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    final updated = List<SelectedProductImage>.from(_images);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    setState(() {
      _images = updated;
      _selectedImageIndex = newIndex;
    });
  }

  void _openImageViewer(int index) {
    if (_images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AddProductImageViewer(images: _images, initialIndex: index),
      ),
    );
  }

  Future<void> _saveProduct() async {
    setState(() {
      _submitted = true;
      _saving = true;
    });

    try {
      if (_isEditMode) {
        final existing = widget.initialProductData!;
        final updatedProduct = await _stockRepository.updateProduct(
          productId: existing.id,
          grossWeight: _grossWeight,
          stoneWeight: _stoneWeight,
          stoneCharge: _stoneCharge,
        );

        if (!mounted) return;
        _showSnackBar('Product updated successfully.', success: true);
        widget.onProductUpdated?.call(updatedProduct);
        Navigator.of(context).pop(updatedProduct);
      } else {
        final imageUploadItems = _images
            .map(
              (e) => ProductImageUploadItem(
                path: e.path,
                fileName: e.fileName,
                rotationDegrees: e.quarterTurns * 90,
              ),
            )
            .toList(growable: false);

        final uploadedUrls = await _repository.uploadImages(imageUploadItems);

        final request = _repository.prepareRequest(
          productName: _productNameController.text.trim(),
          grossWeight: _grossWeight,
          stoneWeight: _stoneWeight,
          stoneCharge: _stoneCharge,
          netWeight: _netWeight,
          availableQuantity: 1,
          minimumOrderQuantity: 1,
          images: uploadedUrls,
        );

        final response = await _repository.createProduct(request: request);
        _stockRepository.clearCache();
        _fetchProductNameOptions();

        if (!mounted) return;
        _showSnackBar(
          response.message.isNotEmpty
              ? response.message
              : 'Product added successfully.',
          success: true,
        );
        _clearForm();
      }
    } catch (error) {
      if (mounted) _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _prefillEditProduct() {
    final product = widget.initialProductData;
    if (product == null) return;
    _productNameController.text = product.productName;
    _grossWeightController.text = product.weights.grossWeight > 0
        ? product.weights.grossWeight.toStringAsFixed(3)
        : '';
    _stoneWeightController.text = product.weights.stoneWeight > 0
        ? product.weights.stoneWeight.toStringAsFixed(3)
        : '0';
    _stoneChargeController.text = product.weights.stoneCharge > 0
        ? product.weights.stoneCharge.toStringAsFixed(2)
        : '0';
  }

  void _submitInvalid() {
    setState(() => _submitted = true);
    if (_images.isEmpty) {
      _showSnackBar('Please add at least one product image.');
      return;
    }
    if (_productNameError != null) {
      _showSnackBar('Please enter or select a product name.');
      return;
    }
    if (_grossWeightError != null) {
      _showSnackBar(_grossWeightError!);
      return;
    }
    if (_stoneWeightError != null) {
      _showSnackBar(_stoneWeightError!);
      return;
    }
    if (_stoneChargeError != null) {
      _showSnackBar(_stoneChargeError!);
      return;
    }
    if (_netWeightError != null) {
      _showSnackBar(_netWeightError!);
      return;
    }
    _showSnackBar('Please complete the required product details.');
  }

  void _clearForm() {
    _productNameController.clear();
    _grossWeightController.clear();
    _stoneWeightController.text = '0';
    _stoneChargeController.text = '0';
    setState(() {
      _images = const [];
      _selectedImageIndex = 0;
      _submitted = false;
    });
    _updateNetWeight();
  }

  void _updateNetWeight() {
    final value = _netWeight;
    _netWeightController.text = value > 0 ? value.toStringAsFixed(2) : '0.00';
    _refreshForm();
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  bool _isAllowedImage(String path) {
    return _allowedExtensions.contains(p.extension(path).toLowerCase()) &&
        File(path).existsSync();
  }

  double _parseDecimal(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  void _handleFooterNavigation(int index) {
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerHome, (route) => false);
      return;
    }
    if (index == 2) {
      setState(() => _footerIndex = index);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.stockListing);
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

class _ResponsiveTwoColumn extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveTwoColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
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

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.caption.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
