import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteOverlay extends StatelessWidget {
  final List<LatLng> points;

  const RouteOverlay({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 9.0,
          color: const Color(0xFF00FFCC).withValues(alpha: 0.3), 
          strokeJoin: StrokeJoin.round,
          strokeCap: StrokeCap.round,
        ),
        Polyline(
          points: points,
          strokeWidth: 4.5,
          color: const Color(0xFF00FFCC),
          strokeJoin: StrokeJoin.round,
          strokeCap: StrokeCap.round,
          gradientColors: [
            const Color(0xFF00FFCC),
            const Color(0xFF00B4D8),
          ],
        ),
      ],
    );
  }
}