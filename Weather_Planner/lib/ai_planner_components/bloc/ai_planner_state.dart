import '../data/models/ai_planner_suggestion_model.dart';

abstract class AIPlannerState {}

class AIPlannerInitial extends AIPlannerState {}

class AIPlannerLoading extends AIPlannerState {}

class AIPlannerLoaded extends AIPlannerState {
  final PlannerSuggestion suggestion;
  AIPlannerLoaded(this.suggestion);
}

class AIPlannerError extends AIPlannerState {
  final String message;
  AIPlannerError(this.message);
}