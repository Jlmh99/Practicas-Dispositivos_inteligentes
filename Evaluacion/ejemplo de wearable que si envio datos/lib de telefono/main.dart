import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/monitor_screen.dart';

void main() {
  runApp(const ProviderScope(child: TelefonoApp()));
}

class TelefonoApp extends StatelessWidget {
  const TelefonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor Actividad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MonitorScreen(),
    );
  }
}