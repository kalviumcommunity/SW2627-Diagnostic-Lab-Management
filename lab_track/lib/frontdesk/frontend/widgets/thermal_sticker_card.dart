import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../backend/models/thermal_label_model.dart';
import 'barcode_widget.dart';

class ThermalStickerCard extends StatelessWidget {
  final ThermalLabelModel label;
  final VoidCallback? onPrintSingle;

  const ThermalStickerCard({
    super.key,
    required this.label,
    this.onPrintSingle,
  });

  @override
  Widget build(BuildContext context) {
    final capColor = Color(label.vialColorValue);
    final isStat = label.priority.toLowerCase().contains('stat') ||
        label.priority.toLowerCase().contains('urgent');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cap Color Banner / Tube Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: capColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label.vialType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label.volumeRequired,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticker Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Patient Name & Stat Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label.patientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isStat)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'STAT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    else
                      Text(
                        label.patientAgeGender,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Order: ${label.orderId} • ${label.branchId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),

                // Barcode Visualization
                Center(
                  child: BarcodeWidget(
                    code: label.barcode,
                    height: 38,
                    width: 220,
                    showText: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Tests Listed
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: label.testNames.map((test) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        test,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Footer with timestamp & print status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(label.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                    if (label.isPrinted)
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Dispatched / Printed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    else if (onPrintSingle != null)
                      InkWell(
                        onTap: onPrintSingle,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.print_rounded, size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Print Sticker',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
