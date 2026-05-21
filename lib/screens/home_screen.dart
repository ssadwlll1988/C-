import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';
import 'basic_clean_tab.dart';
import 'deep_scan_tab.dart';
import 'large_file_tab.dart';
import 'software_tab.dart';
import 'analysis_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem('一键清理', Icons.cleaning_services_outlined,
        Icons.cleaning_services),
    _NavItem('深度扫描', Icons.travel_explore_outlined, Icons.travel_explore),
    _NavItem('大文件管理', Icons.insert_drive_file_outlined,
        Icons.insert_drive_file),
    _NavItem('软件搬家', Icons.drive_file_move_outlined,
        Icons.drive_file_move),
    _NavItem('C 盘分析', Icons.donut_large_outlined, Icons.donut_large),
  ];

  static const List<Widget> _pages = [
    BasicCleanTab(),
    DeepScanTab(),
    LargeFileTab(),
    SoftwareTab(),
    AnalysisTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F7FA),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2235), Color(0xFF2A2F4A)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A6CF7), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cleaning_services,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('C 盘卫士',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 28),
          for (int i = 0; i < _navItems.length; i++)
            _buildNavTile(i, _navItems[i]),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.verified_user,
                          color: Color(0xFF00B894), size: 14),
                      SizedBox(width: 4),
                      Text('系统状态',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('运行良好',
                      style: TextStyle(
                          color: Color(0xFF00B894),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int idx, _NavItem item) {
    final selected = _selectedIndex == idx;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = idx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF4A6CF7), Color(0xFF6C5CE7)])
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(selected ? item.activeIcon : item.icon,
                color: selected ? Colors.white : Colors.white70, size: 18),
            const SizedBox(width: 10),
            Text(item.label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436)),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('专业版',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4A6CF7),
                    fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Consumer<CleanProvider>(
            builder: (context, p, _) => Row(
              children: [
                const Icon(Icons.storage,
                    size: 16, color: Color(0xFF636E72)),
                const SizedBox(width: 6),
                Text(
                  _parseDiskInfo(p.diskInfo),
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF636E72),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _parseDiskInfo(String raw) {
    if (raw.isEmpty || raw.contains('N/A')) return '正在读取磁盘信息...';
    return raw
        .replaceAll('FREE', '可用')
        .replaceAll('TOTAL', '总容量')
        .replaceAll('/', '|');
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}
