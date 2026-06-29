import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class RoutingState extends Equatable {
  const RoutingState();
  
  @override
  List<Object?> get props => [];
}

class RoutingInitial extends RoutingState {
  const RoutingInitial();
}

class RoutingLoading extends RoutingState {
  const RoutingLoading();
}
class RoutingSuccess extends RoutingState {
  final List<LatLng> path;
  
  const RoutingSuccess({required this.path});
  
  @override
  List<Object?> get props => [path];
}
class RoutingFailure extends RoutingState {
  final String error;
  
  const RoutingFailure({required this.error});
  
  @override
  List<Object?> get props => [error];
}