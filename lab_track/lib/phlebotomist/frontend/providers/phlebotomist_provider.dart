import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../backend/models/phlebotomist_collection_request.dart';
import '../../backend/repositories/phlebotomist_repository.dart';

/// State management for the Field Phlebotomist App (pickups, route, barcode scanning, cold-chain).
class PhlebotomistProvider extends ChangeNotifier {
  final PhlebotomistRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool _isOnDuty = true;
  double _coldBoxTemp = 4.0;
  String _activeFilter = 'pending'; // 'pending', 'urgent', 'completed', 'all'
  String _searchQuery = '';

  List<OrderModel> _orders = [];
  List<SampleModel> _collectedSamples = [];
  OrderModel? _selectedOrder;

  PhlebotomistProvider({PhlebotomistRepository? repository})
      : _repository = repository ?? PhlebotomistRepository() {
    refreshPickups('PH-204');
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isOnDuty => _isOnDuty;
  double get coldBoxTemp => _coldBoxTemp;
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  OrderModel? get selectedOrder => _selectedOrder;
  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<SampleModel> get collectedSamples => List.unmodifiable(_collectedSamples);

  List<OrderModel> get pendingPickups =>
      _orders.where((o) => o.status != OrderStatus.completed).toList();

  List<OrderModel> get completedPickups =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  List<OrderModel> get urgentPickups => _orders.where((o) {
        if (o.status == OrderStatus.completed) return false;
        final slot = o.timeSlot.toLowerCase();
        final instructions = (o.specialInstructions ?? '').toLowerCase();
        return slot.contains('urgent') ||
            slot.contains('fasting') ||
            instructions.contains('fasting') ||
            instructions.contains('urgent');
      }).toList();

  List<OrderModel> get filteredPickups {
    List<OrderModel> list;
    switch (_activeFilter) {
      case 'urgent':
        list = urgentPickups;
        break;
      case 'completed':
        list = completedPickups;
        break;
      case 'all':
        list = _orders;
        break;
      case 'pending':
      default:
        list = pendingPickups;
        break;
    }

    if (_searchQuery.trim().isEmpty) return list;

    final q = _searchQuery.trim().toLowerCase();
    return list.where((o) {
      return o.patientName.toLowerCase().contains(q) ||
          o.id.toLowerCase().contains(q) ||
          o.patientPhone.contains(q) ||
          o.collectionAddress.toLowerCase().contains(q) ||
          o.testNames.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  int get todayTotalCount => _orders.length;
  int get collectedVialsCount => _collectedSamples.length;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleDutyStatus() {
    _isOnDuty = !_isOnDuty;
    notifyListeners();
  }

  void updateColdBoxTemp(double temp) {
    _coldBoxTemp = temp;
    _repository.logColdBoxTemperature(
      phlebotomistId: 'PH-204',
      temperature: temp,
      notes: 'Cold box temperature calibrated.',
    );
    notifyListeners();
  }

  void selectOrder(OrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  Future<void> refreshPickups([String phlebotomistId = 'PH-204']) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pickupList = await _repository.getAssignedPickups(phlebotomistId);
      final sampleList = await _repository.getCollectedSamples(phlebotomistId);
      _orders = pickupList;
      _collectedSamples = sampleList;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isBarcodeAlreadyUsed(String barcode) async {
    return _repository.isBarcodeAlreadyUsed(barcode);
  }

  Future<SampleModel?> confirmCollection(PhlebotomistCollectionRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final sample = await _repository.confirmCollection(request);
      _successMessage = 'Sample ${sample.barcode} bound and stored successfully!';
      await refreshPickups(request.phlebotomistId);
      return sample;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handoverBatchToHub({
    required String phlebotomistId,
    required String branchId,
    required String branchName,
    required List<String> sampleBarcodes,
    required String receiverName,
    String? hubNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.handoverBatchToHub(
        phlebotomistId: phlebotomistId,
        branchId: branchId,
        branchName: branchName,
        sampleBarcodes: sampleBarcodes,
        receiverName: receiverName,
        hubNotes: hubNotes,
      );
      _successMessage = 'Batch of ${sampleBarcodes.length} vials transferred to $branchName!';
      await refreshPickups(phlebotomistId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
