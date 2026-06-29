import 'package:latlong2/latlong.dart';
import '../map_models/weather_data.dart';
import '../map_models/traffic_data.dart';
import '../map_services/weather_service.dart';
import '../map_services/traffic_service.dart';

class RouteAnalyst {
  final WeatherService _weatherService = WeatherService();
  final TrafficService _trafficService = TrafficService();

  Future<Map<String, dynamic>> analyzeRoute(List<LatLng> path) async {
    if (path.isEmpty) return {"duration": 0, "status": "Denied Route"};

    double totalWeightedFactor = 0;
    int sampleCount = path.length > 10 ? 5 : path.length;
    
    for (int i = 0; i < sampleCount; i++) {
      LatLng point = path[(i * (path.length / sampleCount)).floor()];
      
      WeatherData weather = await _weatherService.getRouteWeather(point);
      TrafficData traffic = await _trafficService.getTrafficData(point);
      
      totalWeightedFactor += (weather.weightMultiplier * traffic.congestionMultiplier);
    }

    double finalMultiplier = totalWeightedFactor / sampleCount;

    return {
      "multiplier": finalMultiplier,
      "advice": _generateAdvice(finalMultiplier),
      "color": _getRouteColor(finalMultiplier),
    };
  }

  String _generateAdvice(double multiplier) {
    if (multiplier > 4.0) return "⚠️ Dangerous Route: Better to Avoid.";
    if (multiplier > 2.5) return "🚗 Hard Forcast";
    if (multiplier > 1.5) return "⏳ It may be take longer than expected.";
    return "✅Best Route: Clear and Fast.";
  }

  String _getRouteColor(double multiplier) {
    if (multiplier > 2.5) return "0xFFFF3366";
    if (multiplier > 1.5) return "0xFFFFCC00";
    return "0xFF00FFCC";
  }
}