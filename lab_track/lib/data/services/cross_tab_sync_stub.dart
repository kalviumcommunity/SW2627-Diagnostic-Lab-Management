/// Stub implementation of CrossTabSync for non-web platforms (Android, iOS, Desktop).
class CrossTabSync {
  static void init([void Function(Map<String, dynamic> data)? onMessage]) {
    // No-op on mobile/desktop
  }

  static void addListener(void Function(Map<String, dynamic> data) listener) {
    // No-op on mobile/desktop
  }

  static void removeListener(void Function(Map<String, dynamic> data) listener) {
    // No-op on mobile/desktop
  }

  static void broadcast(String eventType, Map<String, dynamic> payload) {
    // No-op on mobile/desktop
  }
}
