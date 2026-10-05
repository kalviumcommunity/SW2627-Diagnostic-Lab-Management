import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';

/// Phlebotomist Backend API Service (Collection, Vial Barcoding & Cold-Chain Intake)
class PhlebotomistService {
  Future<List<OrderModel>> getAssignedPickups(String phlebotomistId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  Future<void> confirmCollection({
    required String sampleBarcode,
    required String orderId,
    required double temperature,
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
