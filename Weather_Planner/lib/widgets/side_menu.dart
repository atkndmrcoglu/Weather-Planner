import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weather_bloc_bloc.dart';
import '../models/city_model.dart';
import '../utils/time_manager.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<String> _savedCities = [];
  List<CityModel> _allWorldCities = [];
  List<CityModel> _searchResultCities = [];
  final TextEditingController _cityController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadSavedCities();
    await _loadWorldCitiesFromJson();
  }

  Future<void> _loadWorldCitiesFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/cities.json');
      final List<dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _allWorldCities = data.map((e) => CityModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("JSON Load Error: $e");
    }
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _savedCities = prefs.getStringList('saved_cities') ?? [];
      });
    }
  }

  String _calculateTime(String latStr, String lngStr) {
    try {
      double lat = double.parse(latStr);
      double lng = double.parse(lngStr);
      DateTime localTime = TimeManager().getLocalTimeFromCoords(lat, lng);
      return TimeManager().formatTime(localTime);
    } catch (e) {
      return "--:--";
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResultCities = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResultCities = _allWorldCities
          .where((city) => city.name.toLowerCase().startsWith(query.toLowerCase()))
          .take(20)
          .toList();
    });
  }

  Future<void> _addCityToFavorites(CityModel city) async {
    if (!_savedCities.contains(city.name)) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedCities = [..._savedCities, city.name];
        prefs.setStringList('saved_cities', _savedCities);
        _cityController.clear();
        _isSearching = false;
        _searchResultCities = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${city.name} Added to favorites.'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  Future<void> _removeCity(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final removedCity = _savedCities[index];
    setState(() {
      _savedCities.removeAt(index);
      _savedCities = List.from(_savedCities);
      prefs.setStringList('saved_cities', _savedCities);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$removedCity Removed from favorites.'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _isSearching ? _buildSearchResults() : _buildSavedCities(),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Text(
        'My Cities',
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: 3),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _cityController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search city...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.search, color: Colors.white60),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResultCities.isEmpty) {
      return const Center(child: Text('City not found', style: TextStyle(color: Colors.white54)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResultCities.length,
      itemBuilder: (context, index) {
        final city = _searchResultCities[index];
        final isAlreadySaved = _savedCities.contains(city.name);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(city.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: Text(city.country, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _calculateTime(city.lat, city.lng),
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    isAlreadySaved ? Icons.check_circle : Icons.add_circle_outline,
                    color: isAlreadySaved ? Colors.greenAccent : Colors.white38,
                  ),
                  onPressed: isAlreadySaved ? null : () => _addCityToFavorites(city),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedCities() {
    if (_savedCities.isEmpty) {
      return const Center(child: Text('No cities added yet', style: TextStyle(color: Colors.white38)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _savedCities.length,
      itemBuilder: (context, index) {
        final cityName = _savedCities[index];
        
        final cityData = _allWorldCities.firstWhere(
          (c) => c.name == cityName,
          orElse: () => CityModel(name: cityName, country: "", lat: "0", lng: "0", timezoneOffset: 0),
        );
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            title: Text(cityData.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
            subtitle: Text(cityData.country, style: const TextStyle(color: Colors.white38)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _calculateTime(cityData.lat, cityData.lng),
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeCity(index),
                ),
              ],
            ),
            onTap: () {
              context.read<WeatherBlocBloc>().add(FetchWeatherByCity(cityData.name));
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}