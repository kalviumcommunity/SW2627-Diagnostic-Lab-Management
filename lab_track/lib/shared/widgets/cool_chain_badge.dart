import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// God-Level Cold-Chain Telemetry Badge
/// Displays live IoT specimen temperature with safety threshold color coding.
class CoolChainBadge extends StatelessWidget {
  final double? temperature;
  final String? overrideText;
  final bool compact;

  const CoolChainBadge({
    super.key,
    this.temperature,
    this.overrideText,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final temp = temperature ?? 4.2;
    final isSafe = temp >= 2.0 && temp <= 8.0;
    final isWarning = temp > 8.0 && temp <= 12.0;

    final Color color = isSafe
        ? AppColors.successDark
        : (isWarning ? AppColors.warningDark : AppColors.errorDark);

    final Color bgColor = isSafe
        ? AppColors.successLight
        : (isWarning ? AppColors.warningLight : AppColors.errorLight);

    final String label = overrideText ??
        (isSafe
            ? '${temp.toStringAsFixed(1)}°C (Safe 2-8°C)'
            : (isWarning ? '${temp.toStringAsFixed(1)}°C (Elevated)' : '${temp.toStringAsFixed(1)}°C (Breach)'));

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '${temp.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ac_unit_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
