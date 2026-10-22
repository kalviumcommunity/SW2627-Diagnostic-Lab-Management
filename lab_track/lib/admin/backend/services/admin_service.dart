import '../../../data/models/branch_model.dart';
import '../../../domain/enums/user_role.dart';
import '../models/sla_metric_model.dart';
import '../../../data/mock/seed_users.dart';

/// Admin Backend API Service
/// Provides operational metrics, SLA/TAT calculations, multi-branch topology,
/// and staff fleet workload monitoring.
class AdminService {
  static final List<BranchModel> _branchStore = [];
  static final List<StaffAllocationModel> _staffStore = [];
  static final List<TestSlaMetric> _slaMetrics = [];
  static final List<SampleRejectionCause> _rejectionCauses = [];
  static final List<OperationalAlert> _alerts = [];
  static bool _initialized = false;

  AdminService() {
    _ensureInitialized();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // 1. Seed Network Branches
    _branchStore.addAll([
      const BranchModel(
        id: 'branch-apex-hq',
        name: 'Apex Central Reference Laboratory',
        address: 'Plot 42, Institutional Area, Sector 32, Gurugram',
        city: 'Gurugram',
        hasTestingLab: true,
        phoneNumber: '+91 124 456 7890',
      ),
      const BranchModel(
        id: 'branch-spoke-01',
        name: 'Downtown Spoke Center #1',
        address: 'B-12, Ground Floor, Connaught Place, New Delhi',
        city: 'New Delhi',
        hasTestingLab: false,
        phoneNumber: '+91 11 2341 5678',
      ),
      const BranchModel(
        id: 'BR-004',
        name: 'Central Diagnostic Hub 4',
        address: 'Shop 14-16, Galleria Arcade, Sector 29, Gurugram',
        city: 'Gurugram',
        hasTestingLab: true,
        phoneNumber: '+91 124 998 1122',
      ),
      const BranchModel(
        id: 'branch-noida-02',
        name: 'Noida Sector 18 Express Collection Center',
        address: 'Tower A, Commercial Complex, Sector 18, Noida',
        city: 'Noida',
        hasTestingLab: false,
        phoneNumber: '+91 120 455 6789',
      ),
      const BranchModel(
        id: 'branch-north-hub',
        name: 'North Delhi Processing Hub',
        address: '15 Mall Road, Civil Lines, North Delhi',
        city: 'New Delhi',
        hasTestingLab: true,
        phoneNumber: '+91 11 2766 8899',
      ),
    ]);

    // 2. Seed Test TAT SLA Metrics
    _slaMetrics.addAll([
      const TestSlaMetric(
        testName: 'Complete Blood Count (CBC)',
        category: 'Hematology',
        targetTatHours: 2.5,
        actualTatHours: 2.1,
        totalSamplesProcessed: 480,
        compliantSamples: 468,
        compliancePercentage: 97.5,
      ),
      const TestSlaMetric(
        testName: 'Thyroid Panel (T3, T4, TSH)',
        category: 'Biochemistry',
        targetTatHours: 4.0,
        actualTatHours: 3.4,
        totalSamplesProcessed: 320,
        compliantSamples: 310,
        compliancePercentage: 96.8,
      ),
      const TestSlaMetric(
        testName: 'HbA1c Glycated Hemoglobin',
        category: 'Diabetes Care',
        targetTatHours: 3.0,
        actualTatHours: 2.8,
        totalSamplesProcessed: 290,
        compliantSamples: 282,
        compliancePercentage: 97.2,
      ),
      const TestSlaMetric(
        testName: 'Lipid Profile (Cholesterol & Triglycerides)',
        category: 'Biochemistry',
        targetTatHours: 4.5,
        actualTatHours: 4.1,
        totalSamplesProcessed: 215,
        compliantSamples: 206,
        compliancePercentage: 95.8,
      ),
      const TestSlaMetric(
        testName: 'Vitamin D-3 (25-OH)',
        category: 'Immunoassay',
        targetTatHours: 6.0,
        actualTatHours: 6.4, // Slight breach
        totalSamplesProcessed: 140,
        compliantSamples: 128,
        compliancePercentage: 91.4,
      ),
      const TestSlaMetric(
        testName: 'Liver Function Test (LFT)',
        category: 'Biochemistry',
        targetTatHours: 4.0,
        actualTatHours: 3.7,
        totalSamplesProcessed: 185,
        compliantSamples: 178,
        compliancePercentage: 96.2,
      ),
    ]);

    // 3. Seed Sample Rejection Root-Causes Breakdown
    _rejectionCauses.addAll([
      const SampleRejectionCause(
        reason: 'Hemolyzed Specimen (Ruptured RBCs)',
        count: 14,
        percentage: 43.8,
        primaryContributingStep: 'Field Drawing / Needle Technique',
      ),
      const SampleRejectionCause(
        reason: 'Micro-Clotted Anticoagulant Tube',
        count: 9,
        percentage: 28.1,
        primaryContributingStep: 'Inadequate Tube Inversion (EDTA)',
      ),
      const SampleRejectionCause(
        reason: 'Insufficient Specimen Volume (QNS)',
        count: 5,
        percentage: 15.6,
        primaryContributingStep: 'Difficult Pediatric / Senior Draw',
      ),
      const SampleRejectionCause(
        reason: 'Cold-Chain Temp Breach (>8°C)',
        count: 3,
        percentage: 9.4,
        primaryContributingStep: 'Courier Transit Delay',
      ),
      const SampleRejectionCause(
        reason: 'Mislabeled / Smudged Barcode',
        count: 1,
        percentage: 3.1,
        primaryContributingStep: 'Label Printing Defect',
      ),
    ]);

    // 4. Seed Staff Allocations
    _staffStore.addAll([
      const StaffAllocationModel(
        id: 'PH-204',
        name: 'Rahul Verma',
        email: 'rahul.phlebo@labtrack.com',
        phoneNumber: '+91 98765 11111',
        role: UserRole.phlebotomist,
        assignedBranchId: 'BR-004',
        assignedBranchName: 'Central Diagnostic Hub 4',
        isOnDuty: true,
        todayCompletedTasks: 7,
        pendingTasks: 3,
        avgRating: 4.95,
      ),
      const StaffAllocationModel(
        id: 'PH-102',
        name: 'Rajeev Kumar',
        email: 'rajeev.k@labtrack.com',
        phoneNumber: '+91 98112 23344',
        role: UserRole.phlebotomist,
        assignedBranchId: 'branch-spoke-01',
        assignedBranchName: 'Downtown Spoke Center #1',
        isOnDuty: true,
        todayCompletedTasks: 6,
        pendingTasks: 2,
        avgRating: 4.88,
      ),
      const StaffAllocationModel(
        id: 'PH-308',
        name: 'Amit Deshmukh',
        email: 'amit.d@labtrack.com',
        phoneNumber: '+91 98223 34455',
        role: UserRole.phlebotomist,
        assignedBranchId: 'branch-noida-02',
        assignedBranchName: 'Noida Sector 18 Express',
        isOnDuty: false,
        todayCompletedTasks: 4,
        pendingTasks: 0,
        avgRating: 4.92,
      ),
      const StaffAllocationModel(
        id: 'TECH-101',
        name: 'Dr. Neha Kapoor',
        email: 'neha.lab@labtrack.com',
        phoneNumber: '+91 98334 45566',
        role: UserRole.labTechnician,
        assignedBranchId: 'branch-apex-hq',
        assignedBranchName: 'Apex Central Reference Laboratory',
        isOnDuty: true,
        todayCompletedTasks: 64,
        pendingTasks: 8,
        avgRating: 5.0,
      ),
      const StaffAllocationModel(
        id: 'FD-108',
        name: 'Priya Sharma',
        email: 'priya.frontdesk@labtrack.com',
        phoneNumber: '+91 98765 22222',
        role: UserRole.frontDesk,
        assignedBranchId: 'branch-spoke-01',
        assignedBranchName: 'Downtown Spoke Center #1',
        isOnDuty: true,
        todayCompletedTasks: 28,
        pendingTasks: 4,
        avgRating: 4.97,
      ),
      const StaffAllocationModel(
        id: 'TECH-205',
        name: 'Suresh Menon',
        email: 'suresh.tech@labtrack.com',
        phoneNumber: '+91 98445 56677',
        role: UserRole.labTechnician,
        assignedBranchId: 'branch-north-hub',
        assignedBranchName: 'North Delhi Processing Hub',
        isOnDuty: true,
        todayCompletedTasks: 52,
        pendingTasks: 12,
        avgRating: 4.85,
      ),
    ]);

    // Populate remaining staff from kSeedUsers
    final existingStaffIds = _staffStore.map((s) => s.id).toSet();
    const branchNameMap = {
      'branch-apex-hq': 'Apex Central Reference Laboratory',
      'branch-spoke-01': 'Downtown Spoke Center #1',
      'BR-004': 'Central Diagnostic Hub 4',
      'branch-noida-02': 'Noida Sector 18 Express',
      'branch-southdelhi-03': 'South Extension Specialized Pathology',
      'branch-north-hub': 'North Delhi Processing Hub',
    };
    for (final u in kSeedUsers) {
      if (!u.isPatient && !existingStaffIds.contains(u.id)) {
        _staffStore.add(
          userToStaffAllocation(
            u,
            assignedBranchName: branchNameMap[u.assignedBranchId] ?? 'Central Lab Hub',
            isOnDuty: true,
            todayCompletedTasks: 4 + (u.id.hashCode.abs() % 15),
            pendingTasks: 1 + (u.id.hashCode.abs() % 5),
            avgRating: 4.8 + ((u.id.hashCode.abs() % 20) / 100.0),
          ),
        );
      }
    }

    // 5. Seed Real-time Operational Alerts
    _alerts.addAll([
      OperationalAlert(
        id: 'ALT-101',
        title: 'Vitamin D Assay Batch Bottleneck',
        description: 'Immunoassay analyzer at Apex HQ experiencing queue build-up; TAT exceeds SLA by 24 mins.',
        severity: 'warning',
        timestamp: now.subtract(const Duration(minutes: 25)),
        branchId: 'branch-apex-hq',
      ),
      OperationalAlert(
        id: 'ALT-102',
        title: 'Re-collection Alert: Vial Hemolysis',
        description: 'Specimen #SMP-77219 from Sector 14 rejected. Front desk auto-notified for priority home re-draw.',
        severity: 'critical',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
        branchId: 'BR-004',
      ),
      OperationalAlert(
        id: 'ALT-103',
        title: 'Cold Chain Courier Checkpoint Clear',
        description: 'Courier relay batch #CR-88 from Downtown Spoke 01 logged at 3.9°C intact.',
        severity: 'info',
        timestamp: now.subtract(const Duration(hours: 2)),
        branchId: 'branch-spoke-01',
      ),
    ]);
  }

