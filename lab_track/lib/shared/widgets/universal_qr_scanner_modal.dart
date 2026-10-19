import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/scanner_service.dart';
import '../theme/app_colors.dart';

/// God-Level Universal QR & Barcode Scanner Modal Sheet
/// Supports:
/// - Real-time live camera streaming with MLKit Barcode & QR code decoding
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
  static Future<String?> show(BuildContext context, {String? title, String? hint}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalQrScannerModal(
        title: title ?? 'Scan QR / Barcode',
        hint: hint ?? 'Align sterile vial barcode or patient QR within reticle',
      ),
    );
  }

  @override
  State<UniversalQrScannerModal> createState() => _UniversalQrScannerModalState();
}

class _UniversalQrScannerModalState extends State<UniversalQrScannerModal>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  final TextEditingController _manualInputController = TextEditingController();

  bool _isCameraMode = true;
  bool _isTorchOn = false;
  bool _hasScanned = false;
  String? _cameraError;

  final List<String> _demoCodes = [
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
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualInputController.dispose();
    _scannerController.dispose();
    super.dispose();
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
                      onTap: () => setState(() => _isCameraMode = true),
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
                      onTap: () => setState(() => _isCameraMode = false),
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
              Text(
                'Camera Access Notice',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isCameraMode = false),
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Use Quick Presets Instead'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Live camera preview stream
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
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
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _isCameraMode = false),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                        child: const Text('Switch to Manual Input', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            },
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
