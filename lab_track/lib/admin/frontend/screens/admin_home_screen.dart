import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostic Admin - SLA & TAT Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.accentLight,
                  child: Icon(Icons.speed_rounded, color: AppColors.accent),
                ),
                title: const Text('SLA Turnaround Time Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Monitor branch transit bottlenecks and daily sample processing quotas'),
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
