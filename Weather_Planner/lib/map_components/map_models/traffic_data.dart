import 'package:flutter/material.dart';

class TrafficData {
  final double speedLimit;      
  final double currentSpeed;    
  final String roadName;        

  TrafficData({
    required this.speedLimit,
    required this.currentSpeed,
    required this.roadName,
  });

  double get congestionMultiplier {
    if (currentSpeed <= 0) return 3.0; 
    double ratio = speedLimit / currentSpeed;
    return ratio.clamp(1.0, 2.5);
  }

  Color get trafficColor {
    double multiplier = congestionMultiplier;
    if (multiplier <= 1.2) return Colors.greenAccent; 
    if (multiplier <= 1.8) return Colors.orangeAccent; 
    return Colors.redAccent; 
  }

  String get statusText {
    double multiplier = congestionMultiplier;
    if (multiplier <= 1.2) return "Clear Traffic";
    if (multiplier <= 1.8) return "Heavy Traffic";
    return "Severe Traffic / Congestion";
  }
}