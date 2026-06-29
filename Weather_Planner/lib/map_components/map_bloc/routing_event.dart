import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class RoutingEvent extends Equatable {
  const RoutingEvent();

  @override
  List<Object?> get props => [];
}

class CalculateRouteEvent extends RoutingEvent {
  final LatLng start;
  final LatLng end;

  const CalculateRouteEvent({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class ResetRouteEvent extends RoutingEvent {
  const ResetRouteEvent();

  @override
  List<Object?> get props => [];
}