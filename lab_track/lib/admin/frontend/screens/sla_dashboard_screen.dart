import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../backend/models/sla_metric_model.dart';
import '../providers/admin_provider.dart';

class SlaDashboardScreen extends StatelessWidget {
  final bool showAppBar;
  const SlaDashboardScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final slaMetrics = provider.slaMetrics;
    final rejections = provider.rejectionCauses;
    final branchPerfs = provider.branchPerformances;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          _buildSlaHeaderBanner(context, provider),
          const SizedBox(height: 16),

          // Filters Row
          _buildFiltersRow(context, provider),
          const SizedBox(height: 20),

          // Section 1: Diagnostic Test TAT vs SLA
          _buildSectionHeader(
            title: 'DIAGNOSTIC TEST TAT VS SLA TARGETS',
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          ...slaMetrics.map((m) => _buildTestSlaCard(context, m)),
          const SizedBox(height: 20),

          // Section 2: Branch SLA & Throughput Rankings
          _buildSectionHeader(
            title: 'BRANCH THROUGHPUT & SLA COMPLIANCE RANKING',
            accentColor: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),
          ...branchPerfs.map((b) => _buildBranchPerformanceCard(context, b)),
          const SizedBox(height: 20),

          // Section 3: Specimen Rejection Root-Causes Breakdown
          _buildSectionHeader(
            title: 'SPECIMEN REJECTION & RE-DRAW ROOT CAUSES',
            accentColor: AppColors.error,
          ),
          const SizedBox(height: 10),
          _buildRejectionBreakdownCard(context, rejections),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (!showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SLA Turnaround Time Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader({required String title, required Color accentColor}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSlaHeaderBanner(BuildContext context, AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turnaround Time (TAT) Compliance',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '96.8% On-Target',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'NABH / NABL Compliant',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _BannerStat(label: 'Network Target SLA', value: '4.0 hrs max'),
              _BannerStat(label: 'Avg Actual TAT', value: '3.2 hrs'),
              _BannerStat(label: 'Breached Tests', value: '1 of 6'),
              _BannerStat(label: 'Rejection Rate', value: '0.42% (Low)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, AdminProvider provider) {
    return Row(
      children: [
        // Time Filter Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedTimeFilter,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
              items: const [
                DropdownMenuItem(value: 'Today', child: Text('Filter: Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DropdownMenuItem(value: 'Last 7 Days', child: Text('Filter: Last 7 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DropdownMenuItem(value: 'This Month', child: Text('Filter: This Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
              onChanged: (val) {
                if (val != null) provider.setTimeFilter(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Branch Filter Chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedBranchFilter,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                items: [
                  const DropdownMenuItem(value: 'All Branches', child: Text('Branch: All Centers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  ...provider.branches.map(
                    (b) => DropdownMenuItem(
                      value: b.name,
                      child: Text(
                        b.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) provider.setBranchFilter(val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestSlaCard(BuildContext context, TestSlaMetric metric) {
    final isBreached = metric.isBreached;
    final progressFraction = (metric.actualTatHours / metric.targetTatHours).clamp(0.0, 1.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBreached ? AppColors.warning.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.testName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${metric.category} • ${metric.totalSamplesProcessed} samples processed',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.warningLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBreached ? 'TAT Delay Warning' : '${metric.compliancePercentage.toStringAsFixed(1)}% On-SLA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isBreached ? const Color(0xFF92400E) : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressFraction / 1.2).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBreached ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Benchmark: ${metric.targetTatHours} hrs',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'Actual Avg: ${metric.actualTatHours} hrs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isBreached ? AppColors.warning : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchPerformanceCard(BuildContext context, BranchPerformanceMetric branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: branch.hasTestingLab ? const Color(0xFFEEF2FF) : AppColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              branch.hasTestingLab ? Icons.biotech_rounded : Icons.storefront_rounded,
              color: branch.hasTestingLab ? const Color(0xFF6366F1) : AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.branchName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${branch.city} • ${branch.todayProcessedCount} daily tests • Avg ${branch.avgTatHours}h TAT',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${branch.slaComplianceRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              Text(
                branch.operationalStatus,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: branch.operationalStatus == 'Optimal'
                      ? AppColors.success
                      : branch.operationalStatus == 'High Load'
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionBreakdownCard(BuildContext context, List<SampleRejectionCause> causes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Total Network Rejections Today: 32 Specimens (0.42%)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...causes.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          c.reason,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '${c.count} vials (${c.percentage}%)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: c.percentage / 100,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Root Cause Source: ${c.primaryContributingStep}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
