import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'routing_event.dart';
import 'routing_state.dart';

class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  RoutingBloc() : super(const RoutingInitial()) {
    on<CalculateRouteEvent>(_onCalculateRoute);
    on<ResetRouteEvent>(_onResetRoute);
  }

  Future<void> _onCalculateRoute(
    CalculateRouteEvent event,
    Emitter<RoutingState> emit,
  ) async {
    emit(const RoutingLoading());

    try {
      final path = await _fetchRoute(event.start, event.end);
      
      if (path.isEmpty) {
        emit(const RoutingFailure(error: "Route not found."));
      } else {
        emit(RoutingSuccess(path: path));
      }
    } catch (e) {
      emit(RoutingFailure(error: "Route Error: ${e.toString()}"));
    }
  }

  void _onResetRoute(
    ResetRouteEvent event,
    Emitter<RoutingState> emit,
  ) {
    emit(const RoutingInitial());
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final String url = 
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
          
          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception("Failed to connect to navigation service: $e");
    }
  }
}