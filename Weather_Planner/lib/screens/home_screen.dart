import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import '../bloc/weather_bloc_bloc.dart';
import '../widgets/side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchWeather();
  }

  Future<void> _getCurrentLocationAndFetchWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permissions are denied. Please allow location access to fetch weather data.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        context.read<WeatherBlocBloc>().add(FetchWeather(position));
        setState(() => _errorMessage = null);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    }
  }

  DateTime _getCityLocalTime(int offsetInSeconds) {
    return DateTime.now().toUtc().add(Duration(seconds: offsetInSeconds));
  }

  DateTime _convertUtcToCityTime(DateTime? apiTime, int offsetInSeconds) {
    if (apiTime == null) return _getCityLocalTime(offsetInSeconds);
    return apiTime.toUtc().add(Duration(seconds: offsetInSeconds));
  }

  Widget getWeatherIcon(int? code, DateTime localTime, {double scale = 1.0}) {
    bool isNight = localTime.hour >= 19 || localTime.hour <= 6;
    String assetPath = 'assets/8.png'; 

    if (code == 800) {
      assetPath = isNight ? 'assets/12.png' : 'assets/6.png';
    } else if (code != null) {
      assetPath = switch (code) {
        >= 200 && < 300 => 'assets/1.png',
        >= 300 && < 400 => 'assets/2.png',
        >= 500 && < 600 => 'assets/3.png',
        >= 600 && < 700 => 'assets/4.png',
        >= 700 && < 800 => 'assets/5.png',
        > 800 && <= 804 => 'assets/7.png',
        _               => 'assets/8.png',
      };
    }

    return Image.asset(
      assetPath, 
      scale: scale, 
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_cloudy, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      endDrawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
          builder: (context, state) {
            if (state is WeatherBlocSuccess) {
              return Text(
                state.weather.areaName?.toUpperCase() ?? "UNKNOWN LOCATION",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/home_screen.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken, 
            ),
          ),
        ),
        child: BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
          builder: (context, state) {
            if (state is WeatherBlocLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            } else if (state is WeatherBlocSuccess) {
              return RefreshIndicator(
                onRefresh: _getCurrentLocationAndFetchWeather,
                color: Colors.white,
                child: _buildMainContent(state.weather, state.weeklyWeather, state.timezoneOffset),
              );
            } else if (_errorMessage != null) {
              return _buildErrorWidget(_errorMessage!);
            }
            return const Center(child: Text("Data is loading...", style: TextStyle(color: Colors.white)));
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Weather current, List<Weather> weekly, int timezoneOffset) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 120),
          Text(
            '${current.temperature?.celsius?.toStringAsFixed(0) ?? "--"}°',
            style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w200),
          ),
          Text(
            current.weatherDescription?.toUpperCase() ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.2),
          ),
          const SizedBox(height: 40),
          _buildHourlyForecast(current, weekly, timezoneOffset),
          const SizedBox(height: 20),
          _buildWeeklyForecastPanel(weekly, timezoneOffset),
          const SizedBox(height: 20),
          _buildDetailGrid(current, timezoneOffset),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(Weather current, List<Weather> weekly, int offset) {
    final DateTime cityNow = _getCityLocalTime(offset);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 15, bottom: 10),
            child: Row(children: [
              Icon(Icons.access_time, color: Colors.white54, size: 14),
              SizedBox(width: 5),
              Text("HOURLY FORECAST", 
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 24,
              itemBuilder: (context, index) {
                // Saat başı hesaplama
                final DateTime hourTime = cityNow
                    .subtract(Duration(minutes: cityNow.minute, seconds: cityNow.second, milliseconds: cityNow.millisecond))
                    .add(Duration(hours: index));

                Weather? displayWeather;
                if (index == 0) {
                  displayWeather = current;
                } else {
                  displayWeather = _findClosestWeather(weekly, hourTime, offset);
                }
                
                String hourLabel = index == 0 ? "Now" : DateFormat('HH').format(hourTime);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(hourLabel, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 8),
                      getWeatherIcon(displayWeather?.weatherConditionCode, index == 0 ? cityNow : hourTime, scale: 12.0),
                      const SizedBox(height: 8),
                      Text(
                        "${displayWeather?.temperature?.celsius?.toStringAsFixed(0) ?? "--"}°", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Weather? _findClosestWeather(List<Weather> weekly, DateTime targetTime, int offset) {
    if (weekly.isEmpty) return null;
    Weather? closest;
    int minDiff = 10000;
    
    for (var w in weekly) {
      if (w.date == null) continue;
      final DateTime weatherLocal = w.date!.toUtc().add(Duration(seconds: offset));
      
      final int diff = weatherLocal.difference(targetTime).inMinutes.abs();
      
      if (diff < minDiff && diff < 120) {
        minDiff = diff;
        closest = w;
      }
    }
    return closest;
  }

  Widget _buildWeeklyForecastPanel(List<Weather> weekly, int offset) {
    if (weekly.isEmpty) return const SizedBox();
    
    Map<String, List<Weather>> groupedByDay = {};
    for (var w in weekly) {
      if (w.date == null) continue;
      DateTime localDate = _convertUtcToCityTime(w.date, offset);
      String key = DateFormat('yyyy-MM-dd').format(localDate);
      groupedByDay.putIfAbsent(key, () => []).add(w);
    }
    
    List<String> sortedKeys = groupedByDay.keys.toList()..sort();
    if (sortedKeys.length > 5) sortedKeys = sortedKeys.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.calendar_month, color: Colors.white54, size: 14),
            SizedBox(width: 5),
            Text("5-DAY FORECAST", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
          const Divider(color: Colors.white12, height: 20),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedKeys.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final dayForecasts = groupedByDay[sortedKeys[index]]!;
              final localDay = _convertUtcToCityTime(dayForecasts[0].date, offset);
              double minTemp = dayForecasts.map((e) => e.tempMin?.celsius ?? 0).reduce((a, b) => a < b ? a : b);
              double maxTemp = dayForecasts.map((e) => e.tempMax?.celsius ?? 0).reduce((a, b) => a > b ? a : b);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(index == 0 ? "Today" : DateFormat('EEEE').format(localDay), style: const TextStyle(color: Colors.white))),
                    Expanded(flex: 2, child: getWeatherIcon(dayForecasts[0].weatherConditionCode, localDay, scale: 10.0)),
                    Expanded(
                      flex: 4, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("${minTemp.toStringAsFixed(0)}°", style: const TextStyle(color: Colors.white54)),
                          const SizedBox(width: 10),
                          Container(width: 30, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [Colors.blue, Colors.orange]))),
                          const SizedBox(width: 10),
                          Text("${maxTemp.toStringAsFixed(0)}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(Weather current, int offset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        children: [
          _detailBlock("FEELS LIKE", "${current.tempFeelsLike?.celsius?.toStringAsFixed(0)}°", Icons.thermostat),
          _detailBlock("HUMIDITY", "${current.humidity?.toStringAsFixed(0)}%", Icons.water_drop),
          _detailBlock("WIND", "${((current.windSpeed ?? 0) * 3.6).toStringAsFixed(0)} km/h", Icons.air),
          _detailBlock("PRESSURE", "${current.pressure?.toStringAsFixed(0)} hPa", Icons.speed),
          _detailBlock("SUNRISE", DateFormat('HH:mm').format(_convertUtcToCityTime(current.sunrise, offset)), Icons.wb_sunny_outlined),
          _detailBlock("SUNSET", DateFormat('HH:mm').format(_convertUtcToCityTime(current.sunset, offset)), Icons.wb_twilight),
        ],
      ),
    );
  }

  Widget _detailBlock(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(onPressed: _getCurrentLocationAndFetchWeather, child: const Text("Retry Again", style: TextStyle(color: Colors.white))),
        ],
      ),
    ); 
  }
}