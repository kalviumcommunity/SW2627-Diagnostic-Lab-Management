import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../../backend/models/walk_in_requisition_request.dart';
import '../../backend/models/thermal_label_model.dart';
import '../../backend/models/frontdesk_search_item.dart';
import '../../backend/repositories/frontdesk_repository.dart';

class FrontDeskProvider extends ChangeNotifier {
  final FrontDeskRepository _repository;

  final bool _isLoading = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isPrinting = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchQuery = '';
  String _searchFilter = 'all'; // 'all', 'ready', 'processing', 'inTransit'

  List<FrontDeskSearchItem> _searchResults = [];
  List<ThermalLabelModel> _recentLabels = [];

  FrontDeskProvider({FrontDeskRepository? repository})
      : _repository = repository ?? FrontDeskRepository() {
    _init();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSubmitting => _isSubmitting;
  bool get isPrinting => _isPrinting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get searchQuery => _searchQuery;
  String get searchFilter => _searchFilter;

  List<FrontDeskSearchItem> get searchResults => List.unmodifiable(_searchResults);
  List<ThermalLabelModel> get recentLabels => List.unmodifiable(_recentLabels);

  int get totalOrderCount => _searchResults.length;
  int get readyReportCount => _searchResults.where((i) => i.hasReadyReport).length;

  void _init() {
    _recentLabels = _repository.getRecentThermalLabels();
    refreshSearch();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await refreshSearch();
  }

  Future<void> setSearchFilter(String filter) async {
    _searchFilter = filter;
    await refreshSearch();
  }

  Future<void> refreshSearch() async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.search(
        query: _searchQuery,
        filter: _searchFilter,
      );
      _searchResults = items;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<List<ThermalLabelModel>?> submitWalkInRequisition(WalkInRequisitionRequest request) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final labels = await _repository.createWalkInRequisition(request);
      _recentLabels = _repository.getRecentThermalLabels();
      _successMessage =
          'Walk-in requisition created! Generated ${labels.length} sterile barcode stickers.';
      await refreshSearch();
      return labels;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> printThermalLabels(List<ThermalLabelModel> labels) async {
    if (labels.isEmpty) return false;

    _isPrinting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Simulate thermal print spooling
      await Future.delayed(const Duration(milliseconds: 700));
      final barcodes = labels.map((l) => l.barcode).toList();
      await _repository.markLabelsPrinted(barcodes);
      _recentLabels = _repository.getRecentThermalLabels();
      _successMessage = 'Successfully dispatched ${labels.length} barcode stickers to Thermal Printer!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<bool> printRequisitionSlip(OrderModel order) async {
    _isPrinting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      _successMessage = 'Patient receipt slip printed for Order #${order.id}!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  SampleModel? getSample(String barcode) => _repository.getSampleByBarcode(barcode);

  ReportModel? getReport(String orderId) => _repository.getReportByOrderId(orderId);
}
