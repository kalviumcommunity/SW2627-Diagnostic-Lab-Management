import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import 'track_sample_screen.dart';

/// God-Level Past Bookings & Order History Screen for Patients
/// Displays past and current home sample collections, statuses, QR passes, and tracking shortcuts.
class PastBookingsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToBooking;
  final void Function(String? barcode)? onNavigateToTracking;

  const PastBookingsScreen({
    super.key,
    this.onNavigateToBooking,
    this.onNavigateToTracking,
  });

  @override
  State<PastBookingsScreen> createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    final allOrders = patientProvider.orders;

    // Filter orders
    final filteredOrders = allOrders.where((order) {
      // 1. Status Filter
      if (_selectedFilter == 'Confirmed' && order.status != OrderStatus.confirmed) {
        return false;
      }
      if (_selectedFilter == 'In Progress' && order.status != OrderStatus.inProgress) {
        return false;
      }
      if (_selectedFilter == 'Completed' && order.status != OrderStatus.completed) {
        return false;
      }
      if (_selectedFilter == 'Cancelled' && order.status != OrderStatus.cancelled) {
        return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = order.id.toLowerCase().contains(query);
        final matchesBranch = order.branchName.toLowerCase().contains(query);
        final matchesPhleb = (order.assignedPhlebotomistName ?? '').toLowerCase().contains(query);
        final matchesTests = order.testNames.any((t) => t.toLowerCase().contains(query));
        final matchesBarcode = order.sampleBarcodes.any((b) => b.toLowerCase().contains(query));
        if (!matchesId && !matchesBranch && !matchesPhleb && !matchesTests && !matchesBarcode) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Past Bookings & Visits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${allOrders.length} total doorstep pickup ${allOrders.length == 1 ? 'request' : 'requests'}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Bookings',
            onPressed: () {
              if (currentUserId != null) {
                patientProvider.refreshPatientData(currentUserId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing latest booking statuses...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Book New Test',
            onPressed: widget.onNavigateToBooking,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (currentUserId != null) {
            await patientProvider.refreshPatientData(currentUserId);
          }
        },
        child: Column(
          children: [
            // Search Bar & Filter Ribbon
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Box
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID, test, branch, barcode...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', allOrders.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Confirmed',
                          allOrders.where((o) => o.status == OrderStatus.confirmed).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'In Progress',
                          allOrders.where((o) => o.status == OrderStatus.inProgress).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Completed',
                          allOrders.where((o) => o.status == OrderStatus.completed).length,
                        ),
                        if (allOrders.any((o) => o.status == OrderStatus.cancelled)) ...[
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Cancelled',
                            allOrders.where((o) => o.status == OrderStatus.cancelled).length,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(allOrders.isEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildEmptyState(bool noOrdersAtAll) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              noOrdersAtAll ? 'No Past Bookings Yet' : 'No Matching Bookings Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noOrdersAtAll
                  ? 'Schedule your first doorstep specimen collection.\nA certified phlebotomist will arrive with barcoded sterile vials.'
                  : 'Try adjusting your search query or selecting a different status filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (noOrdersAtAll && widget.onNavigateToBooking != null)
              ElevatedButton.icon(
                onPressed: widget.onNavigateToBooking,
                icon: const Icon(Icons.add_circle_rounded, size: 18),
                label: const Text(
                  'Book a Diagnostic Test Now',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusLabel(order.status);
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(order.scheduledDate);
    final createdDateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
    final hasBarcode = order.sampleBarcodes.isNotEmpty;
    final barcode = hasBarcode ? order.sampleBarcodes.first : null;

    return GodLevelCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      onTap: () => _showOrderDetailsModal(order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.id.length > 14 ? order.id.substring(0, 14) : order.id}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: order.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order ID #${order.id} copied to clipboard'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.copy_rounded, size: 13, color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Booked: $createdDateFormatted',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Appointment Pickup Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    children: [
                      TextSpan(
                        text: '$formattedDate • ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: order.timeSlot,
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
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

          const SizedBox(height: 8),

          // Hub & Phlebotomist Row
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phlebotomist: ${order.assignedPhlebotomistName ?? "Praveen"} (${order.branchName})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Test Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: order.testNames.map((testName) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  testName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Total Price & Barcode Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'TOTAL PAID: ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 0.5),
                    ),
                    Text(
                      '₹${order.totalAmount.toInt()}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
                if (barcode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          barcode,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Action Buttons
          Row(
            children: [
              // Button 1: Show QR Pass
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppointmentQrPassModal.show(context, order);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text(
                    'View QR Pass',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Button 2: Track Live Specimen
              if (barcode != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (widget.onNavigateToTracking != null) {
                        widget.onNavigateToTracking!(barcode);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackSampleScreen(initialBarcode: barcode),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.accent),
                    label: const Text(
                      'Live Track',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.accent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Specifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Order ID: #${order.id}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              _buildDetailRow('Status', _getStatusLabel(order.status)),
              _buildDetailRow('Scheduled Date', DateFormat('EEEE, dd MMMM yyyy').format(order.scheduledDate)),
              _buildDetailRow('Time Window Slot', order.timeSlot),
              _buildDetailRow('Assigned Diagnostic Hub', order.branchName),
              _buildDetailRow('Phlebotomist Assigned', order.assignedPhlebotomistName ?? 'Praveen'),
              _buildDetailRow('Doorstep Address', order.collectionAddress),
              _buildDetailRow('Patient Contact Phone', order.patientPhone),
              _buildDetailRow('Tests Ordered (${order.testNames.length})', order.testNames.join('\n• ')),
              _buildDetailRow('Total Paid Amount', '₹${order.totalAmount.toInt()} (Verified Online)'),
              if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
                _buildDetailRow('Phlebotomist Notes', order.specialInstructions!),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppointmentQrPassModal.show(context, order);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Open Doorstep QR Verification Pass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return AppColors.success;
      case OrderStatus.inProgress:
        return AppColors.warning;
      case OrderStatus.completed:
        return const Color(0xFF0284C7);
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.pending:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inProgress:
        return 'In Transit / Testing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.pending:
        return 'Pending';
    }
  }
}

