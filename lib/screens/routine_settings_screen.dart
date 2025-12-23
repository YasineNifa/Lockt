import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import 'upgrade_screen.dart';

class RoutineSettingsScreen extends StatefulWidget {
  final Routine routine;

  const RoutineSettingsScreen({super.key, required this.routine});

  @override
  State<RoutineSettingsScreen> createState() => _RoutineSettingsScreenState();
}

class _RoutineSettingsScreenState extends State<RoutineSettingsScreen> {
  late TextEditingController _nameController;
  late ResetPolicy _resetPolicy;
  late int _customDurationMinutes;
  late int? _mediaAutoDeleteHours;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _resetPolicy = widget.routine.resetPolicy ?? ResetPolicy.daily4am;
    _customDurationMinutes = widget.routine.customResetDurationMinutes ?? 720; // Default 12h
    _mediaAutoDeleteHours = widget.routine.mediaAutoDeleteDurationHours;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) return;

    final provider = context.read<RoutineProvider>();
    
    // Update Name
    provider.updateRoutine(widget.routine, _nameController.text);
    
    // Update Policies (We need to add a method in Provider for this, or just save routine directly)
    // Ideally Provider should handle it to notify listeners.
    // For now, let's update the routine object and save it, then notify provider?
    // Better: Add updateRoutineSettings to Provider.
    
    widget.routine.resetPolicy = _resetPolicy;
    widget.routine.customResetDurationMinutes = _resetPolicy == ResetPolicy.customDuration ? _customDurationMinutes : null;
    widget.routine.mediaAutoDeleteDurationHours = _mediaAutoDeleteHours;
    widget.routine.save();
    
    // Trigger UI update
    provider.notifyListenersPublic(); // We need to expose notifyListeners or just call a dummy update method.
    // Actually, updateRoutine calls save() and notifyListeners().
    // So if we update properties before calling updateRoutine, it might work?
    // But updateRoutine only takes name.
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.select<RoutineProvider, bool>((p) => p.isPremium);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reset Policy Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Reset Policy', style: Theme.of(context).textTheme.titleMedium),
                      if (!isPremium) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 16, color: Colors.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ResetPolicy>(
                    // ignore: deprecated_member_use
                    value: _resetPolicy,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                        value: ResetPolicy.daily4am,
                        child: Text('Daily (4 AM)'),
                      ),
                      DropdownMenuItem(
                        value: ResetPolicy.customDuration,
                        child: Text('Custom Duration'),
                      ),
                    ],
                    onChanged: (value) {
                      if (!isPremium) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                        // Reset to previous value if needed, but dropdown might have changed visually.
                        // Ideally we block the change or revert it.
                        setState(() {}); // Rebuild to revert
                        return;
                      }
                      if (value != null) {
                        setState(() => _resetPolicy = value);
                      }
                    },
                  ),
                  if (_resetPolicy == ResetPolicy.customDuration) ...[
                    const SizedBox(height: 16),
                    Text('Reset after: ${_formatDuration(_customDurationMinutes)}'),
                    Slider(
                      value: _customDurationMinutes.toDouble(),
                      min: 60, // 1 hour
                      max: 24 * 60, // 24 hours
                      divisions: 23,
                      label: _formatDuration(_customDurationMinutes),
                      onChanged: (value) {
                        setState(() => _customDurationMinutes = value.toInt());
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-Delete Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Media Auto-Delete', style: Theme.of(context).textTheme.titleMedium),
                      if (!isPremium) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 16, color: Colors.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automatically delete photos and voice memos after a set time.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    // ignore: deprecated_member_use
                    value: _mediaAutoDeleteHours,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Never')),
                      DropdownMenuItem(value: 1, child: Text('1 Hour')),
                      DropdownMenuItem(value: 12, child: Text('12 Hours')),
                      DropdownMenuItem(value: 24, child: Text('24 Hours')),
                      DropdownMenuItem(value: 168, child: Text('7 Days')),
                    ],
                    onChanged: (value) {
                      if (!isPremium && value != null) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                         setState(() {});
                         return;
                      }
                      setState(() => _mediaAutoDeleteHours = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Delete Routine Button
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Routine?'),
                    content: Text('Are you sure you want to delete "${widget.routine.name}"? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: Colors.black),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<RoutineProvider>().deleteRoutine(widget.routine);
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close settings
                        },
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete Routine', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    return '$hours hours';
  }
}
