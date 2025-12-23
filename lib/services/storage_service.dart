import 'dart:io';
import 'package:flutter/foundation.dart';
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
    Hive.registerAdapter(ResetPolicyAdapter());

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

  bool get isPremium => _settingsBox.get('isPremium', defaultValue: false);
  Future<void> setPremium(bool value) async => _settingsBox.put('isPremium', value);

  // Smart Reset Logic
  Future<void> checkAndReset() async {
    final now = DateTime.now();
    final routines = getRoutines();

    for (var routine in routines) {
      bool changed = false;

      // 1. Reset Logic
      final policy = routine.resetPolicy ?? ResetPolicy.daily4am;
      
      if (policy == ResetPolicy.daily4am) {
        // Daily 4AM Logic
        final lastReset = _settingsBox.get('lastReset_${routine.id}', defaultValue: 0);
        final today4am = DateTime(now.year, now.month, now.day, 4);
        final resetTime = now.isBefore(today4am) 
            ? today4am.subtract(const Duration(days: 1)) 
            : today4am;

        if (lastReset < resetTime.millisecondsSinceEpoch) {
          _resetItems(routine);
          _settingsBox.put('lastReset_${routine.id}', now.millisecondsSinceEpoch);
          changed = true;
        }
      } else if (policy == ResetPolicy.customDuration) {
        // Custom Duration Logic (e.g., reset 12 hours after checking)
        // This is tricky because items might be checked at different times.
        // Simplified: If ALL items are checked (or any item?), reset if time elapsed?
        // Better: Reset individual items? No, usually a routine resets as a whole.
        // Let's implement: If the *last* interaction was > duration ago, reset.
        // For now, let's stick to: If any item is checked and it's been > duration since checkedAt, reset IT.
        final durationMinutes = routine.customResetDurationMinutes ?? 720; // Default 12h
        for (var item in routine.items) {
          if (item.isChecked && item.checkedAt != null) {
            final diff = now.difference(item.checkedAt!);
            if (diff.inMinutes >= durationMinutes) {
              _resetItem(item);
              changed = true;
            }
          }
        }
      }

      // 2. Auto-Delete Media Logic
      if (isPremium && routine.mediaAutoDeleteDurationHours != null) {
        final deleteDuration = Duration(hours: routine.mediaAutoDeleteDurationHours!);
        for (var item in routine.items) {
          // Check Photo
          if (item.photoPath != null && item.checkedAt != null) {
             if (now.difference(item.checkedAt!) > deleteDuration) {
               await deleteFile(item.photoPath!);
               item.photoPath = null;
               changed = true;
             }
          }
          // Check Audio
          if (item.voiceMemoPath != null && item.voiceMemoCreatedAt != null) {
             if (now.difference(item.voiceMemoCreatedAt!) > deleteDuration) {
               await deleteFile(item.voiceMemoPath!);
               item.voiceMemoPath = null;
               item.voiceMemoCreatedAt = null;
               changed = true;
             }
          }
        }
      }

      if (changed) {
        await routine.save();
      }
    }
  }

  void _resetItems(Routine routine) {
    for (var item in routine.items) {
      _resetItem(item);
    }
  }

  void _resetItem(ChecklistItem item) {
    item.isChecked = false;
    item.checkedAt = null;
    // We don't delete media on reset, only on auto-delete policy or manual uncheck?
    // Spec says: "Reset Automatique: La liste se décoche".
    // Usually we keep the proof until next check? Or clear it?
    // Let's clear it to be safe/clean.
    item.photoPath = null;
    item.voiceMemoPath = null;
    item.voiceMemoCreatedAt = null;
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
