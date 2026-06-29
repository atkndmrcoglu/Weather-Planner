import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weather_bloc_bloc.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});
  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<String> _cities = [];
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _cities = prefs.getStringList('saved_cities') ?? []);
  }

  Future<void> _addCity() async {
    final text = _cityController.text.trim();
    if (text.isNotEmpty && !_cities.contains(text)) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _cities = [..._cities, text];
        prefs.setStringList('saved_cities', _cities);
        _cityController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          const DrawerHeader(child: Center(child: Text("CITIES", style: TextStyle(color: Colors.white, fontSize: 24)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add city...",
                hintStyle: const TextStyle(color: Colors.white30),
                suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _addCity),
              ),
            ),
          ),
          Expanded(
            child: _cities.isEmpty 
            ? const Center(child: Text("No cities saved", style: TextStyle(color: Colors.white24)))
            : ListView.builder(
              itemCount: _cities.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(_cities[i], style: const TextStyle(color: Colors.white)),
                onTap: () {
                  context.read<WeatherBlocBloc>().add(FetchWeatherByCity(_cities[i]));
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}