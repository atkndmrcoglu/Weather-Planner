import 'package:hive/hive.dart';
part 'saved_routes.g.dart'; 

@HiveType(typeId: 1)
class SavedRoute extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<List<double>> points;

  @HiveField(3)
  final DateTime createdAt;

  SavedRoute({
    required this.id,
    required this.title,
    required this.points,
    required this.createdAt,
  });
}