  /// Get High-Level Operational KPI Summary
  Future<Map<String, dynamic>> getOperationalSummary() async {
    return {
      'totalDailyVolume': 1420,
      'completedReports': 1285,
      'activeInTransit': 84,
      'processingOnBench': 48,
      'slaComplianceRate': 96.8,
      'avgTatHours': 3.2,
      'onDutyStaffCount': _staffStore.where((s) => s.isOnDuty).length,
      'activeAlertsCount': _alerts.where((a) => !a.isResolved).length,
    };
  }

  /// Get Test SLA Metrics
  Future<List<TestSlaMetric>> getSlaMetrics() async {
    return List.unmodifiable(_slaMetrics);
  }

  /// Get Sample Rejection Root Causes
  Future<List<SampleRejectionCause>> getRejectionCauses() async {
    return List.unmodifiable(_rejectionCauses);
  }

  /// Get Branch Performance List
  Future<List<BranchPerformanceMetric>> getBranchPerformances() async {
    return [
      const BranchPerformanceMetric(
        branchId: 'branch-apex-hq',
        branchName: 'Apex Central Reference Laboratory',
        city: 'Gurugram',
        hasTestingLab: true,
        activeSpecimensInCustody: 62,
        todayProcessedCount: 680,
        avgTatHours: 2.8,
        slaComplianceRate: 98.2,
        activePhlebotomists: 8,
        operationalStatus: 'Optimal',
      ),
      const BranchPerformanceMetric(
        branchId: 'BR-004',
        branchName: 'Central Diagnostic Hub 4',
        city: 'Gurugram',
        hasTestingLab: true,
        activeSpecimensInCustody: 38,
        todayProcessedCount: 340,
        avgTatHours: 3.4,
        slaComplianceRate: 96.5,
        activePhlebotomists: 6,
        operationalStatus: 'Optimal',
      ),
      const BranchPerformanceMetric(
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        city: 'New Delhi',
        hasTestingLab: false,
        activeSpecimensInCustody: 18,
        todayProcessedCount: 195,
        avgTatHours: 3.8,
        slaComplianceRate: 95.1,
        activePhlebotomists: 5,
        operationalStatus: 'High Load',
      ),
      const BranchPerformanceMetric(
        branchId: 'branch-north-hub',
        branchName: 'North Delhi Processing Hub',
        city: 'New Delhi',
        hasTestingLab: true,
        activeSpecimensInCustody: 24,
        todayProcessedCount: 205,
        avgTatHours: 3.1,
        slaComplianceRate: 97.0,
        activePhlebotomists: 4,
        operationalStatus: 'Optimal',
      ),
      const BranchPerformanceMetric(
        branchId: 'branch-noida-02',
        branchName: 'Noida Sector 18 Express',
        city: 'Noida',
        hasTestingLab: false,
        activeSpecimensInCustody: 12,
        todayProcessedCount: 110,
        avgTatHours: 4.2,
        slaComplianceRate: 92.4,
        activePhlebotomists: 3,
        operationalStatus: 'Delayed Transit',
      ),
    ];
  }

