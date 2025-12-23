import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../models/checklist_item.dart';
import '../providers/routine_provider.dart';
import 'camera_screen.dart';

class ChecklistScreen extends StatelessWidget {
  final Routine routine;

  const ChecklistScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          // Re-fetch routine from provider to ensure we have latest state if needed
          // Ideally we rely on the object being updated in place since it's a HiveObject
          // but provider.routines is the source of truth for the list.
          // For now, using the passed routine object is fine as Hive objects update in place.
          
          if (routine.items.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No items yet', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => _showAddItemDialog(context),
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routine.items.length + 1, // +1 for the Add button at bottom
            itemBuilder: (context, index) {
              if (index == routine.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                );
              }

              final item = routine.items[index];
              return _ChecklistItemTile(routine: routine, item: item);
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Check Stove'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<RoutineProvider>().addItem(routine, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  final Routine routine;
  final ChecklistItem item;

  const _ChecklistItemTile({required this.routine, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.isChecked ? const Color(0xFF2C2C2C) : Theme.of(context).cardTheme.color,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (value) {
            context.read<RoutineProvider>().toggleItem(routine, item, value);
          },
          shape: const CircleBorder(),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            item.photoPath != null ? Icons.photo : Icons.camera_alt_outlined,
            color: item.photoPath != null ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          onPressed: () async {
            if (item.photoPath != null) {
              _showPhotoDialog(context, item.photoPath!);
            } else {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
              if (result != null && result is String) {
                if (context.mounted) {
                  context.read<RoutineProvider>().setItemPhoto(routine, item, result);
                }
              }
            }
          },
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(path)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
