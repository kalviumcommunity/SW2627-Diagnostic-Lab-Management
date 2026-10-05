// Enum representing the full lifecycle status of a diagnostic sample/vial.

enum SampleStatus {
  booked,
  phlebotomistAssigned,
  collected,
  inTransit,
  receivedAtBranch,
  inTransitToCentralLab,
  receivedAtLab,
  processing,
  reportReady,
  delivered,
  rejected;

  String get displayName {
    switch (this) {
      case SampleStatus.booked:
        return 'Booking Confirmed';
      case SampleStatus.phlebotomistAssigned:
        return 'Phlebotomist Assigned';
      case SampleStatus.collected:
        return 'Sample Collected';
      case SampleStatus.inTransit:
        return 'In Transit';
      case SampleStatus.receivedAtBranch:
        return 'Received at Branch Hub';
      case SampleStatus.inTransitToCentralLab:
        return 'Transferred to Central Lab';
      case SampleStatus.receivedAtLab:
        return 'Received at Central Lab';
      case SampleStatus.processing:
        return 'Processing & Testing';
      case SampleStatus.reportReady:
        return 'Report Ready';
      case SampleStatus.delivered:
        return 'Delivered to Patient';
      case SampleStatus.rejected:
        return 'Sample Rejected / Recollect';
    }
  }

  String get shortLabel {
    switch (this) {
      case SampleStatus.booked:
        return 'Booked';
      case SampleStatus.phlebotomistAssigned:
        return 'Assigned';
      case SampleStatus.collected:
        return 'Collected';
      case SampleStatus.inTransit:
        return 'In Transit';
      case SampleStatus.receivedAtBranch:
        return 'At Branch';
      case SampleStatus.inTransitToCentralLab:
        return 'In Transit';
      case SampleStatus.receivedAtLab:
        return 'At Lab';
      case SampleStatus.processing:
        return 'Testing';
      case SampleStatus.reportReady:
        return 'Report Ready';
      case SampleStatus.delivered:
        return 'Completed';
      case SampleStatus.rejected:
        return 'Rejected';
    }
  }

  /// Progress percentage from 0.0 to 1.0 for patient tracker UI.
  double get progressPercentage {
    switch (this) {
      case SampleStatus.booked:
        return 0.1;
      case SampleStatus.phlebotomistAssigned:
        return 0.2;
      case SampleStatus.collected:
        return 0.35;
      case SampleStatus.inTransit:
        return 0.50;
      case SampleStatus.receivedAtBranch:
        return 0.65;
      case SampleStatus.inTransitToCentralLab:
        return 0.75;
      case SampleStatus.receivedAtLab:
        return 0.85;
      case SampleStatus.processing:
        return 0.90;
      case SampleStatus.reportReady:
      case SampleStatus.delivered:
        return 1.0;
      case SampleStatus.rejected:
        return 0.0;
    }
  }

  static SampleStatus fromString(String? status) {
    if (status == null) return SampleStatus.booked;
    final clean = status.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final val in SampleStatus.values) {
      if (val.name.toLowerCase() == clean) {
        return val;
      }
    }
    // Fallback common aliases
    if (clean.contains('transit')) return SampleStatus.inTransit;
    if (clean.contains('collect')) return SampleStatus.collected;
    if (clean.contains('process') || clean.contains('test')) return SampleStatus.processing;
    if (clean.contains('ready') || clean.contains('verified')) return SampleStatus.reportReady;
    if (clean.contains('reject')) return SampleStatus.rejected;
    return SampleStatus.booked;
  }

  String toValue() => name;
}
