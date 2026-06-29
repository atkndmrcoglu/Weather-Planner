import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../map_components/map_models/saved_routes.dart';
import '../map_components/map_bloc/routing_bloc.dart';
import '../map_components/map_bloc/routing_state.dart';

class MyRoutesScreen extends StatelessWidget {
  const MyRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage("assets/my_routes_screen_background.png"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'My Routes & Places',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<SavedRoute>('saved_routes_box').listenable(),
          builder: (context, Box<SavedRoute> box, _) {
            final routes = box.values.toList().reversed.toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Saved Routes"),
                  const SizedBox(height: 16),

                  if (routes.isEmpty)
                    _buildEmptyState("Any saved routes yet. Start planning your first route!")
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: routes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return _RouteCard(
                          title: route.title,
                          stats: "${route.points.length} Nokta • ${route.createdAt.day}/${route.createdAt.month}/${route.createdAt.year}",
                          imagePath: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800",
                          onDelete: () => route.delete(),
                          onTap: () {
                            final List<LatLng> latLngList = route.points
                                .map((p) => LatLng(p[0], p[1]))
                                .toList();
                            context.read<RoutingBloc>().emit(RoutingSuccess(path: latLngList));
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("'${route.title}' Loaded To The Map!"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title, stats, imagePath;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _RouteCard({
    required this.title, 
    required this.stats, 
    required this.imagePath,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          image: DecorationImage(
            image: NetworkImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(stats, 
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceItem extends StatelessWidget {
  final String name, description;
  final IconData icon;
  final Color color, iconColor;

  const _PlaceItem({
    required this.name, 
    required this.description, 
    required this.icon, 
    required this.color, 
    required this.iconColor
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16)),
                    Text(description, style: const TextStyle(
                      color: Colors.white54, 
                      fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, 
              size: 14, color: 
              Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}