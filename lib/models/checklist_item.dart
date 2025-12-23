import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'checklist_item.g.dart';

@HiveType(typeId: 0)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isChecked;

  @HiveField(3)
  DateTime? checkedAt;

  @HiveField(4)
  String? photoPath;

  @HiveField(5)
  String? voiceMemoPath;

  @HiveField(6)
  DateTime? voiceMemoCreatedAt;

  @HiveField(8)
  int? iconPoint;

  ChecklistItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.checkedAt,
    this.photoPath,
    this.iconPoint,
    this.voiceMemoPath,
    this.voiceMemoCreatedAt,
  });

  factory ChecklistItem.create({required String name, int? iconPoint}) {
    return ChecklistItem(
      id: const Uuid().v4(),
      name: name,
      iconPoint: iconPoint,
    );
  }
}
