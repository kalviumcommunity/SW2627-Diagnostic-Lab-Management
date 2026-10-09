import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sample_model.dart';
import '../../../shared/theme/app_colors.dart';

class CustodyTimelineModal extends StatelessWidget {
  final SampleModel sample;

  const CustodyTimelineModal({super.key, required this.sample});

  static void show(BuildContext context, SampleModel sample) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustodyTimelineModal(sample: sample),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = sample.events;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 680,
      ),
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chain of Custody Tracking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Vial Barcode: ${sample.barcode} • ${sample.vialType}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Sample Overview Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient: ${sample.patientName}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tests: ${sample.testNames.join(", ")}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sample.status.shortLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stepper / Timeline
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text('No recorded milestones for this sample yet.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isLast = index == events.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Milestone Indicator & Line
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isLast ? AppColors.primary : AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: isLast ? Colors.white : AppColors.primary,
                                  ),
                                ),
                                if (index < events.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: AppColors.border,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Event Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event.status.displayName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('hh:mm a').format(event.timestamp),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${event.actorName} • ${event.locationName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (event.temperatureCelsius != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.ac_unit_rounded, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Cool-Chain Log: ${event.temperatureCelsius}°C',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        event.notes!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
