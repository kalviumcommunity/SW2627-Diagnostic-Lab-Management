import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/theme/app_colors.dart';
import '../../backend/models/sla_metric_model.dart';
import '../providers/admin_provider.dart';

class StaffManagementScreen extends StatefulWidget {
  final bool showAppBar;
  const StaffManagementScreen({super.key, this.showAppBar = true});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  UserRole? _filterRole;

  void _showReallocateDialog(BuildContext context, StaffAllocationModel staff) {
    final provider = context.read<AdminProvider>();
    final branches = provider.branches;
    String selectedBranchId = staff.assignedBranchId;
    String selectedBranchName = staff.assignedBranchName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Reallocate ${staff.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Current Branch: ${staff.assignedBranchName} (${staff.assignedBranchId})',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              const Text('Select Destination Branch Hub / Center:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBranchId,
                    isExpanded: true,
                    items: branches.map((b) {
                      return DropdownMenuItem<String>(
                        value: b.id,
                        child: Text('${b.name} (${b.city})', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final b = branches.firstWhere((element) => element.id == val);
                        setModalState(() {
                          selectedBranchId = b.id;
                          selectedBranchName = b.name;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final success = await provider.reallocateStaff(
                      staffId: staff.id,
                      targetBranchId: selectedBranchId,
                      targetBranchName: selectedBranchName,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '${staff.name} reallocated to $selectedBranchName' : 'Reallocation failed'),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirm Reallocation', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: 'STF-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}');
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController(text: '+91 98');
    UserRole selectedRole = UserRole.phlebotomist;
    final branches = context.read<AdminProvider>().branches;
    String selectedBranchId = branches.isNotEmpty ? branches.first.id : 'BR-004';
    String selectedBranchName = branches.isNotEmpty ? branches.first.name : 'Central Diagnostic Hub 4';

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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Register Staff Member',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Staff Full Name *',
                      hintText: 'e.g. Ramesh Chandra',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter staff name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: idController,
                          decoration: const InputDecoration(
                            labelText: 'Staff ID *',
                            hintText: 'e.g. PH-210',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter staff ID' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<UserRole>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: UserRole.phlebotomist, child: Text('Phlebotomist')),
                            DropdownMenuItem(value: UserRole.labTechnician, child: Text('Lab Tech')),
                            DropdownMenuItem(value: UserRole.frontDesk, child: Text('Front Desk')),
                            DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedRole = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Work Email Address *',
                      hintText: 'e.g. ramesh@labtrack.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Phone *',
                      hintText: '+91 98765 00000',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length < 8) ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Branch Hub *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final b = branches.firstWhere((e) => e.id == val);
                        setModalState(() {
                          selectedBranchId = b.id;
                          selectedBranchName = b.name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final member = StaffAllocationModel(
                          id: idController.text.trim(),
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          role: selectedRole,
                          assignedBranchId: selectedBranchId,
                          assignedBranchName: selectedBranchName,
                          isOnDuty: true,
                          todayCompletedTasks: 0,
                          pendingTasks: 0,
                        );
                        final success = await context.read<AdminProvider>().addStaffMember(member);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Staff member "${member.name}" added!' : 'Failed to add staff member'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Register Staff Member', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final allStaff = provider.staffAllocations;
    final staff = _filterRole == null
        ? allStaff
        : allStaff.where((s) => s.role == _filterRole).toList();

    final onDutyCount = allStaff.where((s) => s.isOnDuty).length;
    final phleboCount = allStaff.where((s) => s.role == UserRole.phlebotomist && s.isOnDuty).length;
    final techCount = allStaff.where((s) => s.role == UserRole.labTechnician && s.isOnDuty).length;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fleet Metric Strip
          Row(
            children: [
              Expanded(
                child: _buildFleetMiniStat(
                  title: 'Total Active',
                  value: '$onDutyCount / ${allStaff.length}',
                  icon: Icons.badge_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFleetMiniStat(
                  title: 'Phlebos in Field',
                  value: '$phleboCount active',
                  icon: Icons.vaccines_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFleetMiniStat(
                  title: 'Lab Techs',
                  value: '$techCount on bench',
                  icon: Icons.science_rounded,
                  color: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Role Filter Chips Row & Register Button
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Staff', null),
                      const SizedBox(width: 6),
                      _buildFilterChip('Phlebotomists', UserRole.phlebotomist),
                      const SizedBox(width: 6),
                      _buildFilterChip('Lab Techs', UserRole.labTechnician),
                      const SizedBox(width: 6),
                      _buildFilterChip('Front Desk', UserRole.frontDesk),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.person_add_rounded, size: 20),
                tooltip: 'Add Staff Member',
                onPressed: () => _showAddStaffDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Header
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STAFF ROSTER (${staff.length})',
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

          ...staff.map((s) => _buildStaffCard(context, s)),
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
        title: const Text('Staff & Phlebotomist Fleet Allocation', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Staff Member',
            onPressed: () => _showAddStaffDialog(context),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildFilterChip(String label, UserRole? role) {
    final isSelected = _filterRole == role;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterRole = role),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildFleetMiniStat({
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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

  Widget _buildStaffCard(BuildContext context, StaffAllocationModel member) {
    final Color roleColor;
    final Color roleBg;
    switch (member.role) {
      case UserRole.phlebotomist:
        roleColor = const Color(0xFFD97706);
        roleBg = const Color(0xFFFEF3C7);
        break;
      case UserRole.labTechnician:
        roleColor = const Color(0xFF6366F1);
        roleBg = const Color(0xFFEEF2FF);
        break;
      case UserRole.frontDesk:
        roleColor = AppColors.accent;
        roleBg = AppColors.accentLight;
        break;
      default:
        roleColor = AppColors.primary;
        roleBg = AppColors.primaryLight;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleBg,
                child: Icon(
                  member.role == UserRole.phlebotomist
                      ? Icons.vaccines_rounded
                      : member.role == UserRole.labTechnician
                          ? Icons.science_rounded
                          : Icons.person_rounded,
                  color: roleColor,
                  size: 20,
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
                            member.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            member.role.displayName,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${member.id} • ${member.phoneNumber}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // On Duty Switch
              Column(
                children: [
                  Switch(
                    value: member.isOnDuty,
                    activeColor: roleColor,
                    onChanged: (_) => context.read<AdminProvider>().toggleStaffDuty(member.id),
                  ),
                  Text(
                    member.isOnDuty ? 'On Duty' : 'Off Duty',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: member.isOnDuty ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  member.assignedBranchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showReallocateDialog(context, member),
                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                label: const Text('Reallocate', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tasks Completed: ${member.todayCompletedTasks}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              Text(
                'Queue: ${member.pendingTasks}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 2),
              Text(
                '${member.avgRating}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
