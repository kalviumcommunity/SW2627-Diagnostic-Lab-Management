import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../backend/models/patient_booking_request.dart';
import '../../backend/models/patient_test_catalog.dart';
import '../providers/patient_provider.dart';

/// God-Level Home Specimen Collection Booking Screen
class BookCollectionScreen extends StatefulWidget {
  const BookCollectionScreen({super.key});

  @override
  State<BookCollectionScreen> createState() => _BookCollectionScreenState();
}

class _BookCollectionScreenState extends State<BookCollectionScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final TextEditingController _notesController = TextEditingController();

  late List<Map<String, dynamic>> _tests;

  final DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '07:00 AM - 08:30 AM (Fasting)';
  String _selectedBranch = 'Central Diagnostic Lab - Sector 5';

  final List<String> _timeSlots = [
    '07:00 AM - 08:30 AM (Fasting)',
    '08:30 AM - 10:00 AM (Fasting)',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  final List<String> _branches = [
    'Central Diagnostic Lab - Sector 5',
    'Apollo Hub Diagnostic Center',
    'Metro City Branch',
    'South Park Specialized Lab',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? 'John Doe');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '+91 98765 43210');
    _addressController = TextEditingController(
      text: user?.address ?? 'Apartment 4B, Sunrise Residency, Sector 14',
    );

    _tests = PatientTestCatalog.availableTests.map((t) {
      return {
        'id': t.id,
        'name': t.name,
        'price': t.price,
        'fasting': t.requiresFasting,
        'description': t.description,
        'selected': t.id == 'test_cbc' || t.id == 'test_thyroid',
      };
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _tests.where((t) => t['selected'] == true).fold(0.0, (sum, t) => sum + (t['price'] as num).toDouble());
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedTests = _tests.where((t) => t['selected'] == true).toList();
    if (selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one diagnostic test to proceed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final patientId = authProvider.currentUser?.id ?? 'PT-84210';

    final request = PatientBookingRequest(
      patientId: patientId,
      patientName: _nameController.text.trim(),
      patientPhone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      selectedTestNames: selectedTests.map((t) => t['name'].toString()).toList(),
      totalAmount: _totalAmount,
      scheduledDate: _selectedDate,
      timeSlot: _selectedSlot,
      branchName: _selectedBranch,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final patientProvider = context.read<PatientProvider>();
    final order = await patientProvider.createBooking(request);

    if (!mounted) return;

    if (order != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: #${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Assigned Hub: ${order.branchName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'Slot: ${DateFormat('dd MMM yyyy').format(order.scheduledDate)} • ${order.timeSlot}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.ac_unit_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A certified phlebotomist with temperature-monitored IoT cool box is assigned.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Track Sample Live'),
            ),
          ],
        ),
      );
    } else if (patientProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patientProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Schedule Home Specimen Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cold chain & phlebotomy assurance banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanTealGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.glowShadow(AppColors.accent, opacity: 0.22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '100% Sterile & Cold-Chain Assured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Vacuum needle collection, barcode printed at doorstep, 2°C - 8°C IoT box.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Test Selection Section
              GodLevelCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Diagnostic Tests',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_tests.where((t) => t['selected'] == true).length} Selected',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._tests.map((test) {
                      final isSelected = test['selected'] as bool;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() => test['selected'] = !isSelected);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0FDF4) : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.success : AppColors.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() => test['selected'] = val ?? false);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        test['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${test['price']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: test['fasting'] ? AppColors.warningLight : AppColors.successLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              test['fasting'] ? '10-12h Fasting' : 'Random / Non-Fasting',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: test['fasting'] ? AppColors.warningDark : AppColors.successDark,
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
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferred Slot & Hub
              GodLevelCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferred Time Slot & Hub',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedSlot,
                      decoration: const InputDecoration(labelText: 'Pickup Window Slot'),
                      items: _timeSlots
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSlot = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedBranch,
                      decoration: const InputDecoration(labelText: 'Assigned Diagnostic Hub'),
                      items: _branches
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranch = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Patient Info
              GodLevelCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient & Doorstep Address',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Patient Full Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Doorstep Address', prefixIcon: Icon(Icons.home_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Phlebotomist Special Instructions (Optional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Total & Book Button
              GodLevelCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                hasGlow: true,
                glowColor: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL ESTIMATED AMOUNT',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_totalAmount.toInt()}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: patientProvider.isLoading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        shadowColor: AppColors.primaryGlow,
                        elevation: 4,
                      ),
                      child: patientProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              children: const [
                                Icon(Icons.check_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Confirm & Dispatch',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
