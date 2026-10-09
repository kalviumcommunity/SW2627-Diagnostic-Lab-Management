import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../backend/models/walk_in_requisition_request.dart';
import '../../backend/models/thermal_label_model.dart';
import '../providers/frontdesk_provider.dart';
import '../widgets/thermal_sticker_card.dart';

class ThermalBarcodeDispatchScreen extends StatefulWidget {
  const ThermalBarcodeDispatchScreen({super.key});

  @override
  State<ThermalBarcodeDispatchScreen> createState() => _ThermalBarcodeDispatchScreenState();
}

class _ThermalBarcodeDispatchScreenState extends State<ThermalBarcodeDispatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _gender = 'Female';
  String _priority = 'Routine'; // 'Routine' or 'Urgent STAT'

  final List<String> _availableTests = [
    'Complete Blood Count (CBC)',
    'HbA1c Glycated Hemoglobin',
    'Thyroid Panel (T3, T4, TSH)',
    'Lipid Profile Comprehensive',
    'Liver Function Test (LFT)',
    'Kidney Function Test (KFT)',
    'Fasting Blood Sugar (FBS)',
    'Postprandial Blood Sugar (PPBS)',
    'Serum Electrolytes (Na, K, Cl)',
    'Dengue NS1 Antigen & Ab',
    'Coagulation PT / INR',
  ];

  final Set<String> _selectedTests = {'Complete Blood Count (CBC)'};
  List<ThermalLabelModel>? _justGeneratedLabels;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillDemoPatient() {
    setState(() {
      _nameController.text = 'Sunita Rao';
      _phoneController.text = '+91 98711 22334';
      _ageController.text = '34';
      _gender = 'Female';
      _addressController.text = 'Flat 202, Royal Palms, DLF Phase 2';
      _priority = 'Routine';
      _selectedTests.clear();
      _selectedTests.addAll([
        'Complete Blood Count (CBC)',
        'Thyroid Panel (T3, T4, TSH)',
        'Fasting Blood Sugar (FBS)',
      ]);
    });
  }

  // Determine required tubes based on selected tests
  Map<String, List<String>> _computeRequiredTubes() {
    final Map<String, List<String>> tubes = {};
    for (final test in _selectedTests) {
      final t = test.toLowerCase();
      if (t.contains('cbc') || t.contains('hba1c') || t.contains('hemoglobin') || t.contains('esr')) {
        tubes.putIfAbsent('Purple Top (K2 EDTA) • 3.0 mL', () => []).add(test);
      } else if (t.contains('glucose') || t.contains('sugar') || t.contains('ppbs') || t.contains('fbs')) {
        tubes.putIfAbsent('Grey Top (Sodium Fluoride) • 2.0 mL', () => []).add(test);
      } else if (t.contains('coagulation') || t.contains('pt') || t.contains('inr')) {
        tubes.putIfAbsent('Light Blue (Sodium Citrate) • 2.7 mL', () => []).add(test);
      } else {
        tubes.putIfAbsent('Gold Top (SST Serum Gel) • 5.0 mL', () => []).add(test);
      }
    }
    return tubes;
  }

  Future<void> _submitRequisition() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one diagnostic test.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final request = WalkInRequisitionRequest(
      patientName: _nameController.text.trim(),
      patientPhone: _phoneController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 30,
      gender: _gender,
      address: _addressController.text.trim(),
      selectedTestNames: _selectedTests.toList(),
      priority: _priority,
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      clinicalNotes: _notesController.text.trim(),
    );

    final provider = context.read<FrontDeskProvider>();
    final labels = await provider.submitWalkInRequisition(request);

    if (labels != null && mounted) {
      setState(() {
        _justGeneratedLabels = labels;
      });
      // Switch to preview tab
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontDeskProvider>();
    final recentLabels = provider.recentLabels;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thermal Barcode & Label Dispatch'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.note_add_rounded, size: 20), text: 'Walk-In Requisition'),
            Tab(icon: Icon(Icons.print_rounded, size: 20), text: 'Thermal Label Spooler'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Requisition Entry Form
              _buildRequisitionFormTab(provider),

              // Tab 2: Thermal Labels Spooler & Preview
              _buildLabelSpoolerTab(provider, recentLabels),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequisitionFormTab(FrontDeskProvider provider) {
    final tubes = _computeRequiredTubes();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Banner: Fast Walk-In Registration
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_printshop_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sterile Barcode Sticker Generation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Direct walk-in counter registration & instant 50x25mm vial thermal label dispatch.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fillDemoPatient,
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Auto-Fill Demo', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient Demographics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Walk-In Patient Demographics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Name & Phone
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Patient Full Name *',
                            hintText: 'e.g. Sunita Rao',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Enter patient name' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number *',
                            hintText: '+91 98765 00000',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                          validator: (v) =>
                              v == null || v.trim().length < 10 ? 'Enter 10-digit phone' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Age & Gender
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age *',
                            hintText: '34',
                            prefixIcon: Icon(Icons.cake_outlined, size: 20),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Enter age' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _gender = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Order Priority
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Order Priority',
                      prefixIcon: Icon(Icons.priority_high_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Routine', child: Text('Routine Collection')),
                      DropdownMenuItem(value: 'Urgent STAT', child: Text('Urgent STAT (High Priority)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Residential Address / Area',
                      hintText: 'e.g. Sector 18, Gurugram',
                      prefixIcon: Icon(Icons.home_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Diagnostic Tests Selection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.biotech_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Select Requisition Test Panels',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_selectedTests.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTests.map((test) {
                      final isSelected = _selectedTests.contains(test);
                      return FilterChip(
                        label: Text(test),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTests.add(test);
                            } else {
                              _selectedTests.remove(test);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Real-Time Sterile Tube Allocation Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vaccines_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'AUTOMATED VACUUM CONTAINER ALLOCATION (${tubes.length} Vials Required)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (tubes.isEmpty)
                    const Text('Select tests above to compute sterile tube requirements.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tubes.entries.map((entry) {
                        Color capColor = const Color(0xFF7E22CE);
                        if (entry.key.contains('Gold')) capColor = const Color(0xFFD97706);
                        if (entry.key.contains('Grey')) capColor = const Color(0xFF475569);
                        if (entry.key.contains('Blue')) capColor = const Color(0xFF0284C7);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: capColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting ? null : _submitRequisition,
                icon: provider.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded, size: 20),
                label: Text(
                  provider.isSubmitting
                      ? 'Generating Sterile Barcodes...'
                      : 'Generate Barcode Stickers & Create Order',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelSpoolerTab(
    FrontDeskProvider provider,
    List<ThermalLabelModel> recentLabels,
  ) {
    final labelsToDisplay = _justGeneratedLabels ?? recentLabels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Spooler Action Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Print (${labelsToDisplay.length} Stickers)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Connected: Zebra ZD410 (USB / Desk Spooler 01)',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: provider.isPrinting
                      ? null
                      : () async {
                          final ok = await provider.printThermalLabels(labelsToDisplay);
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thermal stickers dispatched to printer successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                  icon: provider.isPrinting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.print_rounded, size: 16),
                  label: Text(
                    provider.isPrinting ? 'Printing...' : 'Print All Stickers',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Label Stickers Grid/List
          if (labelsToDisplay.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('No barcode stickers generated yet. Complete a walk-in requisition.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: labelsToDisplay.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final label = labelsToDisplay[index];
                return ThermalStickerCard(
                  label: label,
                  onPrintSingle: () async {
                    await provider.printThermalLabels([label]);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Printed label for vial ${label.barcode}'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
