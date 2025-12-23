import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../models/routine.dart';
import 'checklist_screen.dart';
import 'upgrade_screen.dart';
import 'routine_settings_screen.dart';

class RoutineListScreen extends StatelessWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockt'),
        actions: [
          Consumer<RoutineProvider>(
            builder: (context, provider, _) {
              if (provider.isPremium) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                icon: const Icon(Icons.star, color: Colors.amber),
                label: const Text('Premium', style: TextStyle(color: Colors.amber)),
              );
            },
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          if (provider.routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No routines yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create one to get started', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.routines.length,
            itemBuilder: (context, index) {
              final routine = provider.routines[index];
              return _RoutineCard(routine: routine);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoutineDialog(context),
        label: const Text('New Routine'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) async {
    final provider = context.read<RoutineProvider>();
    if (!await provider.canAddRoutine()) {
    if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
      return;
    }

    final controller = TextEditingController();
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Routine'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Leaving Home'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<RoutineProvider>().addRoutine(
                  controller.text,
                  Icons.home.codePoint, // Default icon
                  0xFF2196F3, // Default color (Blue)
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;

  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final completedCount = routine.items.where((i) => i.isChecked).length;
    final totalCount = routine.items.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChecklistScreen(routine: routine)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(IconData(routine.iconPoint, fontFamily: 'MaterialIcons'), size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineSettingsScreen(routine: routine),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteRoutineDialog(context, routine);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'settings', child: Text('Settings')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                // ignore: deprecated_member_use
                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '$completedCount / $totalCount completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showDeleteRoutineDialog(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<RoutineProvider>().deleteRoutine(routine);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
