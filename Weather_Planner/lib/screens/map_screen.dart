import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../map_components/map_bloc/routing_bloc.dart';
import '../map_components/map_bloc/routing_event.dart';
import '../map_components/map_bloc/routing_state.dart';
import '../map_components/map_ui/route_overlay.dart';
import '../map_components/map_models/saved_routes.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialCity;
  const MapScreen({super.key, this.initialCity});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _isSelectingStart = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSaveDialog(List<LatLng> points) async {
    final TextEditingController nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Name Your Route",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "e.g., Erciyes Summit Road",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF58A6FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EA043),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _executeSave(points, nameController.text.trim());
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSave(List<LatLng> polylinePoints, String title) async {
    try {
      final box = Hive.box<SavedRoute>('saved_routes_box');
      final List<List<double>> rawPoints =
          polylinePoints.map((p) => [p.latitude, p.longitude]).toList();

      final newRoute = SavedRoute(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        points: rawPoints,
        createdAt: DateTime.now(),
      );

      await box.add(newRoute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'$title' successfully saved!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  // --- KONUM TAKİBİ ---
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _updatePosition(position, moveCamera: true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _updatePosition(position, moveCamera: false);
    });

    if (widget.initialCity != null) {
      setState(() {
        _endPoint = widget.initialCity;
        _mapController.move(widget.initialCity!, 13.0);
      });
    }
  }

  void _updatePosition(Position position, {required bool moveCamera}) {
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _startPoint ??= _currentLocation;

      if (moveCamera) {
        _mapController.move(_currentLocation!, 15.0);
      }
    });
  }

  // --- ARAMA ÖNERİLERİ ---
  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'WeatherPlannerApp'});
      if (response.statusCode == 200) {
        setState(() => _suggestions = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Suggest Error: $e");
    }
  }

  void _handleTap(LatLng point) {
    setState(() {
      if (_isSelectingStart) {
        _startPoint = point;
        _isSelectingStart = false;
      } else {
        _endPoint = point;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(38.7205, 35.4826),
              initialZoom: 13.0,
              onTap: (tapPosition, point) => _handleTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              BlocConsumer<RoutingBloc, RoutingState>(
                listener: (context, state) {
                  if (state is RoutingSuccess && state.path.isNotEmpty) {
                    _mapController.move(state.path.first, 14.0);
                  }
                },
                builder: (context, state) {
                  if (state is RoutingSuccess) {
                    return RouteOverlay(points: state.path);
                  }
                  return const SizedBox.shrink();
                },
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: _buildLiveLocationMarker(),
                    ),
                  if (_startPoint != null && _startPoint != _currentLocation)
                    Marker(
                      point: _startPoint!,
                      width: 60,
                      height: 60,
                      child: _buildNeonMarker(
                          const Color(0xFF58A6FF), Icons.location_on),
                    ),
                  if (_endPoint != null)
                    Marker(
                      point: _endPoint!,
                      width: 60,
                      height: 60,
                      child: _buildNeonMarker(
                          const Color(0xFFFF3366), Icons.flag_circle_rounded),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              children: [
                _buildSearchBox(),
                if (_suggestions.isNotEmpty) _buildSuggestionList(),
              ],
            ),
          ),
          _buildUnifiedControlCenter(),
        ],
      ),
    );
  }

  Widget _buildUnifiedControlCenter() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 110.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoundIconButton(
                    icon:
                        _isSelectingStart ? Icons.touch_app : Icons.my_location,
                    color: _isSelectingStart
                        ? const Color(0xFF39D353)
                        : Colors.white70,
                    onTap: () {
                      if (!_isSelectingStart && _currentLocation != null) {
                        _mapController.move(_currentLocation!, 15.0);
                      }
                      setState(() => _isSelectingStart = !_isSelectingStart);
                    },
                  ),
                  _buildSmallDivider(),
                  _buildRoundIconButton(
                    icon: Icons.bookmark_add_rounded,
                    color: const Color(0xFFFFD700),
                    onTap: () {
                      final routingState = context.read<RoutingBloc>().state;
                      if (routingState is RoutingSuccess) {
                        _showSaveDialog(routingState.path);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No active route to save!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  _buildSmallDivider(),
                  _buildRoundIconButton(
                    icon: Icons.refresh_rounded,
                    color: const Color(0xFF58A6FF),
                    onTap: () {
                      setState(() {
                        _endPoint = null;
                        _startPoint = _currentLocation;
                        _searchController.clear();
                        _isSelectingStart = false;
                      });
                      context.read<RoutingBloc>().add(const ResetRouteEvent());
                    },
                  ),
                  _buildSmallDivider(),
                  _buildRoundIconButton(
                    icon: Icons.navigation_rounded,
                    color: const Color(0xFF2EA043),
                    label: "GO",
                    isAction: true,
                    onTap: () {
                      if (_startPoint != null && _endPoint != null) {
                        context.read<RoutingBloc>().add(CalculateRouteEvent(
                            start: _startPoint!, end: _endPoint!));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Select a destination"),
                            backgroundColor: Colors.blueGrey,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 5)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallDivider() => Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white12);

  Widget _buildRoundIconButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap,
      String? label,
      bool isAction = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              horizontal: label != null ? 18 : 12, vertical: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: isAction ? color : color.withValues(alpha: 0.05)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isAction ? Colors.white : color, size: 24),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.85),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _getSuggestions,
            decoration: const InputDecoration(
              hintText: "Search",
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return ListTile(
            leading:
                const Icon(Icons.location_on_outlined, color: Colors.white54),
            title: Text(item['display_name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () {
              final pos = LatLng(
                  double.parse(item['lat']), double.parse(item['lon']));
              setState(() {
                _endPoint = pos;
                _suggestions = [];
                _searchController.text = item['display_name'];
                _mapController.move(pos, 15.0);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildNeonMarker(Color color, IconData icon) {
    return Stack(alignment: Alignment.center, children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)
              ])),
      Icon(icon, color: color, size: 30),
    ]);
  }
}