import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../models/phlebotomist_collection_request.dart';
import '../services/phlebotomist_service.dart';

/// Phlebotomist Repository mediating data access between services and providers.
class PhlebotomistRepository {
  final PhlebotomistService _service;

  PhlebotomistRepository({PhlebotomistService? service})
      : _service = service ?? PhlebotomistService();

  Future<List<OrderModel>> getAssignedPickups(String phlebotomistId) =>
      _service.getAssignedPickups(phlebotomistId);

  Future<OrderModel?> getOrderById(String orderId) =>
      _service.getOrderById(orderId);

  Future<List<SampleModel>> getCollectedSamples(String phlebotomistId) =>
      _service.getCollectedSamples(phlebotomistId);

  Future<bool> isBarcodeAlreadyUsed(String barcode) =>
      _service.isBarcodeAlreadyUsed(barcode);

  Future<SampleModel> confirmCollection(PhlebotomistCollectionRequest request) =>
      _service.confirmCollection(request);

  Future<void> handoverBatchToHub({
    required String phlebotomistId,
    required String branchId,
    required String branchName,
    required List<String> sampleBarcodes,
    required String receiverName,
    String? hubNotes,
  }) =>
      _service.handoverBatchToHub(
        phlebotomistId: phlebotomistId,
        branchId: branchId,
        branchName: branchName,
        sampleBarcodes: sampleBarcodes,
        receiverName: receiverName,
        hubNotes: hubNotes,
      );

  Future<void> logColdBoxTemperature({
    required String phlebotomistId,
    required double temperature,
    required String notes,
  }) =>
      _service.logColdBoxTemperature(
        phlebotomistId: phlebotomistId,
        temperature: temperature,
        notes: notes,
      );

  List<Map<String, dynamic>> getTemperatureLogs() =>
      _service.getTemperatureLogs();
}
