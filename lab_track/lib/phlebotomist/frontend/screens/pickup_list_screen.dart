import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/phlebotomist_provider.dart';
import 'order_detail_screen.dart';
import 'scan_vial_screen.dart';

class PickupListScreen extends StatelessWidget {
  final bool showAppBar;

  const PickupListScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhlebotomistProvider>();
    final pickups = provider.filteredPickups;

    final content = Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input Field
              TextField(
                onChanged: (val) => provider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search by patient, phone, or address...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Pending',
                      count: provider.pendingPickups.length,
                      isSelected: provider.activeFilter == 'pending',
                      onSelected: () => provider.setFilter('pending'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Urgent / Fasting',
                      count: provider.urgentPickups.length,
                      isSelected: provider.activeFilter == 'urgent',
                      color: const Color(0xFFD97706),
                      onSelected: () => provider.setFilter('urgent'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Completed',
                      count: provider.completedPickups.length,
                      isSelected: provider.activeFilter == 'completed',
                      color: AppColors.success,
                      onSelected: () => provider.setFilter('completed'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'All Today',
                      count: provider.todayTotalCount,
                      isSelected: provider.activeFilter == 'all',
                      onSelected: () => provider.setFilter('all'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Pickups List / Empty State
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.refreshPickups(),
            child: pickups.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Pickups in this Queue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'All doorstep collections in this filter are completed or none assigned.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => provider.setFilter('all'),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('View All Pickups'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pickups.length,
                    itemBuilder: (context, index) {
                      final order = pickups[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
          ),
        ),
      ],
    );

    if (!showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doorstep Pickup Queue', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: content,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    Color color = AppColors.primary,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final isCompleted = order.status == OrderStatus.completed;
    final isFasting = order.timeSlot.toLowerCase().contains('fasting') ||
        (order.specialInstructions ?? '').toLowerCase().contains('fasting');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : (isFasting ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : AppColors.border),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Patient Name & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isCompleted
                        ? AppColors.successLight
                        : (isFasting ? const Color(0xFFFEF3C7) : AppColors.primaryLight),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : (isFasting ? Icons.warning_amber_rounded : Icons.person_rounded),
                      size: 20,
                      color: isCompleted
                          ? AppColors.success
                          : (isFasting ? const Color(0xFFD97706) : AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${order.id} • ${order.patientPhone}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.successLight
                          : (isFasting ? const Color(0xFFFEF3C7) : AppColors.primaryLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted ? 'Collected' : (isFasting ? 'Fasting Req.' : 'Scheduled'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? AppColors.success
                            : (isFasting ? const Color(0xFFD97706) : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Slot and Address
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.timeSlot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFasting ? const Color(0xFFB45309) : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.collectionAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Test badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: order.testNames.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 20, color: AppColors.border),

              // Actions Footer
              Row(
                children: [
                  // Call Patient
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${order.patientName} (${order.patientPhone})...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  const Spacer(),

                  // Scan / View Button
                  if (isCompleted)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                      label: const Text('View Sample', style: TextStyle(fontSize: 12, color: AppColors.success)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanVialScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text('Scan & Bind', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
