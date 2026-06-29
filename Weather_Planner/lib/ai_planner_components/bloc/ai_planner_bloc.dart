import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_planner_state.dart';
import '../data/repositories/ai_planner_repository.dart';

abstract class AIPlannerEvent {}

class FetchActivitySuggestionEvent extends AIPlannerEvent {
  final double lat;
  final double lon;
  final ActivityType type; 

  FetchActivitySuggestionEvent({
    required this.lat, 
    required this.lon, 
    required this.type
  });
}

class FetchPicnicSuggestionEvent extends FetchActivitySuggestionEvent {
  FetchPicnicSuggestionEvent(double lat, double lon) 
      : super(lat: lat, lon: lon, type: ActivityType.picnic);
}

class AIPlannerBloc extends Bloc<AIPlannerEvent, AIPlannerState> {
  final AIPlannerRepository repository;

  AIPlannerBloc(this.repository) : super(AIPlannerInitial()) {
    
    on<FetchActivitySuggestionEvent>(_onFetchSuggestion);
 
    on<FetchPicnicSuggestionEvent>(_onFetchSuggestion);
  }

  Future<void> _onFetchSuggestion(
    FetchActivitySuggestionEvent event,
    Emitter<AIPlannerState> emit,
  ) async {
    emit(AIPlannerLoading());

    try {
      final suggestion = await repository.getSuggestion(
        type: event.type,
        lat: event.lat,
        lon: event.lon,
      );
      if (!isClosed) {
        emit(AIPlannerLoaded(suggestion));
      }
      
    } catch (e) {
      if (!isClosed) {
        emit(AIPlannerError("Plan can't be created: ${e.toString()}"));
      }
    }
  }
}