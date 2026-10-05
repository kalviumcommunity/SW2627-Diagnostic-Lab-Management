import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../providers/patient_provider.dart';

class TrackSampleScreen extends StatefulWidget {
  final String? initialBarcode;
  const TrackSampleScreen({super.key, this.initialBarcode});

  @override
  State<TrackSampleScreen> createState() => _TrackSampleScreenState();
}

class _TrackSampleScreenState extends State<TrackSampleScreen> {
  final TextEditingController _searchController = TextEditingController();
  SampleModel? _searchedSample;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialBarcode ?? 'SMP-88390';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchSample() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    final patientProvider = context.read<PatientProvider>();
    final result = await patientProvider.trackSample(query);

    if (!mounted) return;
    setState(() {
      _searchedSample = result;
      _isSearching = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No sample found matching barcode "$query"'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final sample = _searchedSample ?? patientProvider.activeSample;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chain of Custody Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcode search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Sample Barcode (e.g. SMP-88390)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _searchSample(),
                    ),
                  ),
                  _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: AppColors.primary),
                          onPressed: _searchSample,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (sample != null) ...[
              _buildOverviewCard(sample),
              const SizedBox(height: 24),
              const Text(
                'Digital Chain of Custody Audit Trail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cryptographically logged milestones from home pickup to Central Lab.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildTimeline(sample),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No active sample data available.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(SampleModel sample) {
    return Card(
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
                    Text(
                      sample.testNames.isNotEmpty ? sample.testNames.first : 'Diagnostic Panel',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text('Barcode: #${sample.barcode}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sample.status.displayName,
                    style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.ac_unit_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  sample.temperatureStatus ?? '2°C - 8°C (Normal)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  sample.currentBranchName ?? 'In Transit',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(SampleModel sample) {
    if (sample.events.isEmpty) {
      return const Text('No milestones logged yet.');
    }

    return Column(
      children: sample.events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == sample.events.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isLast ? AppColors.warning : AppColors.success,
                  child: Icon(
                    isLast ? Icons.navigation : Icons.check,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.status.displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.locationName} • ${DateFormat('hh:mm a').format(event.timestamp)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (event.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.notes!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
