import 'package:intl/intl.dart';

/// Clinical timestamp and date formatting utility.
class AppDateUtils {
  static final DateFormat standard = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat dateOnly = DateFormat('dd MMM yyyy');
  static final DateFormat timeOnly = DateFormat('hh:mm a');
  static final DateFormat iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  static String format(DateTime? date, {String fallback = 'N/A'}) {
    if (date == null) return fallback;
    return standard.format(date);
  }

  static String formatDate(DateTime? date, {String fallback = 'N/A'}) {
    if (date == null) return fallback;
    return dateOnly.format(date);
  }

  static String formatTime(DateTime? date, {String fallback = 'N/A'}) {
    if (date == null) return fallback;
    return timeOnly.format(date);
  }
}
