import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;
DateTime localToday(String zone) {
  if (!_initialized) {
    data.initializeTimeZones();
    _initialized = true;
  }
  final now = tz.TZDateTime.now(tz.getLocation(zone));
  return DateTime(now.year, now.month, now.day);
}

String civilDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
String shortDate(String value) =>
    DateFormat('dd/MM').format(DateTime.parse(value));
DateTime daysBefore(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day - days);
int quantityMillis(String value) {
  final parts = value.split('.');
  return int.parse(parts[0]) * 1000 +
      int.parse(parts.length == 1 ? '000' : parts[1].padRight(3, '0'));
}
