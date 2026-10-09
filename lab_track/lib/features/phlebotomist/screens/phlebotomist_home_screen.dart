
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/phlebotomist_provider.dart';

class PhlebotomistHomeScreen extends StatelessWidget {
  const PhlebotomistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhlebotomistProvider(),
      child: const _PhlebotomistDashboard(),
    );
  }
}

class _PhlebotomistDashboard extends StatelessWidget {
  const _PhlebotomistDashboard();

  static const blue = Color(0xFF0369A1);
  static const background = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhlebotomistProvider>();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LabTrack',
              style: TextStyle(
                fontSize: 13,
                color: blue,
              ),
            ),
            Text(
              'Phlebotomist Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _welcomeCard(provider),
            const SizedBox(height: 20),
            const Text(
              'Collection Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Total',
                    provider.totalCount,
                    Icons.assignment_outlined,
                    const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Pending',
                    provider.pendingCount,
                    Icons.pending_actions,
                    const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Collected',
                    provider.collectedCount,
                    Icons.check_circle_outline,
                    const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Today's Assignments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search patient, sample ID or address',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Pending', 'Collected'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: provider.filter == filter,
                  onSelected: (_) => provider.setFilter(filter),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (provider.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No matching collection tasks found.'),
                ),
              )
            else
              ...provider.tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _taskCard(context, task),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard(PhlebotomistProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF075985)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your collection route',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            '${provider.pendingCount} collections remaining',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verify each patient and label every sample correctly.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _taskCard(BuildContext context, CollectionTask task) {
    final collected = task.status == CollectionStatus.collected;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    task.patientName[0],
                    style: const TextStyle(
                      color: blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.id,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(collected),
              ],
            ),
            const SizedBox(height: 14),
            _detail(Icons.science_outlined, task.testName),
            const SizedBox(height: 8),
            _detail(Icons.location_on_outlined, task.address),
            const SizedBox(height: 8),
            _detail(Icons.access_time, task.collectionTime),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDetails(context, task),
                icon: Icon(
                  collected ? Icons.visibility_outlined : Icons.arrow_forward,
                ),
                label: Text(
                  collected ? 'View Details' : 'Start Collection',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool collected) {
    final color = collected
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: collected
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        collected ? 'Collected' : 'Pending',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, CollectionTask task) {
    final provider = context.read<PhlebotomistProvider>();
    final collected = task.status == CollectionStatus.collected;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        bool patientVerified = false;
        bool sampleCollected = false;
        bool sampleLabelled = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canConfirm = patientVerified &&
                sampleCollected &&
                sampleLabelled;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.patientName,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${task.id} • ${task.testName}'),
                    const Divider(height: 28),
                    _detail(Icons.phone_outlined, task.phone),
                    const SizedBox(height: 10),
                    _detail(Icons.location_on_outlined, task.address),
                    const SizedBox(height: 20),
                    const Text(
                      'Collection verification',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: patientVerified,
                      title: const Text('Patient identity verified'),
                      onChanged: collected
                          ? null
                          : (value) => setSheetState(
                                () => patientVerified = value ?? false,
                              ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: sampleCollected,
                      title: const Text('Sample collected'),
                      onChanged: collected
                          ? null
                          : (value) => setSheetState(
                                () => sampleCollected = value ?? false,
                              ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: sampleLabelled,
                      title: const Text('Sample labelled correctly'),
                      onChanged: collected
                          ? null
                          : (value) => setSheetState(
                                () => sampleLabelled = value ?? false,
                              ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: collected || !canConfirm
                            ? null
                            : () {
                                provider.markCollected(task);
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${task.id} marked as collected',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          collected
                              ? 'Sample already collected'
                              : 'Confirm collection',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
