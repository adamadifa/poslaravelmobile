import 'package:intl/intl.dart';

class AppDateFormatter {
  static String format(dynamic date, {String pattern = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    if (date is String && date.trim().isEmpty) return '-';

    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      final clean = date.trim();
      dt = DateTime.tryParse(clean);
      if (dt == null) {
        // Coba potong bagian waktu atau format ISO jika parsing standar gagal
        if (clean.length >= 10) {
          dt = DateTime.tryParse(clean.substring(0, 10));
        }
      }
    }

    if (dt == null) return date.toString();

    try {
      return DateFormat(pattern, 'id_ID').format(dt);
    } catch (_) {
      try {
        return DateFormat(pattern).format(dt);
      } catch (_) {
        return dt.toIso8601String().substring(0, 10);
      }
    }
  }

  static String formatDateTime(dynamic date) {
    return format(date, pattern: 'dd MMM yyyy, HH:mm');
  }

  static String formatShort(dynamic date) {
    return format(date, pattern: 'dd/MM/yyyy');
  }
}
