import 'package:weather/weather.dart';
import 'package:latlong2/latlong.dart';
import '../map_models/weather_data.dart';

class WeatherService {
  final String _apiKey = "4feeac7af5f34fb4eae87585551e6e33";
  late WeatherFactory _wf;

  WeatherService() {
    _wf = WeatherFactory(_apiKey, language: Language.ENGLISH);
  }
  Future<WeatherData> getRouteWeather(LatLng point) async {
    try {
      Weather w = await _wf.currentWeatherByLocation(
        point.latitude, 
        point.longitude
      );

      return WeatherData(
        temperature: w.temperature?.celsius ?? 0.0,
        condition: w.weatherMain ?? "Clear",
        windSpeed: w.windSpeed ?? 0.0,
      );
    } catch (e) {
      return WeatherData(
        temperature: 20.0,
        condition: "Clear",
        windSpeed: 0.0,
      );
    }
  }

  String getDrivingAdvice(WeatherData data) {
    double multiplier = data.weightMultiplier;
    
    if (multiplier >= 3.0) return "⚠️ Critical Snowstorm: Use Winter Tires and Drive with Extreme Caution.";
    if (multiplier >= 2.0) return "🌧️ Warning: Storm and slippery road conditions.";
    if (multiplier > 1.0) return "🌦️ Warning: Rainfall may increase following distance.";
    return "✅ Clear Road: Driving conditions are excellent.";
  }
}