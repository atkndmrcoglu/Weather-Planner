import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 
import '../ai_planner_components/bloc/ai_planner_bloc.dart';
import '../ai_planner_components/bloc/ai_planner_state.dart';
import '../ai_planner_components/data/models/ai_planner_suggestion_model.dart';
import '../ai_planner_components/data/repositories/ai_planner_repository.dart';

class AiPlannerScreen extends StatelessWidget {
  const AiPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AIPlannerBloc(AIPlannerRepository()),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/ai_planner_screen_background.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: _AiPlannerBody(),
        ),
      ),
    );
  }
}

class _AiPlannerBody extends StatelessWidget {
  const _AiPlannerBody();

  String _formatDate(DateTime date) {
    String day = date.day.toString();
    String suffix;

    if (date.day >= 11 && date.day <= 13) {
      suffix = 'th';
    } else {
      switch (date.day % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
        default: suffix = 'th';
      }
    }
    return "$day$suffix of ${DateFormat('MMMM EEEE').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'Picnic', 'icon': Icons.restaurant_rounded, 'color': Colors.orange, 'type': ActivityType.picnic},
      {'title': 'Walking', 'icon': Icons.forest_rounded, 'color': Colors.green, 'type': ActivityType.hiking},
      {'title': 'View Area', 'icon': Icons.camera_rounded, 'color': Colors.purple, 'type': ActivityType.photography},
      {'title': 'Sport', 'icon': Icons.fitness_center_rounded, 'color': Colors.blue, 'type': ActivityType.sports},
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppBar(
          expandedHeight: 140.0,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Text(
              'AI Travel Assistant',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800, 
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = categories[index];
                return _CategoryCard(
                  title: cat['title'] as String,
                  icon: cat['icon'] as IconData,
                  color: cat['color'] as Color,
                  onTap: () {
                    context.read<AIPlannerBloc>().add(
                      FetchActivitySuggestionEvent(lat: 38.7, lon: 35.4, type: cat['type'] as ActivityType)
                    );
                  },
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: BlocBuilder<AIPlannerBloc, AIPlannerState>(
              builder: (context, state) {
                if (state is AIPlannerLoading) {
                  return _buildLoadingState();
                } else if (state is AIPlannerLoaded) {
                  return _buildDetailedResult(state.suggestion);
                } else if (state is AIPlannerError) {
                  return _buildStatusMessage(state.message, isError: true);
                }
                return _buildStatusMessage("Which activity would you like suggestions for?");
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildStatusMessage(String message, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.lightbulb_outline, 
               color: isError ? Colors.white : Colors.blueAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResult(PlannerSuggestion suggestion) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Best Day: ${_formatDate(suggestion.bestDate)}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.reason,
                  style: const TextStyle(color: Color.fromARGB(255, 234, 216, 216), fontSize: 15, height: 1.5, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                const Text("📍 Suggested Locations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestion.recommendedPlaces.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(p, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 15, 
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}