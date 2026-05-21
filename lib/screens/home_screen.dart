import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';
import 'basic_clean_tab.dart';
import 'deep_scan_tab.dart';
import 'large_file_tab.dart';
import 'software_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🧹 C盘清理大师', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Consumer<CleanProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.diskInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🧹 基础清理'),
            Tab(text: '🔍 深度扫描'),
            Tab(text: '📁 大文件管理'),
            Tab(text: '💻 软件管理'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BasicCleanTab(),
          DeepScanTab(),
          LargeFileTab(),
          SoftwareTab(),
        ],
      ),
    );
  }
}