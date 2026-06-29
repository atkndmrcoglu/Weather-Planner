import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../map_models/location_node.dart';

class OsmService {
  final String _searchUrl = 'https://nominatim.openstreetmap.org/search';
  final String _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';
  Future<List<LocationNode>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('$_searchUrl?q=$query&format=json&limit=5&addressdetails=1');

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'WeatherPlannerApp_v1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => LocationNode.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception("Location Search Error: $e");
    }
    return [];
  }
  Future<String> getAddressFromLatLng(LatLng position) async {
    final url = Uri.parse(
      '$_reverseUrl?lat=${position.latitude}&lon=${position.longitude}&format=json',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'WeatherPlannerApp_v1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Unknown Location";
      }
    } catch (e) {
      return "Address Resolution Error: $e";
    }
    return "Location could not be determined";
  }
}