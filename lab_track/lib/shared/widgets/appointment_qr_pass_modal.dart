import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/order_model.dart';
import '../../data/services/central_data_store.dart';
import '../../data/services/cross_tab_sync.dart';
import '../../domain/enums/order_status.dart';
import '../theme/app_colors.dart';

/// Interactive Digital Appointment QR Pass for Patients
/// Shown when booking is confirmed, from Past Bookings, or from Live Track screen.
/// Designed for field phlebotomist doorstep verification with instant mutual real-time confirmation.
class AppointmentQrPassModal extends StatefulWidget {
  final OrderModel order;

  const AppointmentQrPassModal({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppointmentQrPassModal(order: order),
    );
  }

  @override
  State<AppointmentQrPassModal> createState() => _AppointmentQrPassModalState();
}

class _AppointmentQrPassModalState extends State<AppointmentQrPassModal>
    with SingleTickerProviderStateMixin {
  late OrderModel _currentOrder;
  bool _isVerified = false;
  DateTime? _verifiedAt;
  Timer? _autoDismissTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  void Function(Map<String, dynamic>)? _crossTabListener;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _checkVerificationStatus(_currentOrder);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to store updates
    CentralDataStore.instance.addListener(_onStoreChanged);

    // Listen to real-time cross-tab broadcasts
    _crossTabListener = (data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      final payload = data['payload'] as Map<String, dynamic>?;
      if (type == 'doorstep_verified' && payload != null) {
        final orderId = payload['orderId']?.toString();
        if (orderId != null &&
            (orderId.toUpperCase() == _currentOrder.id.toUpperCase() ||
                payload['patientId'] == _currentOrder.patientId)) {
          _triggerVerifiedCelebration(
            DateTime.tryParse(payload['verifiedAt']?.toString() ?? '') ?? DateTime.now(),
          );
        }
      }
    };
    CrossTabSync.addListener(_crossTabListener!);

    // Check store in case it was already verified
    _syncWithStore();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    if (_crossTabListener != null) {
      CrossTabSync.removeListener(_crossTabListener!);
    }
    CentralDataStore.instance.removeListener(_onStoreChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _syncWithStore();
  }

  void _syncWithStore() {
    final storeOrders = CentralDataStore.instance.orders;
    final match = storeOrders.firstWhere(
      (o) =>
          o.id.toUpperCase() == _currentOrder.id.toUpperCase() ||
          (o.patientId == _currentOrder.patientId &&
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.cancelled),
      orElse: () => _currentOrder,
    );

    if (match != _currentOrder) {
      setState(() {
        _currentOrder = match;
      });
      _checkVerificationStatus(match);
    }
  }

  void _checkVerificationStatus(OrderModel order) {
    if (order.doorstepVerifiedAt != null ||
        (order.status == OrderStatus.inProgress && order.sampleBarcodes.isNotEmpty)) {
      if (!_isVerified) {
        _triggerVerifiedCelebration(order.doorstepVerifiedAt ?? DateTime.now());
      }
    }
  }

  void _triggerVerifiedCelebration(DateTime timestamp) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isVerified = true;
      _verifiedAt = timestamp;
    });

    // Auto dismiss after 4 seconds of celebratory feedback
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload =
        'LABTRACK:APPOINTMENT:${_currentOrder.id}:${_currentOrder.patientId}:${_currentOrder.patientName}';

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
                  gradient: _isVerified
                      ? AppColors.emeraldTealGradient
                      : AppColors.cyanTealGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.glowShadow(
                    _isVerified ? AppColors.success : AppColors.primary,
                    opacity: 0.25,
                  ),
                ),
                child: Icon(
                  _isVerified ? Icons.verified_user_rounded : Icons.qr_code_2_rounded,
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
                      _isVerified
                          ? 'Doorstep Identity Verified!'
                          : 'Doorstep Verification Pass',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _isVerified
                          ? 'Sterile specimen collection in progress'
                          : 'Show this QR code to Phlebotomist upon arrival',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isVerified ? AppColors.successDark : Colors.grey.shade600,
                        fontWeight: _isVerified ? FontWeight.w600 : FontWeight.normal,
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

          // Main Card: Either Celebratory Success Card OR Live Real QR Code
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
            child: _isVerified
                ? _buildVerifiedCelebrationCard()
                : _buildQrScannerTargetCard(qrPayload),
          ),
          const SizedBox(height: 18),

          // Footer Security Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isVerified ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isVerified ? Icons.security_rounded : Icons.shield_outlined,
                  size: 18,
                  color: _isVerified ? AppColors.success : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isVerified
                        ? 'Chain-of-Custody logged: Patient identity authenticated by Phlebotomist ${_currentOrder.assignedPhlebotomistName ?? "Praveen"}.'
                        : 'Phlebotomist ${_currentOrder.assignedPhlebotomistName ?? "Praveen"} will scan this QR to unlock sterile needle & vial binding.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _isVerified ? const Color(0xFF065F46) : const Color(0xFF334155),
                      height: 1.3,
                      fontWeight: _isVerified ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isVerified ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isVerified ? 'Done / Back to Home' : 'Done / Close Pass',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Celebratory Card displayed when Phlebotomist scans the patient's pass
  Widget _buildVerifiedCelebrationCard() {
    final timeStr = _verifiedAt != null
        ? DateFormat('hh:mm a').format(_verifiedAt!)
        : DateFormat('hh:mm a').format(DateTime.now());

    return Container(
      key: const ValueKey('verified_card'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
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
          // Animated Glowing Checkmark Icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: AppColors.glowShadow(AppColors.success, opacity: 0.4),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Celebratory Title
          const Text(
            '✓ Identity Authenticated',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF14532D),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Phlebotomist ${_currentOrder.assignedPhlebotomistName ?? "Praveen"} has verified your identity at doorstep.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF166534),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // Metadata Badge
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
                    const Text('ORDER ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '#${_currentOrder.id}',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('VERIFIED AT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 2),
                    const Text(
                      'DRAWING...',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFD97706)),
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

  /// Active QR Code Display with Real Pure-Dart Scannable QR Matrix
  Widget _buildQrScannerTargetCard(String qrPayload) {
    return Container(
      key: const ValueKey('qr_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Patient Name Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Verified Patient: ${_currentOrder.patientName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real, Camera-Scannable QR Code using qr_flutter
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
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Order ID & Pulsing Radar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Waiting for Phlebotomist to scan...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Order ID: #${_currentOrder.id} • Slot: ${_currentOrder.timeSlot}',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
