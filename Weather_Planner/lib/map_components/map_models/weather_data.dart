import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final String condition; 
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.windSpeed,
  });
  double get weightMultiplier {
    switch (condition.toLowerCase()) {
      case 'snow': return 3.5;        
      case 'rain': return 1.8;         
      case 'thunderstorm': return 2.5; 
      case 'mist': 
      case 'fog': return 1.3;          
      default: return 1.0;             
    }
  }

  IconData get weatherIcon {
    switch (condition.toLowerCase()) {
      case 'snow': return Icons.ac_unit_rounded;
      case 'rain': return Icons.umbrella_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      default: return Icons.wb_sunny_rounded;
    }
  }

  Color get warningColor {
    if (weightMultiplier >= 2.5) return Colors.redAccent;
    if (weightMultiplier > 1.0) return Colors.orangeAccent;
    return Colors.cyanAccent;
  }
}