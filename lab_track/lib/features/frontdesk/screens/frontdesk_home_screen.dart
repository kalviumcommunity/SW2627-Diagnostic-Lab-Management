
import 'package:flutter/material.dart';

class FrontdeskHomeScreen extends StatefulWidget {
  const FrontdeskHomeScreen({super.key});

  @override
  State<FrontdeskHomeScreen> createState() =>
      _FrontdeskHomeScreenState();
}

class _FrontdeskHomeScreenState extends State<FrontdeskHomeScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'All';

  final List<LabSample> _samples = [
    LabSample(
      id: 'SMP-1001',
      patientName: 'Rahul Sharma',
      phone: '9876543210',
      testName: 'CBC + Blood Sugar',
      branch: 'Jaipur Central',
      collectedAt: '09 Oct 2026, 10:00 AM',
      status: SampleStatus.inTransit,
    ),
    LabSample(
      id: 'SMP-1002',
      patientName: 'Priya Mehta',
      phone: '9876543211',
      testName: 'Thyroid Profile',
      branch: 'Malviya Nagar',
      collectedAt: '09 Oct 2026, 11:30 AM',
      status: SampleStatus.processing,
    ),
    LabSample(
      id: 'SMP-1003',
      patientName: 'Amit Singh',
      phone: '9876543212',
      testName: 'Lipid Profile',
      branch: 'Jaipur Central',
      collectedAt: '09 Oct 2026, 09:15 AM',
      status: SampleStatus.reportReady,
    ),
    LabSample(
      id: 'SMP-1004',
      patientName: 'Neha Verma',
      phone: '9876543213',
      testName: 'Liver Function Test',
      branch: 'Vaishali Nagar',
      collectedAt: '09 Oct 2026, 12:15 PM',
      status: SampleStatus.collected,
    ),
  ];

  List<LabSample> get _filteredSamples {
    final query = _searchController.text.trim().toLowerCase();

    return _samples.where((sample) {
      final matchesSearch =
          sample.patientName.toLowerCase().contains(query) ||
          sample.id.toLowerCase().contains(query) ||
          sample.phone.contains(query) ||
          sample.testName.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        'Collected' => sample.status == SampleStatus.collected,
        'In Transit' => sample.status == SampleStatus.inTransit,
        'Processing' => sample.status == SampleStatus.processing,
        'Report Ready' => sample.status == SampleStatus.reportReady,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _count(SampleStatus status) =>
      _samples.where((sample) => sample.status == status).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LABTRACK',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Front Desk',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 21,
                fontWeight: FontWeight.bold,
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
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 22),
            const Text(
              'Sample Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'In Transit',
                    _count(SampleStatus.inTransit),
                    Icons.local_shipping_outlined,
                    const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Processing',
                    _count(SampleStatus.processing),
                    Icons.biotech_outlined,
                    const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Reports Ready',
                    _count(SampleStatus.reportReady),
                    Icons.description_outlined,
                    const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Find a Sample or Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search by patient name, sample ID, phone or test.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. SMP-1001 or Rahul Sharma',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Collected',
                  'In Transit',
                  'Processing',
                  'Report Ready',
                ].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sample Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredSamples.length} found',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_filteredSamples.isEmpty)
              _buildEmptyState()
            else
              ..._filteredSamples.map(
                (sample) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _sampleCard(sample),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0369A1),
            Color(0xFF0F766E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Welcome to your workspace',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Every sample, easy to find.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track samples across branches and quickly locate report status.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
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
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleCard(LabSample sample) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showSampleDetails(sample),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    sample.patientName[0],
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
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
                        sample.patientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sample.id,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(sample.status),
              ],
            ),
            const SizedBox(height: 14),
            _detailRow(
              Icons.science_outlined,
              sample.testName,
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.account_tree_outlined,
              sample.branch,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Color(0xFF0369A1),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'View sample details',
                    style: TextStyle(
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(SampleStatus status) {
    late final String label;
    late final Color foreground;
    late final Color background;

    switch (status) {
      case SampleStatus.collected:
        label = 'Collected';
        foreground = const Color(0xFF475569);
        background = const Color(0xFFF1F5F9);
      case SampleStatus.inTransit:
        label = 'In Transit';
        foreground = const Color(0xFFB45309);
        background = const Color(0xFFFEF3C7);
      case SampleStatus.processing:
        label = 'Processing';
        foreground = const Color(0xFF1D4ED8);
        background = const Color(0xFFDBEAFE);
      case SampleStatus.reportReady:
        label = 'Report Ready';
        foreground = const Color(0xFF047857);
        background = const Color(0xFFD1FAE5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off,
            size: 45,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'No matching records',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different patient name, sample ID or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showSampleDetails(LabSample sample) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sample Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    sample.id,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow(
                    Icons.person_outline,
                    sample.patientName,
                  ),
                  const SizedBox(height: 13),
                  _detailRow(
                    Icons.phone_outlined,
                    sample.phone,
                  ),
                  const SizedBox(height: 13),
                  _detailRow(
                    Icons.science_outlined,
                    sample.testName,
                  ),
                  const SizedBox(height: 13),
                  _detailRow(
                    Icons.account_tree_outlined,
                    sample.branch,
                  ),
                  const SizedBox(height: 13),
                  _detailRow(
                    Icons.schedule,
                    sample.collectedAt,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes,
                        color: Color(0xFF0369A1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusDescription(sample.status),
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (sample.status == SampleStatus.reportReady)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF047857),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Report is ready. Report viewing and delivery can be connected to the report module.',
                              style: TextStyle(
                                color: Color(0xFF065F46),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusDescription(SampleStatus status) {
    switch (status) {
      case SampleStatus.collected:
        return 'Sample collected. Awaiting branch transit update.';
      case SampleStatus.inTransit:
        return 'Sample is on its way to the assigned lab branch.';
      case SampleStatus.processing:
        return 'Sample has reached the lab and is being processed.';
      case SampleStatus.reportReady:
        return 'The report is marked ready in this demo record.';
    }
  }
}

enum SampleStatus {
  collected,
  inTransit,
  processing,
  reportReady,
}

class LabSample {
  LabSample({
    required this.id,
    required this.patientName,
    required this.phone,
    required this.testName,
    required this.branch,
    required this.collectedAt,
    required this.status,
  });

  final String id;
  final String patientName;
  final String phone;
  final String testName;
  final String branch;
  final String collectedAt;
  final SampleStatus status;
}
