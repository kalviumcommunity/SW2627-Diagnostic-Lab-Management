import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../../data/services/cross_tab_sync.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../shared/theme/app_colors.dart';

/// Digital Cold-Box Batch Handover QR Pass
/// Presented by Phlebotomist Praveen to Lab Tech Aryan at Central Reference Lab reception.
class ColdBoxHandoverQrModal extends StatefulWidget {
  final List<SampleModel> samples;
  final double coldBoxTemp;
  final String phlebotomistName;
  final String phlebotomistId;

  const ColdBoxHandoverQrModal({
    super.key,
    required this.samples,
    required this.coldBoxTemp,
    this.phlebotomistName = 'Praveen',
    this.phlebotomistId = 'PH-PRAVEEN',
  });

  static Future<void> show(
    BuildContext context, {
    required List<SampleModel> samples,
    required double coldBoxTemp,
    String phlebotomistName = 'Praveen',
    String phlebotomistId = 'PH-PRAVEEN',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ColdBoxHandoverQrModal(
        samples: samples,
        coldBoxTemp: coldBoxTemp,
        phlebotomistName: phlebotomistName,
        phlebotomistId: phlebotomistId,
      ),
    );
  }

  @override
  State<ColdBoxHandoverQrModal> createState() => _ColdBoxHandoverQrModalState();
}

class _ColdBoxHandoverQrModalState extends State<ColdBoxHandoverQrModal>
    with SingleTickerProviderStateMixin {
  bool _isHandedOver = false;
  String _receiverName = 'Lab Tech Aryan (#LAB-ARYAN)';
  DateTime? _handedOverAt;
  Timer? _autoDismissTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    CentralDataStore.instance.addListener(_checkHandoverStatus);

    CrossTabSync.init((data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      final payload = data['payload'] as Map<String, dynamic>?;
      if (type == 'sample_accessioned' && payload != null) {
        final barcode = payload['barcode']?.toString();
        if (barcode != null && widget.samples.any((s) => s.barcode.toUpperCase() == barcode.toUpperCase())) {
          _triggerHandoverCelebration(payload['technicianName']?.toString() ?? 'Lab Tech Aryan (#LAB-ARYAN)');
        }
      }
    });

    _checkHandoverStatus();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    CentralDataStore.instance.removeListener(_checkHandoverStatus);
    _pulseController.dispose();
    super.dispose();
  }

  void _checkHandoverStatus() {
    if (!mounted) return;
    final storeSamples = CentralDataStore.instance.samples;
    final targetBarcodes = widget.samples.map((s) => s.barcode.toUpperCase()).toSet();

    final matched = storeSamples.where((s) => targetBarcodes.contains(s.barcode.toUpperCase())).toList();
    if (matched.isNotEmpty &&
        matched.any((s) =>
            s.status == SampleStatus.receivedAtLab ||
            s.status == SampleStatus.processing ||
            s.currentCustodianId == 'LAB-ARYAN')) {
      if (!_isHandedOver) {
        _triggerHandoverCelebration('Lab Tech Aryan (#LAB-ARYAN)');
      }
    }
  }

  void _triggerHandoverCelebration(String receiver) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isHandedOver = true;
      _receiverName = receiver;
      _handedOverAt = DateTime.now();
    });

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final barcodesCsv = widget.samples.map((s) => s.barcode).join(',');
    final qrPayload =
        'LABTRACK:HANDOVER:${widget.phlebotomistId}:${widget.phlebotomistName}:${widget.coldBoxTemp.toStringAsFixed(1)}:$barcodesCsv';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: _isHandedOver
                      ? AppColors.emeraldTealGradient
                      : AppColors.purpleIndigoGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.glowShadow(
                    _isHandedOver ? AppColors.success : const Color(0xFF7C3AED),
                    opacity: 0.25,
                  ),
                ),
                child: Icon(
                  _isHandedOver ? Icons.handshake_rounded : Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHandedOver
                          ? 'Custody Handover Confirmed!'
                          : 'Cold-Box Lab Handover Pass',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      _isHandedOver
                          ? 'Received by $_receiverName'
                          : 'Show this pass to Lab Tech Aryan for accessioning',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isHandedOver ? AppColors.successDark : Colors.grey.shade600,
                        fontWeight: _isHandedOver ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Card: Either Celebratory Success Card OR Scannable Batch QR Code
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isHandedOver
                ? _buildCelebrationCard()
                : _buildQrPassCard(qrPayload),
          ),
          const SizedBox(height: 18),

          // Bottom Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHandedOver ? AppColors.success : const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isHandedOver ? 'Done / Back to Cold Box' : 'Close Handover Pass',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCard() {
    return Container(
      key: const ValueKey('handover_celebration'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF86EFAC), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: AppColors.glowShadow(AppColors.success, opacity: 0.4),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '✓ Custody Transferred',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF14532D)),
          ),
          const SizedBox(height: 6),
          Text(
            'All ${widget.samples.length} specimens accessioned into Central Laboratory by $_receiverName.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('VIALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.samples.length} Tubes',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('TEMPERATURE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.coldBoxTemp.toStringAsFixed(1)}°C INTACT',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    const Text(
                      'Apex Central',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF7C3AED)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPassCard(String qrPayload) {
    return Container(
      key: const ValueKey('handover_qr_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custody Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Text(
                  '${widget.samples.length} Vials • ${widget.coldBoxTemp.toStringAsFixed(1)}°C Cold Chain',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF7C3AED)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real Camera-Scannable QR Code using qr_flutter
          Container(
            width: 210,
            height: 210,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF4C1D95),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1E1B4B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Receiver notice
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ready for Lab Tech Aryan to scan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sample chips preview
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: widget.samples.take(4).map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  s.barcode,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

