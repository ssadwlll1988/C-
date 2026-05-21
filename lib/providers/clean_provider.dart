import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/disk_utils.dart';
import '../config/scan_categories.dart';

class CleanProvider with ChangeNotifier {
  final List<ScanCategory> _scanCategories = SCAN_CATEGORIES;
  final Map<String, int> _scanResults = {};
  final Map<String, List<String>> _scanPaths = {};
  bool _isScanning = false;
  bool _isCleaning = false;
  double _progress = 0.0;
  String _statusText = '准备就绪 - 点击"开始扫描"';
  String _diskInfo = '';
  final Map<String, bool> _selectedItems = {};
  int _completedCount = 0;

  CleanProvider() {
    _loadDiskInfo();
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

  int get totalSelectedSize {
    int total = 0;
    for (final entry in _selectedItems.entries) {
      if (entry.value && _scanResults.containsKey(entry.key)) {
        total += _scanResults[entry.key]!;
      }
    }
    return total;
  }

  int get totalScannedSize {
    int total = 0;
    for (final v in _scanResults.values) {
      total += v;
    }
    return total;
  }

  Future<void> startScan() async {
    if (_isScanning || _isCleaning) return;

    _isScanning = true;
    _scanResults.clear();
    _scanPaths.clear();
    _selectedItems.clear();
    _progress = 0.0;
    _completedCount = 0;
    _statusText = '正在扫描...';
    notifyListeners();

    final totalCats = _scanCategories.length;
    const maxConcurrent = 4;
    final futures = <Future<void>>[];

    int next = 0;
    Future<void> worker() async {
      while (true) {
        final idx = next++;
        if (idx >= totalCats) return;
        final category = _scanCategories[idx];
        int totalSize = 0;
        final foundPaths = <String>[];

        for (final path in category.paths) {
          try {
            if (Directory(path).existsSync() || File(path).existsSync()) {
              final size = await DiskUtils.getDirSize(path);
              if (size > 0) {
                totalSize += size;
                foundPaths.add(path);
              }
            }
          } catch (_) {}
        }

        _scanResults[category.id] = totalSize;
        _scanPaths[category.id] = foundPaths;
        _selectedItems[category.id] = category.safe && totalSize > 0;

        _completedCount++;
        _progress = _completedCount / totalCats;
        _statusText =
            '正在扫描：${category.name} ($_completedCount/$totalCats)';
        notifyListeners();
      }
    }

    for (int i = 0; i < maxConcurrent; i++) {
      futures.add(worker());
    }
    await Future.wait(futures);

    _isScanning = false;
    _progress = 1.0;
    _statusText =
        '扫描完成！发现 ${DiskUtils.formatSize(totalScannedSize)} 可清理空间。';
    await _loadDiskInfo();
    notifyListeners();
  }

  Future<void> startClean() async {
    final selected = _selectedItems.entries
        .where((e) =>
            e.value &&
            _scanResults.containsKey(e.key) &&
            _scanResults[e.key]! > 0)
        .map((e) => e.key)
        .toList();

    if (selected.isEmpty) {
      _statusText = '请先勾选要清理的项目。';
      notifyListeners();
      return;
    }

    _isCleaning = true;
    _statusText = '正在清理 ${selected.length} 个项目...';
    _progress = 0.0;
    notifyListeners();

    int totalFreed = 0;
    for (int i = 0; i < selected.length; i++) {
      final categoryId = selected[i];
      final category =
          _scanCategories.firstWhere((c) => c.id == categoryId);

      _statusText =
          '正在清理：${category.name} (${i + 1}/${selected.length})';
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
        } catch (_) {}
      }

      _scanResults[categoryId] = 0;
    }

    _isCleaning = false;
    _progress = 1.0;
    _statusText =
        '清理完成！已释放 ${DiskUtils.formatSize(totalFreed)} 空间。';
    await _loadDiskInfo();
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      _progress = 0.0;
      _statusText = '准备就绪 - 点击"开始扫描"';
      notifyListeners();
    });
  }

  void toggleSelection(String categoryId, bool value) {
    _selectedItems[categoryId] = value;
    notifyListeners();
  }

  void toggleAll(bool value) {
    for (final category in _scanCategories) {
      if (_scanResults.containsKey(category.id) &&
          _scanResults[category.id]! > 0) {
        _selectedItems[category.id] = value;
      }
    }
    notifyListeners();
  }
}
