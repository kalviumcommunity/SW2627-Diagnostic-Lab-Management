import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laboratory Technician Portal - Rack Intake & Analyzers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.infoLight,
                  child: Icon(Icons.inbox_rounded, color: AppColors.info),
                ),
                title: const Text('Incoming Rack Intake', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Scan transit batch couriers and verify accessioning'),
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
