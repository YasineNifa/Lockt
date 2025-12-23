import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/routine_provider.dart';
import 'screens/routine_list_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();
  await storageService.checkAndResetDaily();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoutineProvider(storageService)),
      ],
      child: const LocktApp(),
    ),
  );
}

class LocktApp extends StatelessWidget {
  const LocktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lockt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RoutineListScreen(),
    );
  }
}
