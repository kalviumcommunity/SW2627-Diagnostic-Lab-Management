/// Cross-platform cross-tab synchronization export.
/// On Web, enables instant message passing across separate Chrome tabs.
/// On Mobile/Desktop, falls back to a no-op stub.
export 'cross_tab_sync_stub.dart'
    if (dart.library.html) 'cross_tab_sync_web.dart';

