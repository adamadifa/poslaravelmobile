import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  static String format(num? amount) {
    if (amount == null) return 'Rp 0';
    return _formatter.format(amount);
  }

  static String formatNumber(num? amount) {
    if (amount == null) return '0';
    return _numberFormatter.format(amount);
  }

  static double parseCleanNumber(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  static String formatCompact(num? amount) {
    if (amount == null) return '0';
    return NumberFormat.compact(locale: 'id_ID').format(amount);
  }
}

/// TextInputFormatter yang secara realtime memformat input angka menjadi pemisah ribuan titik (contoh: 10000 -> 10.000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya digit angka
    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.tryParse(cleanDigits) ?? 0;
    final newFormatted = _formatter.format(number);

    return TextEditingValue(
      text: newFormatted,
      selection: TextSelection.collapsed(offset: newFormatted.length),
    );
  }
}
