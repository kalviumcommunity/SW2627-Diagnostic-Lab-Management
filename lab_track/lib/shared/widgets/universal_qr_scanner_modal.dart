import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/scanner_service.dart';
import '../theme/app_colors.dart';

/// God-Level Universal QR & Barcode Scanner Modal Sheet
/// Supports:
/// - Real-time live camera streaming with MLKit Barcode & QR code decoding
/// - Robust runtime camera permission handling (with direct link to App Settings)
/// - Proper app lifecycle observer to resume camera when returning from settings
/// - Torch control & front/back camera toggling
/// - Graceful fallback to Manual / Demo Presets for web, emulators, or denied permissions
/// - URL & raw barcode extraction using ScannerService
class UniversalQrScannerModal extends StatefulWidget {
  final String title;
  final String hint;

  const UniversalQrScannerModal({
    super.key,
    this.title = 'Scan QR / Barcode',
    this.hint = 'Align sterile vial barcode or patient QR within reticle',
  });

  /// Static helper to open the scanner modal from any screen.
  /// Returns the extracted barcode string or null if cancelled.
  static Future<String?> show(BuildContext context, {String? title, String? hint, String? instructions}) {
    final effectiveHint = hint ?? instructions ?? 'Align sterile vial barcode or patient QR within reticle';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalQrScannerModal(
        title: title ?? 'Scan QR / Barcode',
        hint: effectiveHint,
      ),
    );
  }

  @override
  State<UniversalQrScannerModal> createState() => _UniversalQrScannerModalState();
}

class _UniversalQrScannerModalState extends State<UniversalQrScannerModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  final TextEditingController _manualInputController = TextEditingController();

  bool _isCameraMode = true;
  bool _isTorchOn = false;
  bool _hasScanned = false;
  bool _isCameraStarting = false;
  bool _isPermanentlyDenied = false;
  String? _cameraError;

  final List<String> _demoCodes = [
    'ORD-VIR-101',
    'SMP-VIR-777',
    'SMP-88390',
    'SMP-99120',
    'SMP-77401',
    'SMP-65219',
    'SMP-90214',
    'ORD-84210',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // autoStart: false prevents racing against native Android permission dialogs
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // Start camera after layout pass
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isCameraMode) {
        _requestAndStartCamera();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCameraMode) {
      // Re-trigger camera when returning from system permission dialog or phone settings
      _requestAndStartCamera();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      try {
        _scannerController.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _manualInputController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestAndStartCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraStarting = true;
      _cameraError = null;
      _isPermanentlyDenied = false;
    });

    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

    try {
      if (!kIsWeb && !isTest) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          setState(() {
            _isCameraStarting = false;
            _isPermanentlyDenied = status.isPermanentlyDenied;
            _cameraError = status.isPermanentlyDenied
                ? 'Camera permission is permanently denied. Tap "Open Settings" to enable camera access in App Info.'
                : 'Camera permission denied. Tap "Grant Permission" to scan barcodes.';
          });
          return;
        }
      }

      if (!isTest) {
        await _scannerController.start();
      }
      if (mounted) {
        setState(() {
          _isCameraStarting = false;
          _isPermanentlyDenied = false;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraStarting = false;
          _cameraError = e.toString();
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? barcode.displayValue;
      if (raw != null && raw.trim().isNotEmpty) {
        final extracted = ScannerService.extractSampleBarcode(raw);
        if (extracted != null && extracted.isNotEmpty) {
          _hasScanned = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(extracted);
          break;
        }
      }
    }
  }

  void _submitManual() {
    final text = _manualInputController.text.trim();
    if (text.isEmpty) return;

    final extracted = ScannerService.extractSampleBarcode(text) ?? text.toUpperCase();
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(extracted);
  }

  void _selectPreset(String code) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(code);
  }

  void _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  void _selectCameraMode(bool enable) {
    if (enable == _isCameraMode) return;
    setState(() => _isCameraMode = enable);
    if (enable) {
      _requestAndStartCamera();
    } else {
      try {
        _scannerController.stop();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: min(height * 0.85, 620),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.hint,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Mode Selector Tab (Camera vs Manual Input)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectCameraMode(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCameraMode ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Live Camera',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectCameraMode(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isCameraMode ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.keyboard_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Manual / Presets',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main View (Camera Viewfinder or Manual Input)
          Expanded(
            child: _isCameraMode ? _buildCameraView() : _buildManualView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, size: 48, color: AppColors.warning),
              const SizedBox(height: 12),
              const Text(
                'Camera Access Required',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (_isPermanentlyDenied)
                    ElevatedButton.icon(
                      onPressed: openAppSettings,
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text('Open App Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _requestAndStartCamera,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Grant Permission / Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _selectCameraMode(false),
                    icon: const Icon(Icons.keyboard_rounded, size: 16),
                    label: const Text('Use Manual / Presets'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isCameraStarting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Initializing Camera Hardware...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Live camera preview stream - Positioned.fill guarantees complete container coverage
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              useAppLifecycleState: false, // Managed manually via WidgetsBindingObserver
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_rounded, size: 40, color: AppColors.warning),
                        const SizedBox(height: 10),
                        Text(
                          'Camera unavailable: ${error.errorCode.name}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _requestAndStartCamera,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Retry Camera', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _selectCameraMode(false),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                              child: const Text('Switch to Manual', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Darkened vignette overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
          ),
        ),

        // Reticle Target Box
        Container(
          width: 240,
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Animated Scanning Laser Line
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Positioned(
              top: 70 + (_animController.value * 160),
              child: Container(
                width: 220,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFFEF4444), Colors.transparent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Top Control Tools (Torch & Camera Switch)
        Positioned(
          top: 16,
          right: 20,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? Colors.amber : Colors.white70,
                    size: 20,
                  ),
                  tooltip: 'Toggle Flashlight',
                  onPressed: _toggleTorch,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Switch Camera',
                  onPressed: _switchCamera,
                ),
              ),
            ],
          ),
        ),

        // Bottom Instruction Pill
        Positioned(
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 14),
                SizedBox(width: 6),
                Text(
                  'Auto-detects QR codes & Code-128 barcodes',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Barcode / QR Input',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualInputController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter code or paste URL (e.g. SMP-88390)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onSubmitted: (_) => _submitManual(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _submitManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: const [
              Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text(
                '1-Click Demo Specimen Barcodes',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select any active system specimen to test without camera hardware:',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _demoCodes.map((code) {
              return ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Colors.white12),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onPressed: () => _selectPreset(code),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
