import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/clean_provider.dart';
import 'providers/deep_scan_provider.dart';
import 'providers/large_file_provider.dart';
import 'providers/software_provider.dart';
import 'providers/analysis_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CleanProvider()),
        ChangeNotifierProvider(create: (_) => DeepScanProvider()),
        ChangeNotifierProvider(create: (_) => LargeFileProvider()),
        ChangeNotifierProvider(create: (_) => SoftwareProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const DiskCleanerApp(),
    ),
  );
}

class DiskCleanerApp extends StatelessWidget {
  const DiskCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C 盘卫士 - 专业清理工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4A6CF7),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Microsoft YaHei',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6CF7),
          primary: const Color(0xFF4A6CF7),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
