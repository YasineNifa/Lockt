import 'package:hive_flutter/hive_flutter.dart';

import '../models/checklist_item.dart';
import '../models/routine.dart';

class StorageService {
  static const String _routineBoxName = 'routines';
  static const String _settingsBoxName = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(ChecklistItemAdapter());
    Hive.registerAdapter(RoutineAdapter());

    await Hive.openBox<Routine>(_routineBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  Box<Routine> get _routineBox => Hive.box<Routine>(_routineBoxName);
  Box get _settingsBox => Hive.box(_settingsBoxName);

  List<Routine> getRoutines() {
    return _routineBox.values.toList();
  }

  Future<void> saveRoutine(Routine routine) async {
    if (routine.isInBox) {
      await routine.save();
    } else {
      await _routineBox.add(routine);
    }
  }

  Future<void> deleteRoutine(Routine routine) async {
    await routine.delete();
  }

  // Daily Reset Logic
  Future<void> checkAndResetDaily() async {
    final lastReset = _settingsBox.get('lastReset', defaultValue: 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // If last reset was before today (e.g. yesterday or never)
    if (lastReset < today.millisecondsSinceEpoch) {
      await _resetAllItems();
      await _settingsBox.put('lastReset', today.millisecondsSinceEpoch);
    }
  }

  Future<void> _resetAllItems() async {
    final routines = getRoutines();
    for (var routine in routines) {
      bool changed = false;
      for (var item in routine.items) {
        if (item.isChecked || item.photoPath != null) {
          item.isChecked = false;
          item.checkedAt = null;
          // Note: We might want to delete the actual photo file here to save space
          // But for now, just clearing the path reference is enough for the logic
          item.photoPath = null; 
          changed = true;
        }
      }
      if (changed) {
        await routine.save();
      }
    }
  }
}
