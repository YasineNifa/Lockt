import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
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
  bool get isPremium => _storageService.isPremium;

  void _loadRoutines() {
    _routines = _storageService.getRoutines();
    notifyListeners();
    _updateWidget();
  }

  Future<void> setPremium(bool value) async {
    await _storageService.setPremium(value);
    notifyListeners();
    _updateWidget();
  }

  Future<bool> canAddRoutine() async {
    if (isPremium) return true;
    return _routines.isEmpty; // Free limit: 1 routine
  }

  Future<void> addRoutine(String name, int iconPoint, int colorPoint) async {
    if (!await canAddRoutine()) return;

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
    _updateWidget();
  }

  Future<void> toggleItem(Routine routine, ChecklistItem item, bool? value) async {
    item.isChecked = value ?? false;
    item.checkedAt = item.isChecked ? DateTime.now() : null;
    if (!item.isChecked) {
      item.photoPath = null;
      item.voiceMemoPath = null;
    }
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> setItemPhoto(Routine routine, ChecklistItem item, String path) async {
    item.photoPath = path;
    item.isChecked = true;
    item.checkedAt = DateTime.now();
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> setItemVoiceMemo(Routine routine, ChecklistItem item, String path) async {
    item.voiceMemoPath = path;
    item.voiceMemoCreatedAt = DateTime.now();
    item.isChecked = true;
    item.checkedAt = DateTime.now();
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> manualReset(Routine routine) async {
    for (var item in routine.items) {
      item.isChecked = false;
      item.checkedAt = null;
      item.photoPath = null;
      item.voiceMemoPath = null;
      item.voiceMemoCreatedAt = null;
    }
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> checkDailyReset() async {
    await _storageService.checkAndReset();
    _loadRoutines();
  }

  Future<void> _updateWidget() async {
    if (!isPremium) return;
    
    int totalUnchecked = 0;
    for (var routine in _routines) {
      totalUnchecked += routine.items.where((i) => !i.isChecked).length;
    }

    final status = totalUnchecked == 0 ? "All OK ✅" : "$totalUnchecked items left";
    
    try {
      await HomeWidget.saveWidgetData<String>('status', status);
      await HomeWidget.updateWidget(
        name: 'LocktWidget',
        iOSName: 'LocktWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
