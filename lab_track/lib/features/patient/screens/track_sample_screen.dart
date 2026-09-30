import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrackSampleScreen extends StatefulWidget {
  final String? initialBarcode;
  const TrackSampleScreen({super.key, this.initialBarcode});

  @override
  State<TrackSampleScreen> createState() => _TrackSampleScreenState();
}

class _TrackSampleScreenState extends State<TrackSampleScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _activeBarcode;

  @override
  void initState() {
    super.initState();
    _activeBarcode = widget.initialBarcode ?? 'SMP-88390';
    _searchController.text = _activeBarcode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchSample() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _activeBarcode = query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chain of Custody Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search / Barcode Input Bar
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
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: _searchSample,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Sample Summary Card
            _buildSampleOverviewCard(),
            const SizedBox(height: 24),

            // Detailed Chain of Custody Timeline
            const Text(
              'Digital Chain of Custody',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Immutable live audit trail from home collection to Central Lab.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            _buildTimeline(),
            const SizedBox(height: 24),

            // Lab Assistance card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 36, color: AppColors.primaryDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Have questions about your sample?',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Contact Central Diagnostic Hub helpline for instant live status support.',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                      'Sample ID: $_activeBarcode',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tests: Thyroid Panel & HbA1c',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.directions_bike_rounded, size: 14, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'In Transit',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoBlock(label: 'Assigned Phlebotomist', val: 'Rajeev Sharma'),
                const SizedBox(width: 16),
                _buildInfoBlock(label: 'Destination Hub', val: 'Central Lab Hub 4'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBlock(label: 'Vial Type', val: 'EDTA (Purple) + Serum'),
                const SizedBox(width: 16),
                _buildInfoBlock(label: 'Est. Report Time', val: 'Today, 06:00 PM'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock({required String label, required String val}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineTile(
          title: 'Sample Collected at Home',
          subtitle: 'Phlebotomist Rajeev scanned barcode and packaged vial into cold storage bag.',
          time: 'Today, 08:15 AM',
          actor: 'Phlebotomist: Rajeev Sharma (#PHL-102)',
          isCompleted: true,
          isActive: false,
          isFirst: true,
        ),
        _buildTimelineTile(
          title: 'Dispatched to Central Hub in Transit',
          subtitle: 'Sample transferred to temperature-controlled transit batch #TR-402.',
          time: 'Today, 09:30 AM',
          actor: 'Courier Handover: Sector 14 Unit',
          isCompleted: true,
          isActive: true,
        ),
        _buildTimelineTile(
          title: 'Incoming Scan at Diagnostic Lab',
          subtitle: 'Lab technician verifies vial integrity, checks barcodes, and puts into rack.',
          time: 'Estimated ~ 11:30 AM',
          actor: 'Central Lab Reception Desk',
          isCompleted: false,
          isActive: false,
        ),
        _buildTimelineTile(
          title: 'Clinical Analysis & Testing',
          subtitle: 'Automated immunoassay and biochemistry analysis.',
          time: 'Estimated ~ 02:30 PM',
          actor: 'Department of Biochemistry',
          isCompleted: false,
          isActive: false,
        ),
        _buildTimelineTile(
          title: 'Pathologist Verification & Digital Report Release',
          subtitle: 'Verified digital report available immediately for patient & front-desk view.',
          time: 'Estimated ~ 06:00 PM',
          actor: 'Chief Pathologist',
          isCompleted: false,
          isActive: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required String time,
    required String actor,
    required bool isCompleted,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color nodeColor;
    IconData nodeIcon;

    if (isCompleted && !isActive) {
      nodeColor = AppColors.success;
      nodeIcon = Icons.check;
    } else if (isActive) {
      nodeColor = AppColors.warning;
      nodeIcon = Icons.access_time_filled_rounded;
    } else {
      nodeColor = AppColors.border;
      nodeIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line & node
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(nodeIcon, size: 14, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.warningLight.withValues(alpha: 0.4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppColors.warning : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isActive ? AppColors.warning : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          actor,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
