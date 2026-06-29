class PlannerSuggestion {
  final DateTime bestDate;
  final String reason;
  final List<String> recommendedPlaces;
  final double suitabilityScore;

  PlannerSuggestion({
    required this.bestDate,
    required this.reason,
    required this.recommendedPlaces,
    required this.suitabilityScore,
  });
}