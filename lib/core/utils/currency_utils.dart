import 'package:intl/intl.dart';

class CurrencyUtils {
  static final _formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static String format(num? value) => _formatter.format(value ?? 0);
}
