import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/routine.dart';
import '../models/checklist_item.dart';
import '../services/storage_service.dart';
import 'revenue_provider.dart';

class RoutineProvider extends ChangeNotifier {
  final StorageService _storageService;
  final RevenueProvider _revenueProvider;
  List<Routine> _routines = [];
  String? _selectedRoutineId;

  RoutineProvider(this._storageService, this._revenueProvider) {
    _loadRoutines();
    _revenueProvider.addListener(_onPremiumChange);
  }

  void _onPremiumChange() {
    notifyListeners();
    _updateWidget();
  }

  @override
  void dispose() {
    _revenueProvider.removeListener(_onPremiumChange);
    super.dispose();
  }

  List<Routine> get routines => _routines;
  
  Routine? get selectedRoutine {
    if (_routines.isEmpty) return null;
    if (_selectedRoutineId == null) return _routines.first;
    try {
      return _routines.firstWhere((r) => r.id == _selectedRoutineId);
    } catch (e) {
      // If the selected routine ID no longer exists, default to the first one.
      return _routines.first;
    }
  }

  void selectRoutine(String id) {
    _selectedRoutineId = id;
    notifyListeners();
  }

  bool get isPremium => _revenueProvider.isPremium;

  void _loadRoutines() {
    _routines = _storageService.getRoutines();
    // Ensure _selectedRoutineId is valid after loading routines
    if (_selectedRoutineId != null && !_routines.any((r) => r.id == _selectedRoutineId)) {
      _selectedRoutineId = _routines.isNotEmpty ? _routines.first.id : null;
    } else if (_selectedRoutineId == null && _routines.isNotEmpty) {
      _selectedRoutineId = _routines.first.id;
    } else if (_routines.isEmpty) {
      _selectedRoutineId = null;
    }
    notifyListeners();
    _updateWidget();
  }

  // Deprecated: Use RevenueProvider.restorePurchases() or showPaywall()
  Future<void> setPremium(bool value) async {
    // await _storageService.setPremium(value);
    // notifyListeners();
    // _updateWidget();
    debugPrint("setPremium is deprecated. Use RevenueCat.");
  }

  Future<bool> canAddRoutine() async {
    if (isPremium) return true;
    return _routines.isEmpty; // Free limit: 1 routine
  }

  Future<Routine?> addRoutine(String name, int iconPoint, int colorPoint) async {
    if (!await canAddRoutine()) return null;

    final newRoutine = Routine.create(
      name: name,
      iconPoint: iconPoint,
      colorPoint: colorPoint,
    );
    await _storageService.saveRoutine(newRoutine);
    _loadRoutines();
    selectRoutine(newRoutine.id);
    return newRoutine;
  }

  Future<void> deleteRoutine(Routine routine) async {
    await _storageService.deleteRoutine(routine);
    _loadRoutines();
  }

  Future<void> updateRoutine(Routine routine, String name) async {
    routine.name = name;
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> updateItem(Routine routine, ChecklistItem item, String name) async {
    item.name = name;
    await routine.save();
    notifyListeners();
  }

  Future<void> deleteItem(Routine routine, ChecklistItem item) async {
    routine.items.remove(item);
    // Also delete media files if any
    if (item.photoPath != null) {
      await _storageService.deleteFile(item.photoPath!);
    }
    if (item.voiceMemoPath != null) {
      await _storageService.deleteFile(item.voiceMemoPath!);
    }
    await routine.save();
    notifyListeners();
    _updateWidget();
  }

  Future<void> addItem(Routine routine, String name, {int? iconPoint}) async {
    final newItem = ChecklistItem.create(name: name, iconPoint: iconPoint);
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
    try {
      final routines = _storageService.getRoutines();
      int totalUnchecked = 0;
      for (var routine in routines) {
        totalUnchecked += routine.items.where((i) => !i.isChecked).length;
      }

      final message = totalUnchecked == 0 ? "All OK ✅" : "$totalUnchecked items left";
      
      await HomeWidget.saveWidgetData<String>('app_status', message);
      await HomeWidget.updateWidget(
        name: 'LocktWidget',
        iOSName: 'LocktWidget',
        androidName: 'LocktWidget',
      );
    } catch (e) {
      debugPrint("Error updating widget: $e");
    }
  }

  void notifyListenersPublic() {
    notifyListeners();
  }
}
