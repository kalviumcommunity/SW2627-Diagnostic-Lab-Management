import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class PhlebotomistHomeScreen extends StatelessWidget {
  const PhlebotomistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phlebotomist Portal - Pickups & Custody'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.warningLight,
                  child: Icon(Icons.qr_code_scanner_rounded, color: AppColors.warning),
                ),
                title: const Text('Scan & Bind Vial Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Affix sterile barcodes and record cool-chain temperature'),
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
