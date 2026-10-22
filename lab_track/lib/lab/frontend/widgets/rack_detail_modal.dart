import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/universal_qr_scanner_modal.dart';
import '../../backend/models/lab_rack_model.dart';
import '../providers/lab_provider.dart';

/// Interactive modal visualizing analyzer specimen racks with tube wells.
class RackDetailModal extends StatefulWidget {
  final LabRackModel rack;

  const RackDetailModal({super.key, required this.rack});

  @override
  State<RackDetailModal> createState() => _RackDetailModalState();
}

class _RackDetailModalState extends State<RackDetailModal> {
  final _barcodeController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _addSampleToRack() async {
    final barcode = _barcodeController.text.trim().toUpperCase();
    if (barcode.isEmpty) return;

    setState(() => _isAdding = true);
    final success = await context.read<LabProvider>().assignToRack(
          barcode: barcode,
          rackId: widget.rack.id,
        );

    if (!mounted) return;
    setState(() => _isAdding = false);

    if (success) {
      _barcodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sample $barcode loaded into ${widget.rack.name}.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Color _getCapColor(String department) {
    switch (department.toLowerCase()) {
      case 'hematology':
        return const Color(0xFF7C3AED); // Purple EDTA
      case 'biochemistry':
        return const Color(0xFFEAB308); // Gold/Yellow SST
      case 'clinical pathology':
        return const Color(0xFF10B981); // Green Heparin
      case 'immunology':
        return const Color(0xFF0284C7); // Sky Blue
      default:
        return const Color(0xFF6B7280); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final capColor = _getCapColor(widget.rack.department);
    final count = widget.rack.currentCount;
    final total = widget.rack.capacity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                      color: capColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.grid_view_rounded, color: capColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rack.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.rack.department} • ${widget.rack.analyzerName}',
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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Rack Capacity Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RACK OCCUPANCY: $count / $total VIALS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.rack.status == 'in_analyzer' ? AppColors.infoLight : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.rack.status == 'in_analyzer' ? 'RUNNING IN ANALYZER' : 'LOADING BATCH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: widget.rack.status == 'in_analyzer' ? AppColors.info : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: widget.rack.occupancyRate,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(capColor),
                ),
              ),
              const SizedBox(height: 20),

              // Visual Rack Well Matrix (6 columns x rows)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final isOccupied = index < count;
                    final barcode = isOccupied ? widget.rack.sampleBarcodes[index] : null;

                    return Tooltip(
                      message: isOccupied ? 'Well #${index + 1}: $barcode' : 'Well #${index + 1}: Empty Slot',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOccupied ? capColor : Colors.white,
                          border: Border.all(
                            color: isOccupied ? capColor : AppColors.border,
                            width: 2,
                          ),
                          boxShadow: isOccupied
                              ? [
                                  BoxShadow(
                                    color: capColor.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isOccupied ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Barcode Insertion Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter/Scan Vial Barcode (e.g. SMP-77401)',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                          tooltip: 'Scan Tube Barcode',
                          onPressed: () async {
                            final code = await UniversalQrScannerModal.show(
                              context,
                              title: 'Scan Tube into Rack',
                              hint: 'Scan specimen vial barcode to assign directly into rack well',
                            );
                            if (code != null && code.isNotEmpty) {
                              _barcodeController.text = code;
                              _addSampleToRack();
                            }
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isAdding || widget.rack.isFull ? null : _addSampleToRack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: capColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isAdding
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Slot Vial', style: TextStyle(fontWeight: FontWeight.w700)),
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
