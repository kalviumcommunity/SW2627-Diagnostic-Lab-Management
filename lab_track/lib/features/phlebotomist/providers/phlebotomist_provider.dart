
import 'package:flutter/foundation.dart';

enum CollectionStatus {
  pending,
  collected,
}

class CollectionTask {
  CollectionTask({
    required this.id,
    required this.patientName,
    required this.phone,
    required this.address,
    required this.testName,
    required this.collectionTime,
    this.status = CollectionStatus.pending,
  });

  final String id;
  final String patientName;
  final String phone;
  final String address;
  final String testName;
  final String collectionTime;
  CollectionStatus status;
}

class PhlebotomistProvider extends ChangeNotifier {
  final List<CollectionTask> _tasks = [
    CollectionTask(
      id: 'SMP-1001',
      patientName: 'Rahul Sharma',
      phone: '9876543210',
      address: 'Malviya Nagar, Jaipur',
      testName: 'CBC + Blood Sugar',
      collectionTime: '10:00 AM',
    ),
    CollectionTask(
      id: 'SMP-1002',
      patientName: 'Priya Mehta',
      phone: '9876543211',
      address: 'Mansarovar, Jaipur',
      testName: 'Thyroid Profile',
      collectionTime: '11:30 AM',
    ),
    CollectionTask(
      id: 'SMP-1003',
      patientName: 'Amit Singh',
      phone: '9876543212',
      address: 'Vaishali Nagar, Jaipur',
      testName: 'Lipid Profile',
      collectionTime: '01:00 PM',
      status: CollectionStatus.collected,
    ),
    CollectionTask(
      id: 'SMP-1004',
      patientName: 'Neha Verma',
      phone: '9876543213',
      address: 'C-Scheme, Jaipur',
      testName: 'Liver Function Test',
      collectionTime: '03:30 PM',
    ),
  ];

  String _searchQuery = '';
  String _filter = 'All';

  List<CollectionTask> get tasks {
    final query = _searchQuery.trim().toLowerCase();

    return _tasks.where((task) {
      final matchesSearch =
          task.patientName.toLowerCase().contains(query) ||
          task.id.toLowerCase().contains(query) ||
          task.address.toLowerCase().contains(query);

      final matchesFilter = switch (_filter) {
        'Pending' => task.status == CollectionStatus.pending,
        'Collected' => task.status == CollectionStatus.collected,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get totalCount => _tasks.length;

  int get pendingCount => _tasks
      .where((task) => task.status == CollectionStatus.pending)
      .length;

  int get collectedCount => _tasks
      .where((task) => task.status == CollectionStatus.collected)
      .length;

  String get filter => _filter;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void markCollected(CollectionTask task) {
    if (task.status == CollectionStatus.collected) return;

    task.status = CollectionStatus.collected;
    notifyListeners();
  }
}
