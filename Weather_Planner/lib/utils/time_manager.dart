import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_lookup;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimeManager {
  static final TimeManager _instance = TimeManager._internal();
  factory TimeManager() => _instance;
  TimeManager._internal();

  bool _isInitialized = false;

  void init() {
    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }
  }

  DateTime getLocalTimeFromCoords(double lat, double lng) {
    if (!_isInitialized) init();

    try {
      String timezoneId = tz_lookup.latLngToTimezoneString(lat, lng);

      final location = tz.getLocation(timezoneId);

      return tz.TZDateTime.now(location);
    } catch (e) {
      return DateTime.now();
    }
  }

  String formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}