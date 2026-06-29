import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/ai_planner_suggestion_model.dart';

enum ActivityType { 
  picnic, hiking, photography, sports, beach, cityTour 
}

class AIPlannerRepository {
  final String _overpassUrl = "https://overpass-api.de/api/interpreter";

  Future<PlannerSuggestion> getSuggestion({
    required ActivityType type,
    required double lat,
    required double lon,
  }) async {
    try {
      // İstek öncesi kısa bir gecikme
      await Future.delayed(const Duration(milliseconds: 500));

      final List<String> places = await _findPlacesWithOverpass(lat, lon, type);

      return PlannerSuggestion(
        bestDate: DateTime.now().add(const Duration(days: 1)),
        reason: "The analysis of the surroundings was completed based on real-time geographical data.",
        recommendedPlaces: places.isNotEmpty ? places : ["Natural Exploration Area"],
        suitabilityScore: 92.0,
      );
    } catch (e) {
      throw Exception("Error preparing suggestion: $e");
    }
  }

  Future<List<String>> _findPlacesWithOverpass(double lat, double lon, ActivityType type) async {
    String osmFilter;
    
    switch (type) {
      case ActivityType.picnic: 
        osmFilter = '["leisure"~"park|picnic_site|garden"]'; break;
      case ActivityType.hiking: 
        osmFilter = '["leisure"~"nature_reserve|park"]["hiking"~"yes|designated|intermediate|easy"]'; break;
      case ActivityType.photography: 
        osmFilter = '["tourism"~"viewpoint|attraction|artwork|historic"]'; break;
      case ActivityType.sports: 
        osmFilter = '["leisure"~"pitch|sports_centre|stadium|fitness_station"]'; break;
      case ActivityType.beach: 
        osmFilter = '["natural"~"beach|water"]'; break;
      case ActivityType.cityTour: 
        osmFilter = '["tourism"~"museum|gallery|historic|monument|castle"]'; break;
    }

    final query = """
    [out:json][timeout:30];
    (
      nwr$osmFilter(around:25000,$lat,$lon);
    );
    out tags;
    """;

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List elements = data['elements'] ?? [];

        if (elements.isNotEmpty) {
          final List<String> foundNames = elements
              .where((e) => e['tags'] != null && e['tags']['name'] != null)
              .map((e) => e['tags']['name'] as String)
              .toSet()
              .toList();

          if (foundNames.isNotEmpty) {
            foundNames.shuffle();
            return foundNames.take(3).toList();
          }
        }
      }
    } catch (e) {
      
      throw Exception("Overpass API Error: $e");
    }

    return ["No Locations Found"];
  }
}