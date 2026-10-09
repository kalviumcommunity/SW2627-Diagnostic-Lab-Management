import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../../../domain/enums/sample_status.dart';

class FrontDeskSearchItem {
  final OrderModel order;
  final List<SampleModel> samples;
  final List<ReportModel> reports;

  const FrontDeskSearchItem({
    required this.order,
    required this.samples,
    required this.reports,
  });

  bool get hasReadyReport => reports.any((r) => r.isReady);

  ReportModel? get primaryReport =>
      reports.isNotEmpty ? reports.firstWhere((r) => r.isReady, orElse: () => reports.first) : null;

  SampleStatus get aggregateStatus {
    if (samples.isEmpty) return SampleStatus.booked;
    // Check if any report is ready
    if (hasReadyReport) return SampleStatus.reportReady;
    // Otherwise return latest sample status
    return samples.first.status;
  }
}
