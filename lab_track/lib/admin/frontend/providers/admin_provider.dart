import 'package:flutter/foundation.dart';
import '../../../data/models/branch_model.dart';
import '../../backend/models/sla_metric_model.dart';
import '../../backend/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> _kpis = {};
  List<TestSlaMetric> _slaMetrics = [];
  List<SampleRejectionCause> _rejectionCauses = [];
  List<BranchPerformanceMetric> _branchPerformances = [];
  List<BranchModel> _branches = [];
  List<StaffAllocationModel> _staffAllocations = [];
  List<OperationalAlert> _alerts = [];

  String _selectedBranchFilter = 'All Branches';
  String _selectedTimeFilter = 'Today';

  AdminProvider({AdminRepository? repository})
      : _repository = repository ?? AdminRepository() {
    loadAllData();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> get kpis => _kpis;
  List<TestSlaMetric> get slaMetrics => _slaMetrics;
  List<SampleRejectionCause> get rejectionCauses => _rejectionCauses;
  List<BranchPerformanceMetric> get branchPerformances => _branchPerformances;
  List<BranchModel> get branches => _branches;
  List<StaffAllocationModel> get staffAllocations => _staffAllocations;
  List<OperationalAlert> get alerts => _alerts;

  String get selectedBranchFilter => _selectedBranchFilter;
  String get selectedTimeFilter => _selectedTimeFilter;

  // Filtered views
  List<BranchPerformanceMetric> get filteredBranchPerformances {
    if (_selectedBranchFilter == 'All Branches') return _branchPerformances;
    return _branchPerformances
        .where((b) => b.branchName.contains(_selectedBranchFilter) || b.branchId == _selectedBranchFilter)
        .toList();
  }

  List<StaffAllocationModel> get filteredStaffAllocations {
    if (_selectedBranchFilter == 'All Branches') return _staffAllocations;
    return _staffAllocations
        .where((s) => s.assignedBranchName.contains(_selectedBranchFilter) || s.assignedBranchId == _selectedBranchFilter)
        .toList();
  }

  int get activePhlebotomistsCount =>
      _staffStoreCount(rolePredicate: (s) => s.role.name == 'phlebotomist' && s.isOnDuty);

  int _staffStoreCount({required bool Function(StaffAllocationModel) rolePredicate}) {
    return _staffAllocations.where(rolePredicate).length;
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final kpis = await _repository.getOperationalSummary();
      final sla = await _repository.getSlaMetrics();
      final rejections = await _repository.getRejectionCauses();
      final branchPerfs = await _repository.getBranchPerformances();
      final branches = await _repository.getBranches();
      final staff = await _repository.getStaffAllocations();
      final alerts = await _repository.getAlerts();

      _kpis = kpis;
      _slaMetrics = sla;
      _rejectionCauses = rejections;
      _branchPerformances = branchPerfs;
      _branches = branches;
      _staffAllocations = staff;
      _alerts = alerts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadAllData();
  }

  void setBranchFilter(String branch) {
    _selectedBranchFilter = branch;
    notifyListeners();
  }

  void setTimeFilter(String time) {
    _selectedTimeFilter = time;
    notifyListeners();
  }

  Future<bool> addBranch(BranchModel branch) async {
    try {
      final created = await _repository.addBranch(branch);
      _branches = [..._branches, created];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStaffDuty(String staffId) async {
    try {
      final updated = await _repository.toggleStaffDuty(staffId);
      final index = _staffAllocations.indexWhere((s) => s.id == staffId);
      if (index != -1) {
        _staffAllocations[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reallocateStaff({
    required String staffId,
    required String targetBranchId,
    required String targetBranchName,
  }) async {
    try {
      final updated = await _repository.reallocateStaff(
        staffId: staffId,
        targetBranchId: targetBranchId,
        targetBranchName: targetBranchName,
      );
      final index = _staffAllocations.indexWhere((s) => s.id == staffId);
      if (index != -1) {
        _staffAllocations[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addStaffMember(StaffAllocationModel staff) async {
    try {
      final created = await _repository.addStaffMember(staff);
      _staffAllocations = [..._staffAllocations, created];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> resolveAlert(String alertId) async {
    await _repository.resolveAlert(alertId);
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isResolved: true);
      notifyListeners();
    }
  }
}
