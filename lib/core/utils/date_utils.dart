import 'package:intl/intl.dart';

class AppDateUtils {
  static String display(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return DateFormat('dd MMM yyyy').format(d);
  }

  static String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String monthName(int month) => DateFormat('MMMM').format(DateTime(2024, month));
}
