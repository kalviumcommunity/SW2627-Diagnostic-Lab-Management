import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/scanner_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/universal_qr_scanner_modal.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../backend/models/phlebotomist_collection_request.dart';
import '../providers/phlebotomist_provider.dart';
import 'collect_confirm_screen.dart';

class ScanVialScreen extends StatefulWidget {
  final OrderModel? order;

  const ScanVialScreen({super.key, this.order});

  @override
  State<ScanVialScreen> createState() => _ScanVialScreenState();
}

class _ScanVialScreenState extends State<ScanVialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TextEditingController _barcodeController;
  final TextEditingController _notesController = TextEditingController();
  late final MobileScannerController _scannerController;

  OrderModel? _currentOrder;
  String _selectedVialType = 'Purple Top (K2 EDTA)';
  double _temperatureCelsius = 4.0;
  bool _isTorchOn = false;
  bool _isCameraActive = true;
  String? _cameraErrorMessage;
  bool _isPermanentlyDenied = false;
  bool _isVerifyingBarcode = false;
  String? _barcodeError;
  bool _isSuccessScanned = false;
  bool _isPatientQrVerified = false;

  late AnimationController _animController;

  final List<Map<String, dynamic>> _vialTypes = [
    {
      'name': 'Purple Top (K2 EDTA)',
      'color': const Color(0xFF7E22CE),
      'tests': 'CBC, HbA1c, ESR',
      'vol': '3.0 mL',
    },
    {
      'name': 'Gold Top (SST Serum Gel)',
      'color': const Color(0xFFD97706),
      'tests': 'Thyroid, LFT, KFT, Lipids',
      'vol': '5.0 mL',
    },
    {
      'name': 'Grey Top (Sodium Fluoride)',
      'color': const Color(0xFF475569),
      'tests': 'Fasting Glucose, PPBS',
      'vol': '2.0 mL',
    },
    {
      'name': 'Red Top (Plain Serum)',
      'color': const Color(0xFFDC2626),
      'tests': 'Serology, Antibodies, Immunology',
      'vol': '4.0 mL',
    },
    {
      'name': 'Light Blue (Sodium Citrate)',
      'color': const Color(0xFF0284C7),
      'tests': 'Coagulation, PT/INR, D-Dimer',
      'vol': '2.7 mL',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentOrder = widget.order;
    _barcodeController = TextEditingController();

    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isCameraActive) {
        _startCamera();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCameraActive) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      try {
        _scannerController.stop();
      } catch (_) {}
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentOrder == null) {
      final provider = context.read<PhlebotomistProvider>();
      if (provider.pendingPickups.isNotEmpty) {
        _currentOrder = provider.pendingPickups.first;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeController.dispose();
    _notesController.dispose();
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!mounted) return;
    setState(() {
      _cameraErrorMessage = null;
      _isPermanentlyDenied = false;
    });

    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

    try {
      if (!kIsWeb && !isTest) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          setState(() {
            _isPermanentlyDenied = status.isPermanentlyDenied;
            _cameraErrorMessage = status.isPermanentlyDenied
                ? 'Camera permission permanently denied. Enable in App Settings.'
                : 'Camera permission denied. Tap Retry below.';
          });
          return;
        }
      }

      if (!isTest) {
        await _scannerController.start();
      }
      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isPermanentlyDenied = false;
          _cameraErrorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _openPatientQrScanner() async {
    try {
      await _scannerController.stop();
    } catch (_) {}
    if (!mounted) return;
    final code = await UniversalQrScannerModal.show(
      context,
      title: 'Scan Patient Doorstep QR Pass',
      hint: 'Point camera at the Appointment QR Pass on ' + (_currentOrder?.patientName ?? 'Patient') + ' phone.',
    );
    if (code != null && code.isNotEmpty) {
      final user = context.read<AuthProvider>().currentUser;
      final provider = context.read<PhlebotomistProvider>();
      final verifiedOrder = await provider.verifyPatientDoorstepPass(
        orderId: code,
        phlebotomistId: user?.id ?? 'PH-PRAVEEN',
        phlebotomistName: user?.name ?? 'Praveen',
      );

      if (!mounted) return;
      setState(() {
        _isPatientQrVerified = true;
        if (verifiedOrder != null) {
          _currentOrder = verifiedOrder;
        }
      });

      HapticFeedback.heavyImpact();

      // Show rich celebratory confirmation dialog on Phlebotomist screen
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldTealGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.glowShadow(AppColors.success, opacity: 0.35),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Doorstep Identity Verified!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Patient ' + (verifiedOrder?.patientName ?? _currentOrder?.patientName ?? "Patient") + ' authenticated.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID:', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text(
                          '#' + (verifiedOrder?.id ?? _currentOrder?.id ?? code),
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phlebotomist:', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text(
                          user?.name ?? 'Praveen',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Chain-of-Custody:', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text('UNLOCKED ✓', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.successDark)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Proceed to Vial Scan', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (mounted && _isCameraActive) {
      _startCamera();
    }
  }

  Future<void> _openVialFullscreenScanner() async {
    try {
      await _scannerController.stop();
    } catch (_) {}
    if (!mounted) return;
    final code = await UniversalQrScannerModal.show(
      context,
      title: 'Scan Sterile Vial Barcode',
      hint: 'Align specimen tube barcode (SMP-XXXXX) within reticle',
    );
    if (code != null && code.isNotEmpty) {
      _applyBarcode(code);
    }
    if (mounted && _isCameraActive) {
      _startCamera();
    }
  }

  void _generateRandomBarcode() {
    final rand = Random();
    final num = 10000 + rand.nextInt(89999);
    final code = 'SMP-$num';
    _applyBarcode(code);
  }

  Future<void> _applyBarcode(String code) async {
    setState(() {
      _barcodeController.text = code;
      _isVerifyingBarcode = true;
      _barcodeError = null;
      _isSuccessScanned = false;
    });

    final provider = context.read<PhlebotomistProvider>();
    final isUsed = await provider.isBarcodeAlreadyUsed(code);

    if (!mounted) return;
    setState(() {
      _isVerifyingBarcode = false;
      if (isUsed) {
        _barcodeError = 'Barcode "$code" is already assigned to an existing vial. Use a fresh tube!';
        _isSuccessScanned = false;
      } else {
        _barcodeError = null;
        _isSuccessScanned = true;
      }
    });
  }

  Future<void> _submitCollection() async {
    if (_currentOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active collection order.')),
      );
      return;
    }

    if (!_isPatientQrVerified) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 10),
              Text('Verify Patient QR Pass', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: const Text(
            'For complete chain-of-custody compliance, please authenticate the patient\'s Doorstep Appointment QR Pass before binding specimen tubes.',
            style: TextStyle(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _isPatientQrVerified = true);
                Navigator.pop(ctx, true);
              },
              child: const Text('Manual Override', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx, false);
                await _openPatientQrScanner();
                if (_isPatientQrVerified) {
                  _submitCollection();
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: const Text('Scan QR Pass'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      if (proceed != true && !_isPatientQrVerified) return;
    }

    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      setState(() => _barcodeError = 'Please scan or enter a sterile vial barcode.');
      return;
    }

    if (_barcodeError != null) return;

    final user = context.read<AuthProvider>().currentUser;
    final provider = context.read<PhlebotomistProvider>();

    final request = PhlebotomistCollectionRequest(
      orderId: _currentOrder!.id,
      patientId: _currentOrder!.patientId,
      patientName: _currentOrder!.patientName,
      sampleBarcode: barcode,
      vialType: _selectedVialType,
      temperatureCelsius: _temperatureCelsius,
      locationAddress: _currentOrder!.collectionAddress,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      phlebotomistId: user?.id ?? 'PH-PRAVEEN',
      phlebotomistName: user?.name ?? 'Praveen Sharma',
    );

    final result = await provider.confirmCollection(request);

    if (!mounted) return;
    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CollectConfirmScreen(sample: result),
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhlebotomistProvider>();
    final pendingOrders = provider.pendingPickups;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan & Bind Vial Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: _isTorchOn ? 'Torch Off' : 'Torch On',
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : null,
            ),
            onPressed: () async {
              try {
                await _scannerController.toggleTorch();
              } catch (_) {}
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            tooltip: 'Flip Camera',
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () async {
              try {
                await _scannerController.switchCamera();
              } catch (_) {}
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Selector if multiple exist
            if (pendingOrders.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (pendingOrders.any((o) => o.id == _currentOrder?.id)) ? _currentOrder?.id : null,
                          isExpanded: true,
                          hint: const Text('Select Patient Pickup'),
                          items: pendingOrders.map((o) {
                            return DropdownMenuItem<String>(
                              value: o.id,
                              child: Text(
                                '${o.patientName} (${o.id}) • ${o.timeSlot.split("(").first.trim()}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _currentOrder = pendingOrders.firstWhere((o) => o.id == val, orElse: () => pendingOrders.first);
                                _isPatientQrVerified = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // STAGE 1: VERIFY PATIENT DOORSTEP APPOINTMENT QR PASS
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isPatientQrVerified ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPatientQrVerified ? AppColors.success : AppColors.border,
                  width: _isPatientQrVerified ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isPatientQrVerified ? AppColors.successLight : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPatientQrVerified ? Icons.verified_user_rounded : Icons.qr_code_scanner_rounded,
                          color: _isPatientQrVerified ? AppColors.successDark : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'STAGE 1: PATIENT IDENTITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: _isPatientQrVerified ? AppColors.successDark : const Color(0xFFD97706),
                                  ),
                                ),
                                const Spacer(),
                                if (_isPatientQrVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'VERIFIED',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPatientQrVerified
                                  ? 'Doorstep Appointment QR Authenticated • ' + (_currentOrder?.patientName ?? 'Patient')
                                  : 'Scan Patient Doorstep QR Pass before drawing specimen',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isPatientQrVerified ? const Color(0xFF14532D) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openPatientQrScanner,
                          icon: Icon(
                            _isPatientQrVerified ? Icons.refresh_rounded : Icons.qr_code_2_rounded,
                            size: 16,
                            color: _isPatientQrVerified ? AppColors.successDark : const Color(0xFFD97706),
                          ),
                          label: Text(
                            _isPatientQrVerified ? 'Rescan QR Pass' : 'Scan Patient QR Pass',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _isPatientQrVerified ? AppColors.successDark : const Color(0xFFD97706),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isPatientQrVerified ? AppColors.success : const Color(0xFFD97706),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (!_isPatientQrVerified) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _isPatientQrVerified = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient identity manually verified via ID check.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Manual Override', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Scanner Viewfinder Card
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Live MobileScanner or Graceful Simulation Fallback
                    if (_isCameraActive && _cameraErrorMessage == null)
                      Positioned.fill(
                        child: MobileScanner(
                          controller: _scannerController,
                          useAppLifecycleState: false,
                          onDetect: (capture) {
                            if (_isVerifyingBarcode) return;
                            for (final b in capture.barcodes) {
                              final raw = b.rawValue ?? b.displayValue;
                              if (raw != null && raw.trim().isNotEmpty) {
                                final code = ScannerService.extractSampleBarcode(raw) ?? raw.trim().toUpperCase();
                                if (code != _barcodeController.text) {
                                  HapticFeedback.mediumImpact();
                                  _applyBarcode(code);
                                }
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error) {
                            return Container(
                              color: const Color(0xFF1E293B),
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.videocam_off_rounded, color: AppColors.warning, size: 36),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Camera Feed: ${error.errorCode.name}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      error.errorCode == MobileScannerErrorCode.permissionDenied
                                          ? 'Camera permission denied. Grant permission or enable in App Settings.'
                                          : 'Unable to start camera preview (${error.errorCode.name}).',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (_isPermanentlyDenied)
                                          ElevatedButton.icon(
                                            onPressed: openAppSettings,
                                            icon: const Icon(Icons.settings_rounded, size: 14),
                                            label: const Text('App Settings', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                          )
                                        else
                                          ElevatedButton.icon(
                                            onPressed: _startCamera,
                                            icon: const Icon(Icons.refresh_rounded, size: 14),
                                            label: const Text('Retry Camera', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                          ),
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _cameraErrorMessage = error.errorCode.name;
                                              _isCameraActive = false;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white38),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          child: const Text('Use Presets', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Fallback Simulation / Manual Viewfinder
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                _isTorchOn ? const Color(0xFF334155) : const Color(0xFF1E293B),
                                Colors.black,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSuccessScanned ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                                  size: 44,
                                  color: _isSuccessScanned ? AppColors.success : Colors.white24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isSuccessScanned
                                      ? 'Locked: ${_barcodeController.text}'
                                      : (_cameraErrorMessage != null
                                          ? 'Camera Paused: $_cameraErrorMessage'
                                          : 'Simulation / Manual Input Active'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isSuccessScanned ? AppColors.success : Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _startCamera,
                                  icon: const Icon(Icons.videocam_rounded, size: 14),
                                  label: const Text('Start / Resume Camera', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Targeting Reticle & Viewfinder Corners
                    Container(
                      width: 220,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isSuccessScanned
                              ? AppColors.success
                              : (_barcodeError != null ? AppColors.error : Colors.white70),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // Animated Scanning Laser Line
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Positioned(
                          top: 55 + (_animController.value * 130),
                          left: (MediaQuery.of(context).size.width - 240) / 2,
                          child: Container(
                            width: 200,
                            height: 2,
                            decoration: BoxDecoration(
                              color: _isSuccessScanned ? AppColors.success : const Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSuccessScanned ? AppColors.success : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Top Floating Camera Control Badges
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: _isCameraActive ? 'Pause Camera' : 'Resume Camera',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              _isCameraActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                              size: 16,
                            ),
                            onPressed: () async {
                              if (_isCameraActive) {
                                try {
                                  await _scannerController.stop();
                                } catch (_) {}
                                setState(() {
                                  _isCameraActive = false;
                                  _cameraErrorMessage = null;
                                });
                              } else {
                                _startCamera();
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Fullscreen Scanner',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.fullscreen_rounded, size: 18),
                            onPressed: _openVialFullscreenScanner,
                          ),
                        ],
                      ),
                    ),

                    // Scan Instructions Overlay
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSuccessScanned
                                  ? Icons.check_circle
                                  : Icons.center_focus_strong_rounded,
                              size: 14,
                              color: _isSuccessScanned ? AppColors.success : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isSuccessScanned
                                  ? 'Barcode Detected & Verified!'
                                  : 'Align sterile vial barcode within reticle',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isSuccessScanned ? AppColors.success : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Fullscreen Sheet Scanner Launcher Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openVialFullscreenScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Open High-Precision Fullscreen Scanner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Demo Barcode Trigger Buttons for 1-Click Testing
            Row(
              children: [
                const Text(
                  'Quick Barcode Presets:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _generateRandomBarcode,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Generate New', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPresetChip('SMP-VIR-777'),
                _buildPresetChip('SMP-88390'),
                _buildPresetChip('SMP-91024'),
                _buildPresetChip('SMP-55120'),
                _buildPresetChip('SMP-33041'),
              ],
            ),
            const SizedBox(height: 14),

            // Manual Barcode Input Field
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _barcodeError != null
                      ? AppColors.error
                      : (_isSuccessScanned ? AppColors.success : AppColors.border),
                  width: _barcodeError != null || _isSuccessScanned ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Vial Barcode Number',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      if (_isVerifyingBarcode)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _barcodeController,
                    onChanged: (val) => _applyBarcode(val),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. SMP-88390',
                      isDense: true,
                      border: InputBorder.none,
                      suffixIcon: _barcodeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _barcodeController.clear();
                                setState(() {
                                  _barcodeError = null;
                                  _isSuccessScanned = false;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  if (_barcodeError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _barcodeError!,
                      style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Specimen Tube Type Selection
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specimen Vacutainer Tube Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  ..._vialTypes.map((vial) {
                    final isSelected = _selectedVialType == vial['name'];
                    return InkWell(
                      onTap: () => setState(() => _selectedVialType = vial['name']),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (vial['color'] as Color).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? vial['color'] as Color : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: vial['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vial['name']} (${vial['vol']})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Common tests: ${vial['tests']}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: vial['name'],
                              groupValue: _selectedVialType,
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedVialType = v);
                              },
                              activeColor: vial['color'] as Color,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cold-Chain Temperature Logger
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cold-Box Temperature Log',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _temperatureCelsius >= 2.0 && _temperatureCelsius <= 8.0
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_temperatureCelsius.toStringAsFixed(1)} °C • ${_temperatureCelsius >= 2.0 && _temperatureCelsius <= 8.0 ? "Normal" : "Out of Range"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _temperatureCelsius >= 2.0 && _temperatureCelsius <= 8.0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Clinical threshold: 2.0°C to 8.0°C (WHO Diagnostic Transport Norm)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Slider(
                    value: _temperatureCelsius,
                    min: 1.0,
                    max: 10.0,
                    divisions: 45,
                    label: '${_temperatureCelsius.toStringAsFixed(1)}°C',
                    activeColor: _temperatureCelsius >= 2.0 && _temperatureCelsius <= 8.0
                        ? AppColors.success
                        : AppColors.error,
                    onChanged: (val) => setState(() => _temperatureCelsius = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // On-site Notes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collection & Phlebotomist Notes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Vein drawn smoothly on first attempt. Gel pack ice verified.',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _submitCollection,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  provider.isLoading ? 'Completing Sample...' : '✓ Complete Sample Collection',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String barcode) {
    return ActionChip(
      label: Text(
        barcode,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      onPressed: () => _applyBarcode(barcode),
    );
  }
}
