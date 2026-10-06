import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';

class PhlebotomistHomeScreen extends StatelessWidget {
  const PhlebotomistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phlebotomist - Pickups & Custody'),
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
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: const Icon(Icons.vaccines_rounded, color: Color(0xFFD97706), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Rahul Verma',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Field Phlebotomist • ID: ${user?.id ?? "PH-204"}',
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
                  backgroundColor: AppColors.warningLight,
                  child: Icon(Icons.qr_code_scanner_rounded, color: AppColors.warning),
                ),
                title: const Text('Scan & Bind Vial Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Affix sterile barcodes and record cool-chain temperature on-site'),
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
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.route_rounded, color: AppColors.primary),
                ),
                title: const Text('Today\'s Doorstep Route & Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('View patient home addresses, time slots, and fasting prerequisites'),
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
