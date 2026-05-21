import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/disk_utils.dart';

class ScanCategory {
  final String id;
  final String name;
  final String desc;
  final List<String> paths;
  final bool safe;
  final String icon;
  final String category;
  final String? scanType;

  ScanCategory({
    required this.id,
    required this.name,
    required this.desc,
    required this.paths,
    required this.safe,
    required this.icon,
    required this.category,
    this.scanType,
  });
}

class CleanProvider with ChangeNotifier {
  List<ScanCategory> _scanCategories = [];
  Map<String, int> _scanResults = {};
  Map<String, List<String>> _scanPaths = {};
  bool _isScanning = false;
  bool _isCleaning = false;
  double _progress = 0.0;
  String _statusText = '就绪 - 点击「扫描垃圾文件」开始';
  String _diskInfo = '';
  Map<String, bool> _selectedItems = {};

  CleanProvider() {
    _initializeScanCategories();
    _loadDiskInfo();
  }

  void _initializeScanCategories() {
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final appData = Platform.environment['APPDATA'] ?? '';
    final temp = Platform.environment['TEMP'] ?? '';

    _scanCategories = [
      ScanCategory(
        id: 'temp_user',
        name: '用户临时文件',
        desc: 'Temp目录下的临时文件',
        paths: ['$userProfile\\AppData\\Local\\Temp'],
        safe: true,
        icon: '📄',
        category: '系统临时',
      ),
      ScanCategory(
        id: 'temp_windows',
        name: 'Windows临时文件',
        desc: 'C:\\Windows\\Temp 下的临时文件',
        paths: ['C:\\Windows\\Temp'],
        safe: true,
        icon: '📄',
        category: '系统临时',
      ),
      ScanCategory(
        id: 'crash_dumps',
        name: '崩溃转储文件',
        desc: '应用程序崩溃产生的dump文件',
        paths: [
          '$localAppData\\CrashDumps',
          'C:\\Windows\\Minidump',
          'C:\\Windows\\MEMORY.DMP',
          '$localAppData\\Microsoft\\Windows\\WER',
          'C:\\ProgramData\\Microsoft\\Windows\\WER'
        ],
        safe: true,
        icon: '💥',
        category: '系统临时',
      ),
      ScanCategory(
        id: 'windows_update',
        name: 'Windows更新缓存',
        desc: '已下载的Windows更新安装包',
        paths: ['C:\\Windows\\SoftwareDistribution\\Download'],
        safe: true,
        icon: '🔄',
        category: '系统缓存',
      ),
      ScanCategory(
        id: 'recycle_bin',
        name: '回收站',
        desc: '已删除但未清空的文件',
        paths: ['C:\\\$Recycle.Bin'],
        safe: true,
        icon: '🗑️',
        category: '系统缓存',
      ),
      // Add more categories as needed
    ];
  }

  Future<void> _loadDiskInfo() async {
    _diskInfo = await DiskUtils.getDiskInfo();
    notifyListeners();
  }

  List<ScanCategory> get scanCategories => _scanCategories;
  Map<String, int> get scanResults => _scanResults;
  Map<String, List<String>> get scanPaths => _scanPaths;
  bool get isScanning => _isScanning;
  bool get isCleaning => _isCleaning;
  double get progress => _progress;
  String get statusText => _statusText;
  String get diskInfo => _diskInfo;
  Map<String, bool> get selectedItems => _selectedItems;

  Future<void> startScan() async {
    if (_isScanning || _isCleaning) return;

    _isScanning = true;
    _scanResults.clear();
    _scanPaths.clear();
    _selectedItems.clear();
    _progress = 0.0;
    _statusText = '🔍 正在扫描...';
    notifyListeners();

    for (int i = 0; i < _scanCategories.length; i++) {
      final category = _scanCategories[i];
      int totalSize = 0;
      List<String> foundPaths = [];

      for (final path in category.paths) {
        if (Directory(path).existsSync() || File(path).existsSync()) {
          final size = await DiskUtils.getDirSize(path);
          if (size > 0) {
            totalSize += size;
            foundPaths.add(path);
          }
        }
      }

      _scanResults[category.id] = totalSize;
      _scanPaths[category.id] = foundPaths;
      _selectedItems[category.id] = category.safe && totalSize > 0;

      _progress = (i + 1) / _scanCategories.length;
      _statusText = '🔍 正在扫描: ${category.name} (${i + 1}/${_scanCategories.length})';
      notifyListeners();
    }

    _isScanning = false;
    _progress = 1.0;
    _statusText = '✅ 扫描完成！共发现 ${_formatTotalSize()} 可清理空间';
    await _loadDiskInfo();
    notifyListeners();
  }

  String _formatTotalSize() {
    int total = 0;
    for (final entry in _selectedItems.entries) {
      if (entry.value && _scanResults.containsKey(entry.key)) {
        total += _scanResults[entry.key]!;
      }
    }
    return DiskUtils.formatSize(total);
  }

  Future<void> startClean() async {
    final selected = _selectedItems.entries
        .where((e) => e.value && _scanResults.containsKey(e.key) && _scanResults[e.key]! > 0)
        .map((e) => e.key)
        .toList();

    if (selected.isEmpty) {
      _statusText = '⚠️ 没有选中可清理的项目，请勾选后再点击';
      notifyListeners();
      return;
    }

    _isCleaning = true;
    _statusText = '正在清理 ${selected.length} 个项目...';
    notifyListeners();

    int totalFreed = 0;
    for (int i = 0; i < selected.length; i++) {
      final categoryId = selected[i];
      final category = _scanCategories.firstWhere((c) => c.id == categoryId);
      
      _statusText = '正在清理: ${category.name} (${i + 1}/${selected.length})';
      _progress = (i + 1) / selected.length;
      notifyListeners();

      for (final path in _scanPaths[categoryId] ?? []) {
        try {
          if (await Directory(path).exists()) {
            final size = await DiskUtils.getDirSize(path);
            await DiskUtils.removeDirectory(path);
            totalFreed += size;
          } else if (await File(path).exists()) {
            final size = await File(path).length();
            await DiskUtils.removeFile(path);
            totalFreed += size;
          }
        } catch (e) {
          print('Error cleaning $path: $e');
        }
      }

      _scanResults[categoryId] = 0;
    }

    _isCleaning = false;
    _progress = 1.0;
    _statusText = '🎉 清理完成！共释放 ${DiskUtils.formatSize(totalFreed)} 空间';
    await _loadDiskInfo();
    notifyListeners();

    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _progress = 0.0;
      _statusText = '就绪 - 点击「扫描垃圾文件」开始';
      notifyListeners();
    });
  }

  void toggleSelection(String categoryId, bool value) {
    _selectedItems[categoryId] = value;
    notifyListeners();
  }

  void toggleAll(bool value) {
    for (final category in _scanCategories) {
      if (_scanResults.containsKey(category.id) && _scanResults[category.id]! > 0) {
        _selectedItems[category.id] = value;
      }
    }
    notifyListeners();
  }
}