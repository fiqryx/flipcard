import 'package:intl/intl.dart';

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}

extension DateTimeFormatting on DateTime? {
  /// Formats the DateTime into a custom string.
  /// - [format]: Pattern like 'dd-MM-yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'.
  /// - [fallback]: Text to return if the DateTime is null (default: empty string).
  String format({String format = 'dd-MM-yyyy', String fallback = ''}) {
    if (this == null) return fallback;
    return DateFormat(format).format(this!);
  }

  String formatRelative({String fallback = ''}) {
    if (this == null) return fallback;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(this!.year, this!.month, this!.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return format(); // Falls back to dd-MM-yyyy
  }
}

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final firstDay = DateTime(year, 1, 1);
    return difference(firstDay).inDays + 1;
  }
}
