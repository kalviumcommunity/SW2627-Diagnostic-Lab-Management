import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class BranchManagementScreen extends StatefulWidget {
  final bool showAppBar;
  const BranchManagementScreen({super.key, this.showAppBar = true});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddBranchDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: 'BR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController(text: 'Delhi NCR');
    final phoneController = TextEditingController(text: '+91 ');
    bool hasLab = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_business_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Register New Branch Hub',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Hub Name *',
                      hintText: 'e.g. West Delhi Central Processing Center',
                      prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter branch name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: idController,
                          decoration: const InputDecoration(
                            labelText: 'Branch Code / ID *',
                            hintText: 'e.g. BR-008',
                            prefixIcon: Icon(Icons.tag_rounded, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter branch ID' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City / Region *',
                            hintText: 'e.g. Gurugram',
                            prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Full Physical Address *',
                      hintText: 'Building, Sector, Road, Pin Code',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter street address' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Reception Helpline *',
                      hintText: '+91 98765 00000',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid phone' : null,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: hasLab,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: const Text('Equipped with Central Analytical Testing Lab', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Uncheck if this is a collection-only spoke center', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    onChanged: (val) => setModalState(() => hasLab = val ?? true),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final branch = BranchModel(
                          id: idController.text.trim(),
                          name: nameController.text.trim(),
                          address: addressController.text.trim(),
                          city: cityController.text.trim(),
                          hasTestingLab: hasLab,
                          phoneNumber: phoneController.text.trim(),
                        );
                        final success = await context.read<AdminProvider>().addBranch(branch);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Branch "${branch.name}" successfully registered!' : 'Failed to register branch.'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Confirm & Save Branch Hub', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final branches = provider.branches.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.city.toLowerCase().contains(q) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    final testingLabsCount = provider.branches.where((b) => b.hasTestingLab).length;
    final spokeCentersCount = provider.branches.length - testingLabsCount;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network Topology Stats Strip
          Row(
            children: [
              Expanded(
                child: _buildTopologyMiniStat(
                  title: 'Total Hubs',
                  value: '${provider.branches.length}',
                  icon: Icons.hub_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopologyMiniStat(
                  title: 'Testing Labs',
                  value: '$testingLabsCount',
                  icon: Icons.biotech_rounded,
                  color: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopologyMiniStat(
                  title: 'Spoke Centers',
                  value: '$spokeCentersCount',
                  icon: Icons.storefront_rounded,
                  color: AppColors.accent,
                  bgColor: AppColors.accentLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar & Add Button Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search branches by city, ID, or name...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddBranchDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Hub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section Title
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NETWORK BRANCH ROSTER (${branches.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (branches.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 10),
                  Text(
                    'No branches match "$_searchQuery"',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text('Try adjusting your search query or clear the filter.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ...branches.map((b) => _buildBranchCard(context, b)),

          const SizedBox(height: 24),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Multi-Branch Custody Topology', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Add Branch Hub',
            onPressed: () => _showAddBranchDialog(context),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildTopologyMiniStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, BranchModel branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: branch.hasTestingLab ? const Color(0xFFEEF2FF) : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  branch.hasTestingLab ? Icons.biotech_rounded : Icons.storefront_rounded,
                  color: branch.hasTestingLab ? const Color(0xFF6366F1) : AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            branch.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: branch.hasTestingLab ? const Color(0xFFEEF2FF) : AppColors.accentLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            branch.hasTestingLab ? 'Central Lab' : 'Collection Spoke',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: branch.hasTestingLab ? const Color(0xFF6366F1) : AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${branch.id} • ${branch.city}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  branch.address,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                branch.phoneNumber,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Custody Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
