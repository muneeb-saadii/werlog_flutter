import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../core/models/app_models_extended.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  CameraResult — what onProceed delivers to the caller
//  Exactly ONE of [images] or [pdf] will be non-null / non-empty.
// ─────────────────────────────────────────────────────────────────────────────
class CameraResult {
  /// Non-empty when the user captured / picked images.
  final List<File> images;

  /// Non-null when the user picked a PDF.
  final File? pdf;

  const CameraResult._({required this.images, this.pdf});

  /// Convenience factory for an image result.
  factory CameraResult.images(List<File> images) =>
      CameraResult._(images: images);

  /// Convenience factory for a PDF result.
  factory CameraResult.pdf(File pdf) =>
      CameraResult._(images: const [], pdf: pdf);

  /// True when the result is a PDF (not images).
  bool get isPdf => pdf != null;

  /// True when the result is images (not a PDF).
  bool get isImages => pdf == null && images.isNotEmpty;
}


// ─────────────────────────────────────────────────────────────────────────────
//  Entry-point widget — handles permission gate + camera lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class NewCameraScreen extends StatefulWidget {
  final CameraViewData? data;
  final VoidCallback? onClose;

  /// Called after the user taps "Proceed".
  /// [result.isPdf]    → user selected a PDF — use result.pdf
  /// [result.isImages] → user captured/picked images — use result.images
  final void Function(CameraResult result)? onProceed;

  const NewCameraScreen({
    super.key,
    this.data,
    this.onClose,
    this.onProceed,
  });

  @override
  State<NewCameraScreen> createState() => _NewCameraScreenState();
}

