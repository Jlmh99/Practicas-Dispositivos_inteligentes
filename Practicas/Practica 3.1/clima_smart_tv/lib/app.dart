import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/home_screen.dart';

class ClimaSmartTVApp extends StatelessWidget {
  const ClimaSmartTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima Smart TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}