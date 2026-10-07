import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/order_model.dart';
import '../../../shared/theme/app_colors.dart';
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

class _ScanVialScreenState extends State<ScanVialScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _barcodeController;
  final TextEditingController _notesController = TextEditingController();

  OrderModel? _currentOrder;
  String _selectedVialType = 'Purple Top (K2 EDTA)';
  double _temperatureCelsius = 4.0;
  bool _isTorchOn = false;
  bool _isVerifyingBarcode = false;
  String? _barcodeError;
  bool _isSuccessScanned = false;

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
    _currentOrder = widget.order;
    _barcodeController = TextEditingController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
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
    _barcodeController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
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
      latitude: 28.4595,
      longitude: 77.0266,
      locationAddress: _currentOrder!.collectionAddress,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      phlebotomistId: user?.id ?? 'PH-204',
      phlebotomistName: user?.name ?? 'Rahul Verma',
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
            onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
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
                          value: _currentOrder?.id,
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
                                _currentOrder = pendingOrders.firstWhere((o) => o.id == val);
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

            // Scanner Viewfinder Card
            Container(
              height: 240,
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
                    // Camera Simulation Background
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
                          top: 50 + (_animController.value * 130),
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
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  provider.isLoading ? 'Binding Specimen...' : 'Confirm & Bind Sterile Sample',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
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
