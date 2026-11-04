import '../models/branch_model.dart';
import '../../admin/backend/models/sla_metric_model.dart';
import '../services/central_data_store.dart';

/// Repository managing network spoke centers, central testing hubs, and staff allocations.
class BranchRepository {
  final CentralDataStore _store;

  BranchRepository({CentralDataStore? store})
      : _store = store ?? CentralDataStore.instance;

  /// Retrieves all branches in the diagnostic network.
  Future<List<BranchModel>> getAllBranches() async {
    return _store.branches;
  }

  /// Retrieves a specific branch by ID.
  Future<BranchModel?> getBranchById(String id) async {
    try {
      return _store.branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves staff allocations across branches.
  Future<List<StaffAllocationModel>> getStaffAllocations() async {
    return _store.staff;
  }
}
