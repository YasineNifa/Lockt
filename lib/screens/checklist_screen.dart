import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/routine.dart';
import '../models/checklist_item.dart';
import '../providers/routine_provider.dart';
import 'camera_screen.dart';
import 'upgrade_screen.dart';

class ChecklistScreen extends StatelessWidget {
  final Routine routine;

  const ChecklistScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Manual Reset',
            onPressed: () {
              // Manual Reset is Free
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset List?'),
                  content: const Text('This will uncheck all items and clear proofs.'),
                  actions: [
                    TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
                    FilledButton(
                      onPressed: () {
                        context.read<RoutineProvider>().manualReset(routine);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
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
            itemCount: routine.items.length + 1,
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
            style: TextButton.styleFrom(foregroundColor: Colors.black),
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

class _ChecklistItemTile extends StatefulWidget {
  final Routine routine;
  final ChecklistItem item;

  const _ChecklistItemTile({required this.routine, required this.item});

  @override
  State<_ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<_ChecklistItemTile> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final provider = context.read<RoutineProvider>();
    if (!provider.isPremium) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
      return;
    }

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        provider.setItemVoiceMemo(widget.routine, widget.item, path);
      }
    } else {
      if (await Permission.microphone.request().isGranted) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = path.join(dir.path, 'voice_${const Uuid().v4()}.m4a');
        
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _playVoiceMemo() async {
    if (widget.item.voiceMemoPath == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.item.voiceMemoPath!));
      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.item.photoPath != null;
    final hasVoice = widget.item.voiceMemoPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.item.isChecked ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardTheme.color,
      child: ListTile(
        onLongPress: () {
          _showItemOptions(context);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: widget.item.isChecked,
          onChanged: (value) {
            context.read<RoutineProvider>().toggleItem(widget.routine, widget.item, value);
          },
          shape: const CircleBorder(),
        ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            decoration: widget.item.isChecked ? TextDecoration.lineThrough : null,
            color: widget.item.isChecked ? Colors.grey : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice Memo Button
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop_circle : (hasVoice ? (_isPlaying ? Icons.pause_circle : Icons.play_circle) : Icons.mic),
                color: _isRecording ? Colors.red : (hasVoice ? Colors.green : Colors.grey),
              ),
              onPressed: hasVoice && !_isRecording ? _playVoiceMemo : _toggleRecording,
            ),
            // Photo Button
            IconButton(
              icon: Icon(
                hasPhoto ? Icons.photo : Icons.camera_alt_outlined,
                color: hasPhoto ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              onPressed: () async {
                final provider = context.read<RoutineProvider>();
                if (!provider.isPremium && !hasPhoto) {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                   return;
                }

                if (hasPhoto) {
                  _showPhotoDialog(context, widget.item.photoPath!);
                } else {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  );
                  if (result != null && result is String) {
                    if (context.mounted) {
                      provider.setItemPhoto(widget.routine, widget.item, result);
                    }
                  }
                }
              },
            ),
            // Menu Button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditItemDialog(context);
                } else if (value == 'delete') {
                  _showDeleteItemDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
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

  void _showItemOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                _showEditItemDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteItemDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Item Name'),
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
                context.read<RoutineProvider>().updateItem(widget.routine, widget.item, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${widget.item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<RoutineProvider>().deleteItem(widget.routine, widget.item);
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
