// Enum representing the overall diagnostic booking/order status.

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Approval';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'inprogress':
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  String toValue() => name;
}
