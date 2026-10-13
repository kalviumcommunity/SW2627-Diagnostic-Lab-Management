import '../../../domain/enums/user_role.dart';

/// Performance metrics for diagnostic tests and turnaround time (TAT).
class TestSlaMetric {
  final String testName;
  final String category;
  final double targetTatHours;
  final double actualTatHours;
  final int totalSamplesProcessed;
  final int compliantSamples;
  final double compliancePercentage;

  const TestSlaMetric({
    required this.testName,
    required this.category,
    required this.targetTatHours,
    required this.actualTatHours,
    required this.totalSamplesProcessed,
    required this.compliantSamples,
    required this.compliancePercentage,
  });

  bool get isBreached => actualTatHours > targetTatHours;
}

/// Root-cause analysis breakdown for rejected or recollected specimens.
class SampleRejectionCause {
  final String reason;
  final int count;
  final double percentage;
  final String primaryContributingStep;

  const SampleRejectionCause({
    required this.reason,
    required this.count,
    required this.percentage,
    required this.primaryContributingStep,
  });
}

/// Branch-level operational throughput and compliance ranking.
class BranchPerformanceMetric {
  final String branchId;
  final String branchName;
  final String city;
  final bool hasTestingLab;
  final int activeSpecimensInCustody;
  final int todayProcessedCount;
  final double avgTatHours;
  final double slaComplianceRate;
  final int activePhlebotomists;
  final String operationalStatus; // 'Optimal', 'High Load', 'Critical Bottleneck'

  const BranchPerformanceMetric({
    required this.branchId,
    required this.branchName,
    required this.city,
    required this.hasTestingLab,
    required this.activeSpecimensInCustody,
    required this.todayProcessedCount,
    required this.avgTatHours,
    required this.slaComplianceRate,
    required this.activePhlebotomists,
    required this.operationalStatus,
  });
}

/// Operational staff member allocation and workload model.
class StaffAllocationModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String assignedBranchId;
  final String assignedBranchName;
  final bool isOnDuty;
  final int todayCompletedTasks;
  final int pendingTasks;
  final double avgRating;

  const StaffAllocationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.assignedBranchId,
    required this.assignedBranchName,
    required this.isOnDuty,
    required this.todayCompletedTasks,
    required this.pendingTasks,
    this.avgRating = 4.9,
  });

  StaffAllocationModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? assignedBranchId,
    String? assignedBranchName,
    bool? isOnDuty,
    int? todayCompletedTasks,
    int? pendingTasks,
    double? avgRating,
  }) {
    return StaffAllocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      assignedBranchId: assignedBranchId ?? this.assignedBranchId,
      assignedBranchName: assignedBranchName ?? this.assignedBranchName,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      todayCompletedTasks: todayCompletedTasks ?? this.todayCompletedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      avgRating: avgRating ?? this.avgRating,
    );
  }
}

/// High-priority operational escalation alert.
class OperationalAlert {
  final String id;
  final String title;
  final String description;
  final String severity; // 'critical', 'warning', 'info'
  final DateTime timestamp;
  final String branchId;
  final bool isResolved;

  const OperationalAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.branchId,
    this.isResolved = false,
  });

  OperationalAlert copyWith({
    String? id,
    String? title,
    String? description,
    String? severity,
    DateTime? timestamp,
    String? branchId,
    bool? isResolved,
  }) {
    return OperationalAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      branchId: branchId ?? this.branchId,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