class _NewCameraScreenState extends State<NewCameraScreen>
    with WidgetsBindingObserver {
  // ── permission ──────────────────────────────────────────────────────────────
  _PermState _permState = _PermState.checking;

  // ── camera ──────────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _camIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isCamReady = false;

  // ── images ──────────────────────────────────────────────────────────────────
  final List<CapturedImage> _images = [];
  bool _isCapturing = false;

  // ── pdf ─────────────────────────────────────────────────────────────────────
  /// Non-null when a PDF has been selected. Mutually exclusive with _images.
  File? _selectedPdf;
  String? _selectedPdfName;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_camIndex);
    }
  }

  // ── permission flow ─────────────────────────────────────────────────────────

  Future<void> _checkPermissions() async {
    final cam = await Permission.camera.status;
    if (cam.isGranted) {
      await _initCameras();
    } else if (cam.isPermanentlyDenied) {
      setState(() => _permState = _PermState.permanentlyDenied);
    } else {
      setState(() => _permState = _PermState.requesting);
    }
  }

  Future<void> _requestPermission() async {
    final result = await Permission.camera.request();
    if (result.isGranted) {
      await _initCameras();
    } else if (result.isPermanentlyDenied) {
      setState(() => _permState = _PermState.permanentlyDenied);
    } else {
      setState(() => _permState = _PermState.denied);
    }
  }

  // ── camera init ─────────────────────────────────────────────────────────────

  Future<void> _initCameras() async {
    setState(() => _permState = _PermState.granted);
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) _initCamera(0);
  }

  Future<void> _initCamera(int index) async {
    await _controller?.dispose();
    setState(() => _isCamReady = false);

    final ctrl = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;

    try {
      await ctrl.initialize();
      await ctrl.setFlashMode(_flashMode);
      if (mounted) setState(() => _isCamReady = true);
    } on CameraException catch (e) {
      debugPrint('Camera init error: ${e.description}');
    }
  }

  // ── capture ─────────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    // Block camera capture when a PDF is selected
    if (_selectedPdf != null) {
      _showConflictSnackbar(
          'Remove the PDF first before capturing images.');
      return;
    }

    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      HapticFeedback.mediumImpact();
      final xFile = await ctrl.takePicture();
      final file = File(xFile.path);
      setState(() => _images.add(CapturedImage(file: file)));
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── gallery / PDF source prompt ──────────────────────────────────────────────

  /// Shows a bottom sheet letting the user choose: photos OR PDF.
  /// Enforces the mutual-exclusivity rule before opening either picker.
  Future<void> _showMediaSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaSourceSheet(
        hasPdf:    _selectedPdf != null,
        hasImages: _images.isNotEmpty,
        onPickImages: () {
          Navigator.pop(context);
          _pickFromGallery();
        },
        onPickPdf: () {
          Navigator.pop(context);
          _pickPdf();
        },
      ),
    );
  }

  // ── gallery (images only) ────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    // Block if a PDF is already selected
    if (_selectedPdf != null) {
      _showConflictSnackbar(
          'Remove the PDF first before adding images.');
      return;
    }

    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkVersion();
      if (sdkInt < 33) {
        final perm = await Permission.storage.request();
        if (!perm.isGranted) return;
      }
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        _images.add(CapturedImage(file: File(x.path)));
      }
    });
  }

  // ── PDF picker ───────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    // Block if images are already present
    if (_images.isNotEmpty) {
      _showConflictSnackbar(
          'Remove all images first before selecting a PDF.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,         // one PDF only
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedPdf     = File(path);
      _selectedPdfName = result.files.single.name;
    });
  }

  void _clearPdf() {
    setState(() {
      _selectedPdf     = null;
      _selectedPdfName = null;
    });
  }

  void _showConflictSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: Colors.white)),
        backgroundColor: const Color(0xFF1A3A3F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<int> _androidSdkVersion() async {
    try {
      final v = await const MethodChannel('werlog/system')
          .invokeMethod<int>('getSdkInt');
      return v ?? 33;
    } catch (_) {
      return 33;
    }
  }

  // ── crop ─────────────────────────────────────────────────────────────────────

  Future<void> _cropImage(int index) async {
    final img = _images[index];
    final cropped = await ImageCropper().cropImage(
      sourcePath: img.displayFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF0D2427),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFE8A838),
          backgroundColor: const Color(0xFF0D2427),
          statusBarColor: const Color(0xFF0D2427),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          minimumAspectRatio: 0.5,
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() {
        _images[index] = img.withCrop(File(cropped.path));
      });
    }
  }

  // ── remove ──────────────────────────────────────────────────────────────────

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ── flash / switch ───────────────────────────────────────────────────────────

  Future<void> _toggleFlash() async {
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_camIndex + 1) % _cameras.length;
    _camIndex = next;
    await _initCamera(next);
  }

  // ── proceed ──────────────────────────────────────────────────────────────────

  void _proceed() {
    if (_selectedPdf != null) {
      widget.onProceed?.call(CameraResult.pdf(_selectedPdf!));
    } else if (_images.isNotEmpty) {
      final files = _images.map((i) => i.displayFile).toList();
      widget.onProceed?.call(CameraResult.images(files));
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1E21),
      body: switch (_permState) {
        _PermState.checking => const _LoadingView(),
        _PermState.requesting => _PermissionRequestView(
            onRequest: _requestPermission,
            onClose: widget.onClose,
          ),
        _PermState.denied => _PermissionRequestView(
            onRequest: _requestPermission,
            onClose: widget.onClose,
            isDenied: true,
          ),
        _PermState.permanentlyDenied => _PermissionRequestView(
            onRequest: () => openAppSettings(),
            onClose: widget.onClose,
            isPermanent: true,
          ),
        _PermState.granted => _CameraBody(
            data: widget.data ?? CameraViewData(),
            controller: _controller,
            isCamReady: _isCamReady,
            flashMode: _flashMode,
            images: _images,
            isCapturing: _isCapturing,
            selectedPdf: _selectedPdf,
            selectedPdfName: _selectedPdfName,
            onClose: widget.onClose,
            onCapture: _capture,
            onGallery: (ctx) => _showMediaSourceSheet(ctx),
            onToggleFlash: _toggleFlash,
            onSwitchCamera: _cameras.length > 1 ? _switchCamera : null,
            onCrop: _cropImage,
            onRemove: _removeImage,
            onRemovePdf: _clearPdf,
            onProceed: (_images.isNotEmpty || _selectedPdf != null)
                ? _proceed
                : null,
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Permission gate views
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionRequestView extends StatelessWidget {
  final VoidCallback? onRequest;
  final VoidCallback? onClose;
  final bool isDenied;
  final bool isPermanent;

  const _PermissionRequestView({
    this.onRequest,
    this.onClose,
    this.isDenied = false,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onClose,
              child: _CircleButton(
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const Spacer(),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A3F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFE8A838).withOpacity(0.4), width: 1),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFFE8A838), size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              isPermanent
                  ? 'Camera access\nblocked'
                  : isDenied
                      ? 'Camera access\ndenied'
                      : 'Allow camera\naccess',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPermanent
                  ? 'Please enable camera permission in your device settings to scan documents.'
                  : isDenied
                      ? 'Camera permission is required to capture receipts and warranties.'
                      : 'This app needs camera access to scan your receipts, warranties, and documents.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A838),
                  foregroundColor: const Color(0xFF0A1E21),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isPermanent ? 'Open Settings' : 'Allow Camera',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFE8A838)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main camera body
// ─────────────────────────────────────────────────────────────────────────────

class _CameraBody extends StatelessWidget {
  final CameraViewData data;
  final CameraController? controller;
  final bool isCamReady;
  final FlashMode flashMode;
  final List<CapturedImage> images;
  final bool isCapturing;
  final File? selectedPdf;
  final String? selectedPdfName;
  final VoidCallback? onClose;
  final VoidCallback? onCapture;
  final void Function(BuildContext ctx) onGallery;   // now receives context
  final VoidCallback? onToggleFlash;
  final VoidCallback? onSwitchCamera;
  final void Function(int) onCrop;
  final void Function(int) onRemove;
  final VoidCallback? onRemovePdf;
  final VoidCallback? onProceed;

  const _CameraBody({
    required this.data,
    required this.controller,
    required this.isCamReady,
    required this.flashMode,
    required this.images,
    required this.isCapturing,
    this.selectedPdf,
    this.selectedPdfName,
    this.onClose,
    this.onCapture,
    required this.onGallery,
    this.onToggleFlash,
    this.onSwitchCamera,
    required this.onCrop,
    required this.onRemove,
    this.onRemovePdf,
    this.onProceed,
  });

  bool get _isWarranty => data.scanType == ScanType.warranty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(
          isWarranty: _isWarranty,
          flashMode: flashMode,
          onClose: onClose,
          onToggleFlash: onToggleFlash,
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: isCamReady && controller != null
                    ? _CameraPreview(controller: controller!)
                    : const _CameraPlaceholder(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14, left: 0, right: 0,
                child: Center(child: _ScanTypeBadge(isWarranty: _isWarranty)),
              ),
              Positioned(
                top: 52, left: 28, right: 28, bottom: 20,
                child: CustomPaint(
                  painter: _CornerFramePainter(
                      color: const Color(0xFFE8A838)),
                ),
              ),
              Positioned(
                bottom: 8, left: 0, right: 0,
                child: Text(
                  data.hintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomPanel(
          images: images,
          isCapturing: isCapturing,
          selectedPdf: selectedPdf,
          selectedPdfName: selectedPdfName,
          onCapture: onCapture,
          onGallery: () => onGallery(context),
          onSwitchCamera: onSwitchCamera,
          onCrop: onCrop,
          onRemove: onRemove,
          onRemovePdf: onRemovePdf,
          onProceed: onProceed,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Camera preview with correct aspect ratio handling
// ─────────────────────────────────────────────────────────────────────────────

class _CameraPreview extends StatelessWidget {
  final CameraController controller;
  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0D2427),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Color(0xFFE8A838)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isWarranty;
  final FlashMode flashMode;
  final VoidCallback? onClose;
  final VoidCallback? onToggleFlash;

  const _TopBar({
    required this.isWarranty,
    required this.flashMode,
    this.onClose,
    this.onToggleFlash,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: const Color(0xFF0A1E21),
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: _CircleButton(
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggleFlash,
            child: _CircleButton(
              active: flashMode == FlashMode.torch,
              child: Icon(
                flashMode == FlashMode.torch
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: flashMode == FlashMode.torch
                    ? const Color(0xFFE8A838)
                    : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom panel — thumbnail strip + shutter + controls
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final List<CapturedImage> images;
  final bool isCapturing;
  final File? selectedPdf;
  final String? selectedPdfName;
  final VoidCallback? onCapture;
  final VoidCallback? onGallery;
  final VoidCallback? onSwitchCamera;
  final void Function(int) onCrop;
  final void Function(int) onRemove;
  final VoidCallback? onRemovePdf;
  final VoidCallback? onProceed;

  const _BottomPanel({
    required this.images,
    required this.isCapturing,
    this.selectedPdf,
    this.selectedPdfName,
    this.onCapture,
    this.onGallery,
    this.onSwitchCamera,
    required this.onCrop,
    required this.onRemove,
    this.onRemovePdf,
    this.onProceed,
  });

  bool get _hasContent => images.isNotEmpty || selectedPdf != null;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFF0A1E21),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottom + 8),
      child: Column(
        children: [
          // ── PDF chip OR image thumbnail strip ──────────────────────────────
          if (selectedPdf != null)
            _PdfChip(
              name: selectedPdfName ?? 'document.pdf',
              onRemove: onRemovePdf,
            )
          else if (images.isNotEmpty)
            _ThumbnailStrip(
              images: images,
              onCrop: onCrop,
              onRemove: onRemove,
            ),

          const SizedBox(height: 10),

          // ── shutter row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // gallery / PDF picker
                GestureDetector(
                  onTap: onGallery,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A3F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: const Icon(Icons.folder_open_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 5),
                      Text('Import',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10)),
                    ],
                  ),
                ),

                // shutter (disabled when PDF selected)
                GestureDetector(
                  onTap: (isCapturing || selectedPdf != null) ? null : onCapture,
                  child: AnimatedScale(
                    scale: isCapturing ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Opacity(
                      opacity: selectedPdf != null ? 0.3 : 1.0,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCapturing
                                  ? const Color(0xFFE8A838).withOpacity(0.7)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // proceed / switch camera
                _hasContent
                    ? GestureDetector(
                        onTap: onProceed,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8A838),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    selectedPdf != null
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.check_rounded,
                                    color: const Color(0xFF0A1E21),
                                    size: 22,
                                  ),
                                  if (images.isNotEmpty)
                                    Positioned(
                                      top: 6, right: 6,
                                      child: Container(
                                        width: 16, height: 16,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF0A1E21),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${images.length}',
                                          style: const TextStyle(
                                            color: Color(0xFFE8A838),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('Proceed',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10)),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: onSwitchCamera,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3A3F),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 0.5),
                              ),
                              child: const Icon(Icons.flip_camera_ios_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(height: 5),
                            Text('Flip',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PDF chip — shown in the thumbnail strip area when a PDF is selected
// ─────────────────────────────────────────────────────────────────────────────

class _PdfChip extends StatelessWidget {
  final String name;
  final VoidCallback? onRemove;
  const _PdfChip({required this.name, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A3F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFE8A838).withOpacity(0.35), width: 0.8),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8A838).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFFE8A838), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('1 PDF selected · tap × to remove',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'DMSans')),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFE24B4A)),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media source bottom sheet — Images vs PDF with mutual-exclusivity messaging
// ─────────────────────────────────────────────────────────────────────────────

class _MediaSourceSheet extends StatelessWidget {
  final bool hasPdf;
  final bool hasImages;
  final VoidCallback onPickImages;
  final VoidCallback onPickPdf;

  const _MediaSourceSheet({
    required this.hasPdf,
    required this.hasImages,
    required this.onPickImages,
    required this.onPickPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F2A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Drag handle
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Choose file type',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Images and PDF cannot be mixed in one upload.',
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: Colors.white.withOpacity(0.4)),
          ),
        ),

        const SizedBox(height: 18),

        // Images option
        _SourceTile(
          icon: Icons.photo_library_rounded,
          title: 'Photos / Images',
          subtitle: 'Select one or multiple images',
          locked: hasPdf,
          lockedReason: 'Remove the PDF first',
          onTap: hasPdf ? null : onPickImages,
        ),

        const SizedBox(height: 10),

        // PDF option
        _SourceTile(
          icon: Icons.picture_as_pdf_rounded,
          title: 'PDF Document',
          subtitle: 'Select a single PDF (multi-page supported)',
          locked: hasImages,
          lockedReason: 'Remove all images first',
          onTap: hasImages ? null : onPickPdf,
        ),

        const SizedBox(height: 4),
      ]),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;
  final String lockedReason;
  final VoidCallback? onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.locked,
    required this.lockedReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A3F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: locked
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE8A838).withOpacity(0.25),
              width: 0.8,
            ),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: locked
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE8A838).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: locked
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFFE8A838),
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: locked
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    locked ? lockedReason : subtitle,
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 10,
                        color: locked
                            ? const Color(0xFFE24B4A).withOpacity(0.7)
                            : Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            if (!locked)
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFE8A838), size: 18),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Thumbnail strip with crop/remove per image
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  final List<CapturedImage> images;
  final void Function(int) onCrop;
  final void Function(int) onRemove;

  const _ThumbnailStrip({
    required this.images,
    required this.onCrop,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        itemBuilder: (ctx, i) {
          final img = images[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // thumbnail
                GestureDetector(
                  onTap: () => onCrop(i),
                  child: Container(
                    width: 72, height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: img.isCropped
                            ? const Color(0xFFE8A838)
                            : Colors.white.withOpacity(0.15),
                        width: img.isCropped ? 1.5 : 0.5,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.file(img.displayFile, fit: BoxFit.cover),
                  ),
                ),
                // crop badge
                if (img.isCropped)
                  Positioned(
                    bottom: 5, left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A838),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('cropped',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A1E21))),
                    ),
                  ),
                // crop icon overlay
                Positioned(
                  bottom: 5, right: 5,
                  child: GestureDetector(
                    onTap: () => onCrop(i),
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.crop_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ),
                // remove button
                Positioned(
                  top: -5, right: -5,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE24B4A),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Scan-type badge
// ─────────────────────────────────────────────────────────────────────────────

class _ScanTypeBadge extends StatelessWidget {
  final bool isWarranty;
  const _ScanTypeBadge({required this.isWarranty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8A838).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFE8A838).withOpacity(0.45), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarranty ? Icons.verified_rounded : Icons.receipt_long_rounded,
            color: const Color(0xFFE8A838),
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isWarranty ? 'WARRANTY SCAN' : 'EXPENSE SCAN',
            style: const TextStyle(
              color: Color(0xFFE8A838),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Circle button
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final Widget child;
  final bool active;
  const _CircleButton({required this.child, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFFE8A838).withOpacity(0.15)
            : Colors.white.withOpacity(0.12),
        border: Border.all(
          color: active
              ? const Color(0xFFE8A838).withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Corner frame painter
// ─────────────────────────────────────────────────────────────────────────────

class _CornerFramePainter extends CustomPainter {
  final Color color;
  const _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const len = 24.0;

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o + Offset(dx, 0), paint);
      canvas.drawLine(o, o + Offset(0, dy), paint);
    }

    corner(Offset.zero, len, len);
    corner(Offset(size.width, 0), -len, len);
    corner(Offset(0, size.height), len, -len);
    corner(Offset(size.width, size.height), -len, -len);
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter old) => old.color != color;
}

enum _PermState { checking, requesting, denied, permanentlyDenied, granted }

/// Represents a single image in the capture session.
/// [original] is always the raw file; [cropped] is set after user crops it.
class CapturedImage {
  final File file;
  final File? cropped;

  const CapturedImage({required this.file, this.cropped});

  /// Returns the cropped file if it exists, otherwise the original.
  File get displayFile => cropped ?? file;

  bool get isCropped => cropped != null;

  CapturedImage withCrop(File croppedFile) =>
      CapturedImage(file: file, cropped: croppedFile);
}


// enum ScanType { expense, warranty }

class CameraViewData {
  final ScanType scanType;
  final String hintText;

  CameraViewData({
    this.scanType = ScanType.expense,
    String? hintText,
  }) : hintText = hintText ??
      (scanType == ScanType.warranty
          ? 'Position the warranty card or document inside the frame'
          : 'Position your receipt or invoice inside the frame');
}



/// Result returned by [CameraUploadService.uploadImages].
class UploadResult {
  final bool success;
  final int statusCode;
  final String body;
  final String? error;

  const UploadResult({
    required this.success,
    required this.statusCode,
    required this.body,
    this.error,
  });
}

class CameraUploadService {
  final String baseUrl;
  final String? authToken;

  const CameraUploadService({
    required this.baseUrl,
    this.authToken,
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API
  //  Call this with the list of (possibly cropped) files from onProceed.
  //  Returns an [UploadResult] you can inspect or show to the user.
  // ─────────────────────────────────────────────────────────────────────────

  /// Uploads [images] as a multipart/form-data POST to [endpoint].
  ///
  /// [fieldName]  — the form field name expected by your API (default: "files")
  /// [extraFields] — any additional string fields (e.g. scanType, userId …)
  ///
  /// Example:
  /// ```dart
  /// final svc = CameraUploadService(
  ///   baseUrl: 'https://api.example.com',
  ///   authToken: prefs.getString('token'),
  /// );
  /// final result = await svc.uploadImages(
  ///   images: files,
  ///   endpoint: '/api/scans/upload',
  ///   extraFields: {'scan_type': 'expense', 'user_id': '42'},
  /// );
  /// if (result.success) { /* proceed */ }
  /// ```
  Future<UploadResult> uploadImages({
    required List<File> images,
    String endpoint = 'v1/ocr/jobs',
    String fieldName = 'files',
    Map<String, String> extraFields = const {},
  }) async {

    print('\n================ UPLOAD STARTED ================');

    try {

      // =========================================================
      // URL
      // =========================================================

      final uri = Uri.parse('$baseUrl$endpoint');

      print('BASE URL => $baseUrl');
      print('ENDPOINT => $endpoint');
      print('FINAL URL => $uri');

      // =========================================================
      // REQUEST
      // =========================================================

      final request = http.MultipartRequest('POST', uri);

      print('REQUEST CREATED');

      // =========================================================
      // AUTH
      // =========================================================

      if (authToken != null) {

        request.headers['Authorization'] = 'Bearer $authToken';

        print('AUTH TOKEN ATTACHED');
        print('TOKEN => $authToken');

      } else {

        print('NO AUTH TOKEN FOUND');

      }

      // =========================================================
      // HEADERS
      // =========================================================

      print('HEADERS => ${request.headers}');

      // =========================================================
      // EXTRA FIELDS
      // =========================================================

      request.fields.addAll(extraFields);

      print('FIELDS ADDED => ${request.fields}');

      // =========================================================
      // FILES
      // =========================================================

      print('TOTAL IMAGES => ${images.length}');

      for (int i = 0; i < images.length; i++) {

        final file = images[i];

        print('\n------------- IMAGE ${i + 1} -------------');

        print('FILE PATH => ${file.path}');
        print('FILE EXISTS => ${await file.exists()}');

        final fileLength = await file.length();

        print('FILE SIZE => $fileLength bytes');

        final mime = lookupMimeType(file.path) ?? 'image/jpeg';

        print('MIME TYPE => $mime');

        final parts = mime.split('/');

        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType(parts[0], parts[1]),
        );

        request.files.add(multipartFile);

        print('FILE ADDED TO REQUEST');
        print('FIELD NAME => $fieldName');
        print('CONTENT TYPE => ${parts[0]}/${parts[1]}');
      }

      print('\nTOTAL FILES IN REQUEST => ${request.files.length}');

      // =========================================================
      // SENDING REQUEST
      // =========================================================

      print('\nSENDING REQUEST...');

      final streamed = await request.send();

      print('REQUEST SENT');
      print('STATUS CODE => ${streamed.statusCode}');

      // =========================================================
      // RESPONSE
      // =========================================================

      final response = await http.Response.fromStream(streamed);

      print('\n================ RESPONSE RECEIVED ================');

      print('STATUS CODE => ${response.statusCode}');
      print('RESPONSE HEADERS => ${response.headers}');
      print('RESPONSE BODY => ${response.body}');

      final success =
          response.statusCode >= 200 &&
              response.statusCode < 300;

      print('UPLOAD SUCCESS => $success');

      print('================ UPLOAD FINISHED ================\n');

      return UploadResult(
        success: success,
        statusCode: response.statusCode,
        body: response.body,
      );

    } catch (e, stackTrace) {

      print('\n================ UPLOAD ERROR ================');

      print('ERROR => $e');

      print('\nSTACKTRACE =>');
      print(stackTrace);

      print('================ ERROR END ================\n');

      return UploadResult(
        success: false,
        statusCode: 0,
        body: '',
        error: e.toString(),
      );
    }
  }
}
