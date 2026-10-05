import '../enums/sample_status.dart';

/// State Machine enforcing strict chain-of-custody lifecycle transitions
/// for diagnostic vials to prevent erroneous status skips or untracked state jumps.
class SampleStateMachine {
  static const Map<SampleStatus, List<SampleStatus>> _validTransitions = {
    SampleStatus.booked: [
      SampleStatus.phlebotomistAssigned,
      SampleStatus.rejected,
    ],
    SampleStatus.phlebotomistAssigned: [
      SampleStatus.collected,
      SampleStatus.rejected,
    ],
    SampleStatus.collected: [
      SampleStatus.inTransit,
      SampleStatus.receivedAtBranch,
      SampleStatus.rejected,
    ],
    SampleStatus.inTransit: [
      SampleStatus.receivedAtBranch,
      SampleStatus.receivedAtLab,
      SampleStatus.rejected,
    ],
    SampleStatus.receivedAtBranch: [
      SampleStatus.inTransitToCentralLab,
      SampleStatus.processing, // if branch can test locally
      SampleStatus.rejected,
    ],
    SampleStatus.inTransitToCentralLab: [
      SampleStatus.receivedAtLab,
      SampleStatus.rejected,
    ],
    SampleStatus.receivedAtLab: [
      SampleStatus.processing,
      SampleStatus.rejected,
    ],
    SampleStatus.processing: [
      SampleStatus.reportReady,
      SampleStatus.rejected,
    ],
    SampleStatus.reportReady: [
      SampleStatus.delivered,
    ],
    SampleStatus.delivered: [],
    SampleStatus.rejected: [],
  };

  /// Validates whether transitioning from [current] to [next] is legally allowed.
  static bool canTransition(SampleStatus current, SampleStatus next) {
    if (current == next) return true;
    final allowed = _validTransitions[current];
    return allowed?.contains(next) ?? false;
  }

  /// Returns the next recommended milestone status.
  static SampleStatus? getNextDefaultMilestone(SampleStatus current) {
    final allowed = _validTransitions[current];
    if (allowed == null || allowed.isEmpty) return null;
    return allowed.firstWhere(
      (s) => s != SampleStatus.rejected,
      orElse: () => allowed.first,
    );
  }
}
