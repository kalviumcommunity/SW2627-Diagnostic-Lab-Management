import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';

class FrontDeskHomeScreen extends StatelessWidget {
  const FrontDeskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Front-Desk Instant Lookup & Dispatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Portal / Role',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accentLight,
                    child: const Icon(Icons.desk_rounded, color: AppColors.accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Priya Sharma',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Front Desk Executive • ${user?.assignedBranchId ?? "Spoke Branch 01"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Switch Role', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.search_rounded, color: AppColors.primary),
                ),
                title: const Text('Instant Report & Patient Search', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Search by patient name, phone, or barcode to eliminate manual paper slips'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.successLight,
                  child: Icon(Icons.print_rounded, color: AppColors.success),
                ),
                title: const Text('Thermal Barcode & Label Dispatch', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Generate sterile barcode stickers for walk-in patient test requisitions'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
