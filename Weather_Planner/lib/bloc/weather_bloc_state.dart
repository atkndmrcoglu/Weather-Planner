part of 'weather_bloc_bloc.dart';

sealed class WeatherBlocState extends Equatable {
  const WeatherBlocState();
  @override
  List<Object> get props => [];
}

final class WeatherBlocInitial extends WeatherBlocState {}
final class WeatherBlocLoading extends WeatherBlocState {}
final class WeatherBlocFailure extends WeatherBlocState {
  final String message;
  const WeatherBlocFailure(this.message);
  @override
  List<Object> get props => [message];
}

final class WeatherBlocSuccess extends WeatherBlocState {
  final Weather weather;
  final List<Weather> weeklyWeather;
  final int timezoneOffset; 
  final String timezoneName;

  const WeatherBlocSuccess({
    required this.weather,
    required this.weeklyWeather,
    this.timezoneOffset = 0,
    this.timezoneName = '',
  });

  @override
  List<Object> get props => [weather, weeklyWeather, timezoneOffset, timezoneName];
}