import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'checklist_item.dart';

part 'routine.g.dart';

@HiveType(typeId: 2)
enum ResetPolicy {
  @HiveField(0)
  daily4am,
  @HiveField(1)
  customDuration,
}

@HiveType(typeId: 1)
class Routine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<ChecklistItem> items;

  @HiveField(3)
  int iconPoint;

  @HiveField(4)
  int colorPoint;

  @HiveField(5)
  ResetPolicy? resetPolicy;

  @HiveField(6)
  int? customResetDurationMinutes; // Stored in minutes for simplicity

  @HiveField(7)
  int? mediaAutoDeleteDurationHours; // Stored in hours

  Routine({
    required this.id,
    required this.name,
    required this.items,
    required this.iconPoint,
    required this.colorPoint,
    this.resetPolicy = ResetPolicy.daily4am,
    this.customResetDurationMinutes,
    this.mediaAutoDeleteDurationHours,
  });

  factory Routine.create({
    required String name,
    required int iconPoint,
    required int colorPoint,
  }) {
    return Routine(
      id: const Uuid().v4(),
      name: name,
      items: [],
      iconPoint: iconPoint,
      colorPoint: colorPoint,
    );
  }
}
