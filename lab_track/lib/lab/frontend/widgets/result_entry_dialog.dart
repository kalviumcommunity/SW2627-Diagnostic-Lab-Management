import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/lab_provider.dart';

/// Modal dialog for entering and editing analytical laboratory results.
class ResultEntryDialog extends StatefulWidget {
  final SampleModel sample;
  final ReportModel? existingReport;

  const ResultEntryDialog({
    super.key,
    required this.sample,
    this.existingReport,
  });

  @override
  State<ResultEntryDialog> createState() => _ResultEntryDialogState();
}

class _ResultEntryDialogState extends State<ResultEntryDialog> {
  late List<_ParameterRowController> _controllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initParameters();
  }

  void _initParameters() {
    if (widget.existingReport != null && widget.existingReport!.testResults.isNotEmpty) {
      _controllers = widget.existingReport!.testResults.map((p) {
        return _ParameterRowController(
          name: p.name,
          value: p.value,
          unit: p.unit ?? '',
          range: p.range,
          flag: p.flag,
        );
      }).toList();
    } else {
      // Default to CBC template or Metabolic Panel based on test name
      final testName = widget.sample.testNames.isNotEmpty
          ? widget.sample.testNames.first
          : 'Complete Blood Count (CBC)';

      if (testName.toLowerCase().contains('lipid') || testName.toLowerCase().contains('cholesterol')) {
        _controllers = [
          _ParameterRowController(name: 'Total Cholesterol', value: '185', unit: 'mg/dL', range: '< 200', flag: 'Normal'),
          _ParameterRowController(name: 'Triglycerides', value: '142', unit: 'mg/dL', range: '< 150', flag: 'Normal'),
          _ParameterRowController(name: 'HDL (Good Cholesterol)', value: '45', unit: 'mg/dL', range: '> 40', flag: 'Normal'),
          _ParameterRowController(name: 'LDL (Bad Cholesterol)', value: '112', unit: 'mg/dL', range: '< 100', flag: 'High'),
        ];
      } else if (testName.toLowerCase().contains('glucose') || testName.toLowerCase().contains('sugar')) {
        _controllers = [
          _ParameterRowController(name: 'Fasting Blood Glucose', value: '96', unit: 'mg/dL', range: '70 - 100', flag: 'Normal'),
          _ParameterRowController(name: 'HbA1c Glycated Hemoglobin', value: '5.6', unit: '%', range: '< 5.7', flag: 'Normal'),
        ];
      } else {
        // Complete Blood Count (CBC)
        _controllers = [
          _ParameterRowController(name: 'Hemoglobin', value: '14.2', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          _ParameterRowController(name: 'Total Leukocyte Count (WBC)', value: '7,800', unit: '/uL', range: '4,000 - 11,000', flag: 'Normal'),
          _ParameterRowController(name: 'Platelet Count', value: '250,000', unit: '/uL', range: '150,000 - 450,000', flag: 'Normal'),
          _ParameterRowController(name: 'Packed Cell Volume (PCV)', value: '42.0', unit: '%', range: '40.0 - 50.0', flag: 'Normal'),
          _ParameterRowController(name: 'Neutrophils', value: '62', unit: '%', range: '40 - 70', flag: 'Normal'),
          _ParameterRowController(name: 'Lymphocytes', value: '30', unit: '%', range: '20 - 40', flag: 'Normal'),
        ];
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCustomParameter() {
    setState(() {
      _controllers.add(_ParameterRowController(
        name: 'New Test Parameter',
        value: '0.0',
        unit: 'mg/dL',
        range: '0.0 - 10.0',
        flag: 'Normal',
      ));
    });
  }

  void _saveResults() async {
    setState(() => _isSaving = true);

    final parameters = _controllers.map((c) {
      return ReportParameter(
        name: c.nameController.text.trim(),
        value: c.valueController.text.trim(),
        unit: c.unitController.text.trim(),
        range: c.rangeController.text.trim(),
        flag: c.flag,
      );
    }).toList();

    final testName = widget.sample.testNames.isNotEmpty
        ? widget.sample.testNames.first
        : 'Diagnostic Panel';

    final success = await context.read<LabProvider>().enterTestResults(
          sampleBarcode: widget.sample.barcode,
          parameters: parameters,
          testName: testName,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test results saved for ${widget.sample.barcode}. Forwarded for Pathologist review.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: Color(0xFF7C3AED), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Analytical Findings • ${widget.sample.barcode}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.sample.patientName} • ${widget.sample.testNames.join(", ")}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

              // Table Column Headers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: Text('TEST PARAMETER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text('OBSERVED VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                    Expanded(flex: 1, child: Text('UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text('REF RANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                    SizedBox(width: 70, child: Text('FLAG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Parameter Rows List
              Expanded(
                child: ListView.separated(
                  itemCount: _controllers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = _controllers[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: c.nameController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: c.valueController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: c.unitController,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: c.rangeController,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: c.flag,
                            isDense: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'Normal', child: Text('Normal', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700))),
                              DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w700))),
                              DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => c.flag = val);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Action Toolbar
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _addCustomParameter,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Parameter Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save & Submit for Sign-Off', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _ParameterRowController {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController rangeController;
  String flag;

  _ParameterRowController({
    required String name,
    required String value,
    required String unit,
    required String range,
    required this.flag,
  })  : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value),
        unitController = TextEditingController(text: unit),
        rangeController = TextEditingController(text: range);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
    rangeController.dispose();
  }
}
