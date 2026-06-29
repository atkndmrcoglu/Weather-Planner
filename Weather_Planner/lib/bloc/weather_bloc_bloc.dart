import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:http/http.dart' as http; 

part 'weather_bloc_event.dart';
part 'weather_bloc_state.dart';

class WeatherBlocBloc extends Bloc<WeatherBlocEvent, WeatherBlocState> {
  final String _apiKey = "4feeac7af5f34fb4eae87585551e6e33";

  WeatherBlocBloc() : super(WeatherBlocInitial()) {

    on<FetchWeather>((event, emit) async {
      emit(WeatherBlocLoading());
      try {
        WeatherFactory wf = _getWeatherFactory();

        Weather weather = await wf.currentWeatherByLocation(
          event.position.latitude, 
          event.position.longitude,
        );
        
        List<Weather> weeklyWeather = await wf.fiveDayForecastByLocation(
          event.position.latitude, 
          event.position.longitude,
        );
        int realCityOffset = await _getRawTimezoneOffset(
          lat: event.position.latitude,
          lon: event.position.longitude,
        );

        emit(WeatherBlocSuccess(
          weather: weather, 
          weeklyWeather: weeklyWeather,
          timezoneOffset: realCityOffset,
        ));
      } catch (e) {
        emit(const WeatherBlocFailure("Location Data Not Found"));
      }
    });

    on<FetchWeatherByCity>((event, emit) async {
      emit(WeatherBlocLoading());
      try {
        WeatherFactory wf = _getWeatherFactory();
        
        Weather weather = await wf.currentWeatherByCityName(event.cityName);
        List<Weather> weeklyWeather = await wf.fiveDayForecastByCityName(event.cityName);

        int realCityOffset = await _getRawTimezoneOffset(cityName: event.cityName);
        
        emit(WeatherBlocSuccess(
          weather: weather, 
          weeklyWeather: weeklyWeather,
          timezoneOffset: realCityOffset,
        ));
      } catch (e) {
        emit(const WeatherBlocFailure("City Not Found."));
      }
    });
  }

  WeatherFactory _getWeatherFactory() {
    return WeatherFactory(_apiKey, language: Language.ENGLISH);
  }
  Future<int> _getRawTimezoneOffset({double? lat, double? lon, String? cityName}) async {
    try {
      String url = "";
      if (cityName != null) {
        url = "https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$_apiKey";
      } else {
        url = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['timezone'] ?? 0;
      }
    } catch (e) {
      return 0; 
    }
    return 0;
  }
}