import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/sample_model.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/frontdesk_provider.dart';
import '../widgets/report_modal.dart';
import '../widgets/custody_timeline_modal.dart';

class InstantSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const InstantSearchScreen({super.key, this.initialQuery});

  @override
  State<InstantSearchScreen> createState() => _InstantSearchScreenState();
}

class _InstantSearchScreenState extends State<InstantSearchScreen> {
  late TextEditingController _searchController;

  final List<String> _quickQueries = [
    'John Doe',
    '+91 98765 43210',
    'ORD-84210',
    'SMP-88390',
    'Meena Gupta',
    'Rajesh Sharma',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FrontDeskProvider>();
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        provider.setSearchQuery(widget.initialQuery!);
      } else {
        provider.refreshSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    context.read<FrontDeskProvider>().setSearchQuery(query);
  }

  void _applyQuickQuery(String query) {
    _searchController.text = query;
    _onQueryChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontDeskProvider>();
    final results = provider.searchResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Instant Report & Patient Search'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Card
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by patient name, phone, order ID, or barcode...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onQueryChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Search Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'Quick Lookup: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          ..._quickQueries.map((q) {
                            final isSelected = _searchController.text.trim().toLowerCase() == q.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(q),
                                onPressed: () => _applyQuickQuery(q),
                                backgroundColor: isSelected ? AppColors.primaryLight : AppColors.background,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(provider, 'all', 'All Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip(provider, 'ready', 'Report Ready (Printable)'),
                      const SizedBox(width: 8),
                      _buildFilterChip(provider, 'processing', 'In Lab Testing'),
                      const SizedBox(width: 8),
                      _buildFilterChip(provider, 'inTransit', 'In Transit / Hub'),
                    ],
                  ),
                ),
              ),

              // Results Count / Status Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${results.length} patient order(s) found',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (provider.isSearching)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                  ],
                ),
              ),

              // Search Results List
              Expanded(
                child: results.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return _buildSearchResultCard(context, item, provider);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(FrontDeskProvider provider, String filterKey, String label) {
    final isSelected = provider.searchFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setSearchFilter(filterKey),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    dynamic item,
    FrontDeskProvider provider,
  ) {
    final order = item.order;
    final List<SampleModel> samples = item.samples;
    final hasReady = item.hasReadyReport;
    final primaryReport = item.primaryReport;
    final SampleStatus aggStatus = item.aggregateStatus;

    Color statusBg = AppColors.primaryLight;
    Color statusColor = AppColors.primary;
    IconData statusIcon = Icons.inventory_2_outlined;

    if (hasReady || aggStatus == SampleStatus.reportReady) {
      statusBg = AppColors.successLight;
      statusColor = AppColors.success;
      statusIcon = Icons.verified_rounded;
    } else if (aggStatus == SampleStatus.processing) {
      statusBg = AppColors.infoLight;
      statusColor = AppColors.info;
      statusIcon = Icons.biotech_rounded;
    } else if (aggStatus == SampleStatus.inTransit || aggStatus == SampleStatus.receivedAtBranch) {
      statusBg = AppColors.warningLight;
      statusColor = AppColors.warning;
      statusIcon = Icons.local_shipping_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Patient Info & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accentLight,
                  child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.patientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            order.patientPhone,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${order.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        hasReady ? 'Report Ready' : aggStatus.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tests Requested
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: order.testNames.map<Widget>((test) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    test,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Vials / Barcodes Section
            if (samples.isNotEmpty) ...[
              const Text(
                'COLLECTION VIALS & BARCODES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: samples.map((sample) {
                  return InkWell(
                    onTap: () => CustodyTimelineModal.show(context, sample),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            sample.barcode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sample.status.shortLabel,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Meta Info: Date & Branch
            Row(
              children: [
                Icon(Icons.business_rounded, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  order.branchName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.schedule_rounded, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(order.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
            const Divider(height: 20),

            // Actions Row
            Row(
              children: [
                // View custody timeline
                if (samples.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => CustodyTimelineModal.show(context, samples.first),
                    icon: const Icon(Icons.timeline_rounded, size: 15),
                    label: const Text('Custody Timeline', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                const Spacer(),

                // Print Receipt Slip
                TextButton.icon(
                  onPressed: () async {
                    await provider.printRequisitionSlip(order);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Receipt slip printed for Order #${order.id}'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_rounded, size: 15),
                  label: const Text('Print Slip', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),

                // View & Print Report
                if (primaryReport != null)
                  ElevatedButton.icon(
                    onPressed: () => ReportModal.show(
                      context,
                      report: primaryReport,
                      patientName: order.patientName,
                      patientPhone: order.patientPhone,
                    ),
                    icon: const Icon(Icons.description_rounded, size: 15),
                    label: Text(
                      hasReady ? 'View & Print Report' : 'Draft Report',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasReady ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Specimen is currently under laboratory analysis.'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    icon: const Icon(Icons.hourglass_top_rounded, size: 15),
                    label: const Text('In Testing', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.border,
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Orders Matched',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a patient mobile number, order ID (e.g. ORD-84210), or vial barcode (SMP-88390).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
