import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/routine.dart';
import '../models/checklist_item.dart';
import '../providers/routine_provider.dart';
import 'upgrade_screen.dart';
import 'routine_settings_screen.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          final routine = provider.selectedRoutine;

          if (routine == null) {
            return _buildEmptyState(context);
          }

          // Check for completion to trigger confetti
          final allChecked = routine.items.isNotEmpty && routine.items.every((i) => i.isChecked);
          if (allChecked && _confettiController.state != ConfettiControllerState.playing) {
            // Only play if we just transitioned? For now, play if all checked.
            // Better: Play only once. But let's leave it simple.
            // Actually, playing on every build is bad.
            // We should track previous state or just let the user trigger it manually?
            // User said: "Lancer une petite animation... Si l'utilisateur a tout coché".
            // Let's trigger it in the post-frame callback if not playing.
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (_confettiController.state == ConfettiControllerState.stopped) {
                 _confettiController.play();
               }
             });
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Zone 1: Hero Section (Top)
                  _buildHeroSection(context, provider, routine),
                  
                  // Zone 2: Smart List (Center)
                  Expanded(
                    child: _buildSmartList(context, provider, routine),
                  ),
                  
                  // Zone 3: Actions (Bottom)
                  _buildBottomActions(context, provider, routine),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Welcome to Lockt',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Create your first routine to get started.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddRoutineDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Routine'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, RoutineProvider provider, Routine routine) {
    final completedCount = routine.items.where((i) => i.isChecked).length;
    final totalCount = routine.items.length;
    final isComplete = totalCount > 0 && completedCount == totalCount;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // Optional: Add subtle gradient or shadow
      ),
      child: Column(
        children: [
          // AppBar-like Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RoutineSettingsScreen(routine: routine)),
                  );
                },
              ),
              if (!provider.isPremium)
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                  icon: const Icon(Icons.star, color: Colors.amber, size: 16),
                  label: const Text('PRO', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(width: 48), // Spacer
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Circular Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  // ignore: deprecated_member_use
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? const Color(0xFF66BB6A) : Colors.orange,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isComplete)
                    const Icon(Icons.verified_user, size: 40, color: Color(0xFF66BB6A))
                  else
                    Text(
                      '$completedCount / $totalCount',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Greeting / Status
          Text(
            isComplete ? 'SECURED' : 'Verification in progress...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isComplete ? const Color(0xFF66BB6A) : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isComplete ? "Everything is under control." : "Hello, ready to go?",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          
          const SizedBox(height: 24),
          
          // Routine Selector
          PopupMenuButton<Routine>(
            initialValue: routine,
            onSelected: (Routine r) {
              provider.selectRoutine(r.id);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  routine.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
            itemBuilder: (context) => provider.routines.map((r) {
              return PopupMenuItem<Routine>(
                value: r,
                child: Row(
                  children: [
                    if (r.id == routine.id) ...[
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                    ],
                    Text(r.name),
                    if (!provider.isPremium && provider.routines.indexOf(r) > 0) ...[
                       const Spacer(),
                       const Icon(Icons.lock, size: 16, color: Colors.amber),
                    ],
                  ],
                ),
              );
            }).toList()
              ..add(
                const PopupMenuItem<Routine>(
                  value: null,
                  enabled: false, // It's an action, not a selection
                  child: Divider(),
                ),
              )
              ..add(
                 PopupMenuItem<Routine>(
                  value: null,
                  onTap: () {
                    // Delay to allow menu to close
                    Future.delayed(Duration.zero, () {
                      if (context.mounted) _showAddRoutineDialog(context);
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text('New Routine'),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartList(BuildContext context, RoutineProvider provider, Routine routine) {
    if (routine.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No items yet'),
            TextButton(
              onPressed: () => _showAddItemDialog(context, routine),
              child: const Text('Add your first item'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: routine.items.length,
      itemBuilder: (context, index) {
        final item = routine.items[index];
        return _SmartListItem(routine: routine, item: item);
      },
    );
  }

  Widget _buildBottomActions(BuildContext context, RoutineProvider provider, Routine routine) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset Button
          TextButton.icon(
            onPressed: () {
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
                        provider.manualReset(routine);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
          ),

          // Add FAB
          FloatingActionButton(
            onPressed: () => _showAddItemDialog(context, routine),
            elevation: 2,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
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
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newRoutine = await provider.addRoutine(
                  controller.text,
                  Icons.home.codePoint,
                  0xFF2196F3,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (newRoutine != null) {
                    // Slight delay to allow UI to rebuild with new routine selected
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        _showAddItemDialog(context, newRoutine);
                      }
                    });
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, Routine routine) {
    final controller = TextEditingController();
    int? selectedIconPoint;

    final List<IconData> icons = [
      Icons.circle_outlined,
      Icons.local_fire_department,
      Icons.vpn_key,
      Icons.window,
      Icons.power,
      Icons.water_drop,
      Icons.pets,
      Icons.child_care,
      Icons.garage,
      Icons.lightbulb,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Item'),
            scrollable: true,
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'e.g., Check Stove'),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: icons.map((icon) {
                        final isSelected = (selectedIconPoint == null && icon == Icons.circle_outlined) || 
                                           (selectedIconPoint == icon.codePoint);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedIconPoint = icon == Icons.circle_outlined ? null : icon.codePoint;
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
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
                    context.read<RoutineProvider>().addItem(
                      routine, 
                      controller.text,
                      iconPoint: selectedIconPoint,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SmartListItem extends StatefulWidget {
  final Routine routine;
  final ChecklistItem item;

  const _SmartListItem({required this.routine, required this.item});

  @override
  State<_SmartListItem> createState() => _SmartListItemState();
}

class _SmartListItemState extends State<_SmartListItem> {
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
              style: TextButton.styleFrom(foregroundColor: Colors.black),
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.item.photoPath != null;
    final hasVoice = widget.item.voiceMemoPath != null;
    final isChecked = widget.item.isChecked;

    return Card(
      elevation: 0,
      color: isChecked ? const Color(0xFFE8F5E9) : Colors.white, // Light Green if checked
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isChecked ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onLongPress: () => _showItemOptions(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon (Left)
              Icon(
                widget.item.iconPoint != null 
                    ? IconData(widget.item.iconPoint!, fontFamily: 'MaterialIcons') 
                    : Icons.circle_outlined, // Generic default
                color: isChecked ? const Color(0xFF66BB6A) : Colors.grey,
              ),
              const SizedBox(width: 16),
              
              // Name (Expanded)
              Expanded(
                child: Text(
                  widget.item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isChecked ? const Color(0xFF2E3E2E) : Colors.black,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              
              // Proof Indicators (Center/Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop_circle : (hasVoice ? (_isPlaying ? Icons.pause_circle : Icons.play_circle) : Icons.mic_none),
                      size: 20,
                      color: _isRecording ? Colors.red : (hasVoice ? Colors.blue : Colors.grey[800]),
                    ),
                    onPressed: hasVoice && !_isRecording ? _playVoiceMemo : _toggleRecording,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Photo
                  IconButton(
                    icon: Icon(
                      hasPhoto ? Icons.photo : Icons.camera_alt_outlined,
                      size: 20,
                      color: hasPhoto ? Colors.blue : Colors.grey[800],
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Checkbox (Right)
              Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    if (value == true) {
                      HapticFeedback.mediumImpact();
                    }
                    context.read<RoutineProvider>().toggleItem(widget.routine, widget.item, value);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: const Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
