import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/shared.dart';
import 'instant_search_screen.dart';
import 'thermal_barcode_dispatch_screen.dart';

/// God-Level Front Desk Reception & Transit Hub Console
class FrontDeskHomeScreen extends StatefulWidget {
  const FrontDeskHomeScreen({super.key});

  @override
  State<FrontDeskHomeScreen> createState() => _FrontDeskHomeScreenState();
}

class _FrontDeskHomeScreenState extends State<FrontDeskHomeScreen> {
  DateTime? _lastBackPressed;

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit LabTrack'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.glowShadow(AppColors.accent, opacity: 0.3),
              ),
              child: const Icon(Icons.desk_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Branch Reception Command', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.accent),
            label: const Text('Switch Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppColors.accentLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Front Desk Staff Identity Header
                GodLevelCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  hasGlow: true,
                  glowColor: AppColors.accent,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.glowShadow(AppColors.accent, opacity: 0.3),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.name ?? 'Priya Sharma',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'DESK #01 • ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Branch Reception Executive • Spoke Hub #01 (Downtown Central)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.print_outlined, size: 14, color: AppColors.successDark),
                            SizedBox(width: 4),
                            Text(
                              'Thermal Ready',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Reception Telemetry Bar
                if (MediaQuery.sizeOf(context).height >= 700)
                  Row(
                    children: const [
                    Expanded(
                      child: TelemetryMetricCard(
                        title: 'Today Walk-ins',
                        value: '42',
                        subtitle: 'Zero paper slips',
                        icon: Icons.people_alt_outlined,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TelemetryMetricCard(
                        title: 'Labels Printed',
                        value: '128',
                        subtitle: 'Sterile barcodes',
                        icon: Icons.qr_code_2_rounded,
                        accentColor: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TelemetryMetricCard(
                        title: 'Transit Courier',
                        value: '8 Batches',
                        subtitle: 'To Reference Lab',
                        icon: Icons.local_shipping_outlined,
                        accentColor: Color(0xFFD97706),
                      ),
                    ),
                    ],
                  ),
                if (MediaQuery.sizeOf(context).height >= 700) const SizedBox(height: 28),

                // Core Operational Workflows Header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CORE RECEPTION WORKFLOWS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Card 1: Instant Search Console
                GodLevelCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InstantSearchScreen()),
                    );
                  },
                  padding: const EdgeInsets.all(22),
                  borderRadius: 20,
                  hasGlow: true,
                  glowColor: AppColors.primary,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.glowShadow(AppColors.primary, opacity: 0.3),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Instant Report & Patient Lookup',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SUB-SECOND LOOKUP',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Search by patient name, phone number, or specimen barcode. Eliminates manual paper slip searches and gives instant report verification status.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: const [
                                Icon(Icons.keyboard_outlined, size: 14, color: AppColors.textTertiary),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Hotkeys: Press [Enter] for immediate lookup • Auto-filters on type',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 22, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Card 2: Thermal Barcode Label Dispatch
                GodLevelCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ThermalBarcodeDispatchScreen()),
                    );
                  },
                  padding: const EdgeInsets.all(22),
                  borderRadius: 20,
                  hasGlow: true,
                  glowColor: AppColors.accent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.emeraldTealGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.glowShadow(AppColors.success, opacity: 0.3),
                        ),
                        child: const Icon(Icons.print_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Thermal Barcode & Label Dispatch',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'DIRECT DISPATCH',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.successDark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Generate sterile barcode stickers for walk-in patient test requisitions. Supports EDTA lavender, Serum red, and Fluoride grey tubes.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: const [
                                Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.successDark),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'ZPL & ESC/POS Thermal Protocol Compatible • 300 DPI Barcode Grade',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successDark),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 22, color: AppColors.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
