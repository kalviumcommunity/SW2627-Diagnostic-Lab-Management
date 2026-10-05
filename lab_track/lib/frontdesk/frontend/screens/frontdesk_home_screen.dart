import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class FrontDeskHomeScreen extends StatelessWidget {
  const FrontDeskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Front-Desk Instant Lookup & Dispatch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
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
          ],
        ),
      ),
    );
  }
}