  /// Get All Network Branches
  Future<List<BranchModel>> getBranches() async {
    return List.unmodifiable(_branchStore);
  }

  /// Add New Branch Hub / Center
  Future<BranchModel> addBranch(BranchModel branch) async {
    _branchStore.add(branch);
    return branch;
  }

  /// Get Staff Allocations
  Future<List<StaffAllocationModel>> getStaffAllocations() async {
    return List.unmodifiable(_staffStore);
  }

  /// Toggle Staff Duty Status (On Duty / Off Duty)
  Future<StaffAllocationModel> toggleStaffDuty(String staffId) async {
    final index = _staffStore.indexWhere((s) => s.id == staffId);
    if (index == -1) throw Exception('Staff member not found');
    final current = _staffStore[index];
    final updated = current.copyWith(isOnDuty: !current.isOnDuty);
    _staffStore[index] = updated;
    return updated;
  }

  /// Reallocate Staff Member to Another Branch
  Future<StaffAllocationModel> reallocateStaff({
    required String staffId,
    required String targetBranchId,
    required String targetBranchName,
  }) async {
    final index = _staffStore.indexWhere((s) => s.id == staffId);
    if (index == -1) throw Exception('Staff member not found');
    final current = _staffStore[index];
    final updated = current.copyWith(
      assignedBranchId: targetBranchId,
      assignedBranchName: targetBranchName,
    );
    _staffStore[index] = updated;
    return updated;
  }

  /// Add New Staff Member
  Future<StaffAllocationModel> addStaffMember(StaffAllocationModel staff) async {
    _staffStore.add(staff);
    return staff;
  }

  /// Get Operational Alerts
  Future<List<OperationalAlert>> getAlerts() async {
    return List.unmodifiable(_alerts);
  }

  /// Resolve Operational Alert
  Future<void> resolveAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isResolved: true);
    }
  }
}
