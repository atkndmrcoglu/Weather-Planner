import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bloc/weather_bloc_bloc.dart';
import 'map_components/map_bloc/routing_bloc.dart';
import 'ai_planner_components/bloc/ai_planner_bloc.dart';
import 'ai_planner_components/data/repositories/ai_planner_repository.dart';
import 'widgets/bottom_navigation.dart';
import 'utils/time_manager.dart';
import '../map_components/map_models/saved_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SavedRouteAdapter());
  await Hive.openBox<SavedRoute>('saved_routes_box');
  await initializeDateFormatting('tr_TR', null); 
  TimeManager().init(); 

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => WeatherBlocBloc()),
        BlocProvider(create: (context) => RoutingBloc()),
        BlocProvider(create: (context) => AIPlannerBloc(AIPlannerRepository())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const BottomNavigator(),
      ),
    );
  }
}