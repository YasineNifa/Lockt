import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/routine_provider.dart';

import 'screens/home_screen.dart';
import 'utils/theme.dart';

import 'providers/revenue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();
  await storageService.checkAndReset();

  final revenueProvider = RevenueProvider();
  await revenueProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: revenueProvider),
        ChangeNotifierProvider(create: (_) => RoutineProvider(storageService, revenueProvider)),
      ],
      child: const LocktApp(),
    ),
  );
}

class LocktApp extends StatefulWidget {
  const LocktApp({super.key});

  @override
  State<LocktApp> createState() => _LocktAppState();
}

class _LocktAppState extends State<LocktApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for resets when app comes to foreground
      context.read<RoutineProvider>().checkDailyReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lockt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force Light Mode for "Zen Green"
      home: const HomeScreen(),
    );
  }
}
