import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BookCollectionScreen extends StatefulWidget {
  const BookCollectionScreen({super.key});

  @override
  State<BookCollectionScreen> createState() => _BookCollectionScreenState();
}

class _BookCollectionScreenState extends State<BookCollectionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _addressController = TextEditingController(text: 'Apartment 4B, Sunrise Residency, Sector 14');
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '07:00 AM - 08:30 AM (Fasting)';
  String _selectedBranch = 'Central Diagnostic Lab - Sector 5';

  final List<Map<String, dynamic>> _availableTests = [
    {
      'id': 'cbc',
      'name': 'Complete Blood Count (CBC)',
      'price': 350,
      'fasting': false,
      'selected': true,
    },
    {
      'id': 'lipid',
      'name': 'Lipid Profile',
      'price': 650,
      'fasting': true,
      'selected': true,
    },
    {
      'id': 'thyroid',
      'name': 'Thyroid Panel (T3, T4, TSH)',
      'price': 550,
      'fasting': false,
      'selected': false,
    },
    {
      'id': 'hba1c',
      'name': 'HbA1c (Diabetes Glycated Hemoglobin)',
      'price': 450,
      'fasting': false,
      'selected': false,
    },
    {
      'id': 'vit_d_b12',
      'name': 'Vitamin D & B12 Combo',
      'price': 1200,
      'fasting': true,
      'selected': false,
    },
  ];

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

  int get _totalAmount {
    return _availableTests
        .where((test) => test['selected'] == true)
        .fold<int>(0, (sum, test) => sum + (test['price'] as int));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirmBooking() {
    if (!_formKey.currentState!.validate()) return;

    final selectedTests = _availableTests.where((t) => t['selected'] == true).toList();
    if (selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one test for home collection'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID: #$orderId',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'A phlebotomist from $_selectedBranch has been assigned. You will receive real-time notifications when they are en route.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹$_totalAmount', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking #$orderId created successfully')),
                );
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Home Sample Collection'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.primaryDark, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Samples collected in pre-barcoded sterile vials with temperature-controlled cold transit boxes.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Tests Selection
              const Text(
                '1. Select Required Tests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ..._availableTests.map((test) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: test['selected'] as bool,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        test['selected'] = val ?? false;
                      });
                    },
                    title: Text(
                      test['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        Text('₹${test['price']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        if (test['fasting'] == true) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '10-12h Fasting',
                              style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Section 2: Date & Slot
              const Text(
                '2. Preferred Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Collection Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            icon: const Icon(Icons.edit_calendar, size: 16),
                            label: const Text('Change Date'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text('Available Time Slots', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSlot = slot);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Patient & Address Details
              const Text(
                '3. Patient Information & Home Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Patient Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (val) => val == null || val.isEmpty ? 'Please enter patient name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.isEmpty ? 'Please enter phone number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Home Address', prefixIcon: Icon(Icons.location_on_outlined)),
                        maxLines: 2,
                        validator: (val) => val == null || val.isEmpty ? 'Please enter collection address' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Processing Hub',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                        items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBranch = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Special Notes / Landmarks (Optional)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          hintText: 'e.g. Near Community Center, Elderly patient',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Order Summary and CTA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Home Collection Fee:', style: TextStyle(color: AppColors.textSecondary)),
                        const Text('FREE', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Estimated Cost:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('₹$_totalAmount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmBooking,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirm Home Booking'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
