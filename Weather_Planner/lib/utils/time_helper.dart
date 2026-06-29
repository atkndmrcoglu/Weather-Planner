import 'package:intl/intl.dart';

class TimeHelper {
  static String getCityLocalTime(int offsetSeconds) {
    try {
      final DateTime utcNow = DateTime.now().toUtc();
      
      final DateTime cityTime = utcNow.add(Duration(seconds: offsetSeconds));
      
      // Formatla
      return DateFormat('HH:mm').format(cityTime);
    } catch (e) {
      return "--:--";
    }
  }
}