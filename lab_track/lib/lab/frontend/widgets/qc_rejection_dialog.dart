import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/sample_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/lab_provider.dart';

/// Pre-analytical Quality Control (QC) Rejection Dialog.
class QcRejectionDialog extends StatefulWidget {
  final SampleModel sample;

  const QcRejectionDialog({super.key, required this.sample});

  @override
  State<QcRejectionDialog> createState() => _QcRejectionDialogState();
}

class _QcRejectionDialogState extends State<QcRejectionDialog> {
  String _selectedReason = 'Hemolyzed (Free Hb > 500 mg/dL)';
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = const [
    'Hemolyzed (Free Hb > 500 mg/dL)',
    'Micro-clots in EDTA Tube',
    'Insufficient Specimen Volume (< 1.5 mL)',
    'Lipemic / High Turbidity Serum',
    'Specimen Tube Damaged in Courier Transit',
    'Mislabeled / Barcode Unreadable',
    'Incorrect Anticoagulant Tube Used',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitRejection() async {
    setState(() => _isSubmitting = true);

    final success = await context.read<LabProvider>().recordQcRejection(
          barcode: widget.sample.barcode,
          reason: _selectedReason,
          clinicalNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Specimen ${widget.sample.barcode} flagged as REJECTED. Recollection workflow dispatched.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Flag Pre-Analytical Specimen Failure',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vial #${widget.sample.barcode} • ${widget.sample.patientName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Recollection Warning Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.autorenew_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rejecting this specimen triggers an automatic Recollection Task for the branch and notifies the patient and front desk.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Reason Selector
              const Text('PRIMARY REJECTION ROOT CAUSE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    items: _reasons.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Clinical Notes
              const Text('OBSERVATIONS / BENCH NOTES (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Visual inspection post centrifugation revealed strawberry-pink plasma indicative of erythrocyte hemolysis.',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitRejection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('Confirm Rejection & Recollect', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
