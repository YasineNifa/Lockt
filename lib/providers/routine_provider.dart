import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/checklist_item.dart';
import '../services/storage_service.dart';

class RoutineProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Routine> _routines = [];

  RoutineProvider(this._storageService) {
    _loadRoutines();
  }

  List<Routine> get routines => _routines;

  void _loadRoutines() {
    _routines = _storageService.getRoutines();
    notifyListeners();
  }

  Future<void> addRoutine(String name, int iconPoint, int colorPoint) async {
    final newRoutine = Routine.create(
      name: name,
      iconPoint: iconPoint,
      colorPoint: colorPoint,
    );
    await _storageService.saveRoutine(newRoutine);
    _loadRoutines();
  }

  Future<void> deleteRoutine(Routine routine) async {
    await _storageService.deleteRoutine(routine);
    _loadRoutines();
  }

  Future<void> addItem(Routine routine, String name) async {
    final newItem = ChecklistItem.create(name: name);
    routine.items.add(newItem);
    await routine.save();
    notifyListeners();
  }

  Future<void> toggleItem(Routine routine, ChecklistItem item, bool? value) async {
    item.isChecked = value ?? false;
    item.checkedAt = item.isChecked ? DateTime.now() : null;
    if (!item.isChecked) {
      item.photoPath = null; // Clear photo if unchecked
    }
    await routine.save();
    notifyListeners();
  }

  Future<void> setItemPhoto(Routine routine, ChecklistItem item, String path) async {
    item.photoPath = path;
    item.isChecked = true; // Taking a photo implies checking it
    item.checkedAt = DateTime.now();
    await routine.save();
    notifyListeners();
  }

  Future<void> checkDailyReset() async {
    await _storageService.checkAndResetDaily();
    _loadRoutines();
  }
}
