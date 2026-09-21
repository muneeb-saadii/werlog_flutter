import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../core/models/app_models_extended.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  Entry-point widget — handles permission gate + camera lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class NewCameraScreen extends StatefulWidget {
  final CameraViewData? data;
  final VoidCallback? onClose;

  /// Called after the user taps "Proceed" with the final list of (possibly
  /// cropped) images. The caller is responsible for the actual API request;
  /// use [CameraUploadService.uploadImages] as a ready-made helper.
  final void Function(List<File> images)? onProceed;

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
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      // Short haptic feedback
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

  // ── gallery ─────────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    // On Android <13 we need storage permission for gallery
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkVersion();
      if (sdkInt < 33) {
        final perm = await Permission.storage.request();
        if (!perm.isGranted) return;
      }
      // Android 13+ uses READ_MEDIA_IMAGES, image_picker handles it internally
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
    final files = _images.map((i) => i.displayFile).toList();
    widget.onProceed?.call(files);
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
            onClose: widget.onClose,
            onCapture: _capture,
            onGallery: _pickFromGallery,
            onToggleFlash: _toggleFlash,
            onSwitchCamera: _cameras.length > 1 ? _switchCamera : null,
            onCrop: _cropImage,
            onRemove: _removeImage,
            onProceed: _images.isNotEmpty ? _proceed : null,
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
  final VoidCallback? onClose;
  final VoidCallback? onCapture;
  final VoidCallback? onGallery;
  final VoidCallback? onToggleFlash;
  final VoidCallback? onSwitchCamera;
  final void Function(int) onCrop;
  final void Function(int) onRemove;
  final VoidCallback? onProceed;

  const _CameraBody({
    required this.data,
    required this.controller,
    required this.isCamReady,
    required this.flashMode,
    required this.images,
    required this.isCapturing,
    this.onClose,
    this.onCapture,
    this.onGallery,
    this.onToggleFlash,
    this.onSwitchCamera,
    required this.onCrop,
    required this.onRemove,
    this.onProceed,
  });

  bool get _isWarranty => data.scanType == ScanType.warranty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── top bar ─────────────────────────────────────────────────────────
        _TopBar(
          isWarranty: _isWarranty,
          flashMode: flashMode,
          onClose: onClose,
          onToggleFlash: onToggleFlash,
        ),

        // ── viewfinder ───────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // camera preview
              Positioned.fill(
                child: isCamReady && controller != null
                    ? _CameraPreview(controller: controller!)
                    : const _CameraPlaceholder(),
              ),
              // dark vignette overlay
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
              // scan-type badge
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: _ScanTypeBadge(isWarranty: _isWarranty),
                ),
              ),
              // corner frame guides
              Positioned(
                top: 52, left: 28, right: 28, bottom: 20,
                child: CustomPaint(
                  painter: _CornerFramePainter(
                    color: const Color(0xFFE8A838),
                  ),
                ),
              ),
              // hint text
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

        // ── bottom panel ─────────────────────────────────────────────────────
        _BottomPanel(
          images: images,
          isCapturing: isCapturing,
          onCapture: onCapture,
          onGallery: onGallery,
          onSwitchCamera: onSwitchCamera,
          onCrop: onCrop,
          onRemove: onRemove,
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
  final VoidCallback? onCapture;
  final VoidCallback? onGallery;
  final VoidCallback? onSwitchCamera;
  final void Function(int) onCrop;
  final void Function(int) onRemove;
  final VoidCallback? onProceed;

  const _BottomPanel({
    required this.images,
    required this.isCapturing,
    this.onCapture,
    this.onGallery,
    this.onSwitchCamera,
    required this.onCrop,
    required this.onRemove,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFF0A1E21),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottom + 8),
      child: Column(
        children: [
          // thumbnail strip
          if (images.isNotEmpty)
            _ThumbnailStrip(
              images: images,
              onCrop: onCrop,
              onRemove: onRemove,
            ),

          const SizedBox(height: 10),

          // shutter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // gallery
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
                        child: const Icon(Icons.photo_library_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 5),
                      Text('Gallery',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10)),
                    ],
                  ),
                ),

                // shutter
                GestureDetector(
                  onTap: isCapturing ? null : onCapture,
                  child: AnimatedScale(
                    scale: isCapturing ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 100),
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

                // switch / proceed
                images.isNotEmpty
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
                                  const Icon(Icons.check_rounded,
                                      color: Color(0xFF0A1E21), size: 22),
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
