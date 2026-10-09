import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../models/walk_in_requisition_request.dart';
import '../models/thermal_label_model.dart';
import '../models/frontdesk_search_item.dart';
import '../services/frontdesk_service.dart';

class FrontDeskRepository {
  final FrontDeskService _service;

  FrontDeskRepository({FrontDeskService? service})
      : _service = service ?? FrontDeskService();

  Future<List<FrontDeskSearchItem>> search({
    required String query,
    String filter = 'all',
  }) =>
      _service.search(query: query, filter: filter);

  Future<List<ThermalLabelModel>> createWalkInRequisition(
    WalkInRequisitionRequest request,
  ) =>
      _service.createWalkInRequisition(request);

  Future<void> markLabelsPrinted(List<String> barcodes) =>
      _service.markLabelsPrinted(barcodes);

  List<ThermalLabelModel> getRecentThermalLabels() =>
      _service.getRecentThermalLabels();

  SampleModel? getSampleByBarcode(String barcode) =>
      _service.getSampleByBarcode(barcode);

  ReportModel? getReportByOrderId(String orderId) =>
      _service.getReportByOrderId(orderId);
}
