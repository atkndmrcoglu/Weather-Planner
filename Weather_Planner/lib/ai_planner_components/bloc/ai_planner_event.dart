abstract class AIPlannerEvent {}

class FetchPicnicSuggestionEvent extends AIPlannerEvent {
  final double lat;
  final double lon;
  FetchPicnicSuggestionEvent(this.lat, this.lon);
}