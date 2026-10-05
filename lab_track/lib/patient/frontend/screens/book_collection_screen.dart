import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../backend/models/patient_booking_request.dart';
import '../../backend/models/patient_test_catalog.dart';
import '../providers/patient_provider.dart';

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

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
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

    // Initialize from PatientTestCatalog (Backend)
    _tests = PatientTestCatalog.availableTests.map((t) {
      return {
        'id': t.id,
        'name': t.name,
        'price': t.price,
        'fasting': t.requiresFasting,
        'selected': t.id == 'cbc' || t.id == 'lipid',
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
    return _tests
        .where((t) => t['selected'] == true)
        .fold<double>(0.0, (sum, t) => sum + (t['price'] as int).toDouble());
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedTests = _tests.where((t) => t['selected'] == true).toList();
    if (selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one diagnostic test.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    final patientId = user?.id ?? 'PT-84210';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Booking Confirmed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: #${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Assigned Branch: ${order.branchName}'),
              const SizedBox(height: 4),
              Text('Slot: ${DateFormat('dd MMM yyyy').format(order.scheduledDate)} | ${order.timeSlot}'),
              const SizedBox(height: 12),
              const Text(
                'A certified phlebotomist will arrive with sterile vials and temperature-monitored cooler.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('View Active Track'),
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
        title: const Text('Book Home Sample Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test selection card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Diagnostic Tests',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ..._tests.map((test) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            test['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '₹${test['price']} • ${test['fasting'] ? '10-12h Fasting' : 'No Fasting'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: test['fasting'] ? AppColors.warning : AppColors.textSecondary,
                            ),
                          ),
                          value: test['selected'],
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => test['selected'] = val ?? false);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date & Time Slot
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferred Slot & Branch',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedSlot,
                        decoration: const InputDecoration(labelText: 'Time Slot'),
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
                        decoration: const InputDecoration(labelText: 'Diagnostic Branch'),
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
              ),

              const SizedBox(height: 16),

              // Patient details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient & Address Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Patient Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Collection Address'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Special Notes (Optional)'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Total & Book Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          '₹${_totalAmount.toInt()}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: patientProvider.isLoading ? null : _confirmBooking,
                      child: patientProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm & Schedule'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
