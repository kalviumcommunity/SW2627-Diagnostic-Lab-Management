// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Real-time Cross-Tab synchronization using Web BroadcastChannel and HTML5 localStorage.
/// Enables seamless instant updates across multiple open browser tabs (e.g. Patient, Phlebotomist, Admin).
class CrossTabSync {
  static html.BroadcastChannel? _channel;
  static bool _initialized = false;
  static String _lastMessageId = '';
  static final List<void Function(Map<String, dynamic> data)> _listeners = [];

  static void init([void Function(Map<String, dynamic> data)? onMessage]) {
    if (onMessage != null && !_listeners.contains(onMessage)) {
      _listeners.add(onMessage);
    }
    if (_initialized) return;
    _initialized = true;

    void handlePacket(dynamic rawData) {
      try {
        Map<String, dynamic>? packet;
        if (rawData is String) {
          final decoded = jsonDecode(rawData);
          if (decoded is Map<String, dynamic>) {
            packet = decoded;
          }
        } else if (rawData is Map) {
          packet = Map<String, dynamic>.from(rawData);
        }

        if (packet != null) {
          final msgId = packet['msgId']?.toString() ?? '';
          if (msgId.isNotEmpty && msgId == _lastMessageId) {
            return; // Ignore duplicate
          }
          if (msgId.isNotEmpty) {
            _lastMessageId = msgId;
          }
          for (final listener in List.of(_listeners)) {
            try {
              listener(packet);
            } catch (e) {
              debugPrint('Error invoking CrossTabSync listener: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('CrossTabSync packet handling error: $e');
      }
    }

    try {
      _channel = html.BroadcastChannel('labtrack_cross_tab_channel');
      _channel?.onMessage.listen((event) {
        handlePacket(event.data);
      });

      // Also listen to window storage events as fallback mechanism
      html.window.onStorage.listen((event) {
        if (event.key == 'labtrack_sync_packet' && event.newValue != null) {
          handlePacket(event.newValue);
        }
      });
    } catch (e) {
      debugPrint('CrossTabSync init error: $e');
    }
  }

  static void addListener(void Function(Map<String, dynamic> data) listener) {
    init(listener);
  }

  static void removeListener(void Function(Map<String, dynamic> data) listener) {
    _listeners.remove(listener);
  }

  static void broadcast(String eventType, Map<String, dynamic> payload) {
    try {
      _channel ??= html.BroadcastChannel('labtrack_cross_tab_channel');
      final msgId = 'msg_${DateTime.now().microsecondsSinceEpoch}_${payload.hashCode}';
      final packet = {
        'msgId': msgId,
        'type': eventType,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final jsonStr = jsonEncode(packet);
      _channel?.postMessage(jsonStr);
      // Fallback: storage event in other tabs
      html.window.localStorage['labtrack_sync_packet'] = jsonStr;
    } catch (e) {
      debugPrint('CrossTabSync broadcast error: $e');
    }
  }
}
