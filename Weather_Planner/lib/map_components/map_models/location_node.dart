import 'package:latlong2/latlong.dart';

class LocationNode {
  final LatLng position;
  final String? name;
  final String? timestamp;

  LocationNode({
    required this.position,
    this.name,
    this.timestamp,
  });

  factory LocationNode.fromJson(Map<String, dynamic> json) {
    return LocationNode(
      position: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      name: json['display_name'] ?? "",
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationNode &&
          runtimeType == other.runtimeType &&
          other.position.latitude == position.latitude &&
          other.position.longitude == position.longitude;

  @override
  int get hashCode => position.latitude.hashCode ^ position.longitude.hashCode;
}