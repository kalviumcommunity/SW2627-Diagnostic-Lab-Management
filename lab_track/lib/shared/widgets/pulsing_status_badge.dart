import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../enums/sample_status.dart';

/// God-Level Pulsing Status Badge with glowing breathing wave animation
/// and ultra-crisp micro-typography.
class PulsingStatusBadge extends StatefulWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool isPulsing;
  final double fontSize;

  const PulsingStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.isPulsing = true,
    this.fontSize = 11.0,
  });

  /// Factory constructor for SampleStatus
  factory PulsingStatusBadge.fromSampleStatus(SampleStatus status, {bool isPulsing = true}) {
    Color color;
    IconData icon;

    switch (status) {
      case SampleStatus.booked:
        color = const Color(0xFF64748B);
        icon = Icons.schedule_rounded;
        break;
      case SampleStatus.phlebotomistAssigned:
        color = AppColors.primary;
        icon = Icons.person_pin_circle_rounded;
        break;
      case SampleStatus.collected:
        color = const Color(0xFF0D9488);
        icon = Icons.vaccines_rounded;
        break;
      case SampleStatus.inTransit:
        color = AppColors.warning;
        icon = Icons.local_shipping_rounded;
        break;
      case SampleStatus.receivedAtBranch:
        color = const Color(0xFF0284C7);
        icon = Icons.archive_rounded;
        break;
      case SampleStatus.inTransitToCentralLab:
        color = const Color(0xFFD97706);
        icon = Icons.local_shipping_rounded;
        break;
      case SampleStatus.receivedAtLab:
        color = const Color(0xFF7C3AED);
        icon = Icons.inbox_rounded;
        break;
      case SampleStatus.processing:
        color = const Color(0xFF8B5CF6);
        icon = Icons.science_rounded;
        break;
      case SampleStatus.reportReady:
        color = const Color(0xFF059669);
        icon = Icons.assignment_turned_in_rounded;
        break;
      case SampleStatus.delivered:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case SampleStatus.rejected:
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
    }

    return PulsingStatusBadge(
      label: status.displayName,
      color: color,
      icon: icon,
      isPulsing: isPulsing && (status != SampleStatus.delivered && status != SampleStatus.rejected && status != SampleStatus.reportReady),
    );
  }

  @override
  State<PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<PulsingStatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? widget.color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isPulsing)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _glowAnimation.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: _glowAnimation.value * 0.7),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            )
          else if (widget.icon != null)
            Icon(widget.icon, size: 13, color: widget.color)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              color: widget.color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
