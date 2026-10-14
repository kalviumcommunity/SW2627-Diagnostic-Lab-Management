import '../../../data/models/branch_model.dart';
import '../models/sla_metric_model.dart';
import '../services/admin_service.dart';

class AdminRepository {
  final AdminService _service;

  AdminRepository({AdminService? service}) : _service = service ?? AdminService();

  Future<Map<String, dynamic>> getOperationalSummary() => _service.getOperationalSummary();
  Future<List<TestSlaMetric>> getSlaMetrics() => _service.getSlaMetrics();
  Future<List<SampleRejectionCause>> getRejectionCauses() => _service.getRejectionCauses();
  Future<List<BranchPerformanceMetric>> getBranchPerformances() => _service.getBranchPerformances();
  Future<List<BranchModel>> getBranches() => _service.getBranches();
  Future<BranchModel> addBranch(BranchModel branch) => _service.addBranch(branch);
  Future<List<StaffAllocationModel>> getStaffAllocations() => _service.getStaffAllocations();
  Future<StaffAllocationModel> toggleStaffDuty(String staffId) => _service.toggleStaffDuty(staffId);
  Future<StaffAllocationModel> reallocateStaff({
    required String staffId,
    required String targetBranchId,
    required String targetBranchName,
  }) => _service.reallocateStaff(
        staffId: staffId,
        targetBranchId: targetBranchId,
        targetBranchName: targetBranchName,
      );
  Future<StaffAllocationModel> addStaffMember(StaffAllocationModel staff) => _service.addStaffMember(staff);
  Future<List<OperationalAlert>> getAlerts() => _service.getAlerts();
  Future<void> resolveAlert(String alertId) => _service.resolveAlert(alertId);
}
