import 'package:intl/intl.dart';

/// Date/time formatting helpers used across the app.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _time = DateFormat('HH:mm');

  /// "Just now", "5 min ago", "3 hr ago", "Yesterday", then absolute date.
  static String relative(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Unknown time';
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);
    if (diff.isNegative) return _dateTime.format(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday ${_time.format(value)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateTime.format(value);
  }

  static String dateTime(DateTime? value) =>
      value == null ? 'Not recorded' : _dateTime.format(value);

  static String date(DateTime? value) =>
      value == null ? 'Not recorded' : _date.format(value);

  static String time(DateTime? value) =>
      value == null ? 'Not recorded' : _time.format(value);

  /// Human range for incident windows, e.g. "since 08:30 today".
  static String sinceLabel(DateTime? start, {DateTime? now}) {
    if (start == null) return 'Start time not confirmed';
    return 'Since ${relative(start, now: now)} (${_dateTime.format(start)})';
  }
}
