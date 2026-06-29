import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../map_models/traffic_data.dart';

class TrafficService {
  Future<TrafficData> getTrafficData(LatLng point) async {
    try {
      final List<String> roads = ["Atatürk Bulvarı", "İstasyon Caddesi", "Mevlana Yolu", "Çevreyol"];
      String randomRoad = roads[Random().nextInt(roads.length)];

      double speedLimit = 70.0;
      double currentSpeed = 20.0 + Random().nextDouble() * 55.0;
      int hour = DateTime.now().hour;
      if ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20)) {
        currentSpeed *= 0.6;
      }

      return TrafficData(
        speedLimit: speedLimit,
        currentSpeed: currentSpeed,
        roadName: randomRoad,
      );
    } catch (e) {
      return TrafficData(
        speedLimit: 70.0,
        currentSpeed: 70.0,
        roadName: "Unknown Road Data",
      );
    }
  }

  double calculateTotalDelay(List<TrafficData> roadSegments) {
    double totalMultiplier = 1.0;
    if (roadSegments.isEmpty) return totalMultiplier;

    double sum = 0;
    for (var segment in roadSegments) {
      sum += segment.congestionMultiplier;
    }
    
    return sum / roadSegments.length;
  }
}