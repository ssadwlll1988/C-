import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/disk_utils.dart';
import '../config/analysis_config.dart';

class AnalysisItem {
  final String name;
  final String path;
  final int size;
  final String category;
  bool expanded;
  bool loading;
  bool loaded;
  List<AnalysisItem> children;

  AnalysisItem({
    required this.name,
    required this.path,
    required this.size,
    required this.category,
    this.expanded = false,
    this.loading = false,
    this.loaded = false,
    List<AnalysisItem>? children,
  }) : children = children ?? [];
}

class AnalysisProvider with ChangeNotifier {
  List<AnalysisItem> _items = [];
  final List<String> _breadcrumb = ['C:\\'];
  bool _scanning = false;
  bool _stopRequested = false;
  double _progress = 0.0;
  String _status = '准备就绪 - 点击"开始分析"查看 C 盘空间占用';
  int _totalSize = 0;
  int _diskTotal = 0;
  int _diskFree = 0;

  List<AnalysisItem> get items => _items;
  List<String> get breadcrumb => List.unmodifiable(_breadcrumb);
  bool get scanning => _scanning;
  double get progress => _progress;
  String get status => _status;
  int get totalSize => _totalSize;
  int get diskTotal => _diskTotal;
  int get diskFree => _diskFree;
  int get diskUsed => _diskTotal - _diskFree;
  String get currentPath =>
      _breadcrumb.isEmpty ? 'C:\\' : _breadcrumb.last;

  Future<void> startAnalyze() async {
    if (_scanning) return;
    _breadcrumb
      ..clear()
      ..add('C:\\');
    await _doAnalyze('C:\\');
  }

  Future<void> drillInto(String path) async {
    if (_scanning) return;
    if (_breadcrumb.isEmpty || _breadcrumb.last != path) {
      _breadcrumb.add(path);
    }
    await _doAnalyze(path);
  }

  Future<void> goToBreadcrumb(int index) async {
    if (_scanning) return;
    if (index < 0 || index >= _breadcrumb.length) return;
    final target = _breadcrumb[index];
    _breadcrumb.removeRange(index + 1, _breadcrumb.length);
    await _doAnalyze(target);
  }

  void stop() {
    if (!_scanning) return;
    _stopRequested = true;
    _status = '正在停止分析...';
    notifyListeners();
  }

  Future<void> _doAnalyze(String path) async {
    _scanning = true;
    _stopRequested = false;
    _items = [];
    _totalSize = 0;
    _progress = 0.0;
    _status = '正在分析：$path';
    notifyListeners();

    await _loadDiskInfo();

    final dir = Directory(path);
    if (!dir.existsSync()) {
      _scanning = false;
      _status = '路径不存在：$path';
      notifyListeners();
      return;
    }

    List<Directory> subDirs = [];
    List<File> rootFiles = [];
    final results = <AnalysisItem>[];
    try {
      for (final ent in dir.listSync(followLinks: false)) {
        if (ent is Directory) {
          subDirs.add(ent);
        } else if (ent is File) {
          rootFiles.add(ent);
        }
      }
    } catch (_) {}

    for (final f in rootFiles) {
      try {
        final sz = f.lengthSync();
        if (sz > 0) {
          final name = f.path.split(Platform.pathSeparator).last;
          results.add(AnalysisItem(
            name: name,
            path: f.path,
            size: sz,
            category: '系统文件',
          ));
        }
      } catch (_) {}
    }

    final total = subDirs.length;
    int done = 0;
    const maxConcurrent = 4;
    int next = 0;

    Future<void> worker() async {
      while (true) {
        if (_stopRequested) return;
        final idx = next++;
        if (idx >= total) return;
        final d = subDirs[idx];
        final name = d.path.split(Platform.pathSeparator).last;
        int sz = 0;
        try {
          sz = await DiskUtils.getDirSizeFast(d.path,
              maxDepth: 99, timeoutSeconds: 120);
        } catch (_) {}
        if (sz > 0) {
          results.add(AnalysisItem(
            name: name,
            path: d.path,
            size: sz,
            category: getCategoryByName(name),
          ));
        }
        done++;
        _progress = total > 0 ? done / total : 0.0;
        _status = '正在分析：$name ($done/$total)';
        notifyListeners();
      }
    }

    final futures = <Future<void>>[];
    for (int i = 0; i < maxConcurrent; i++) {
      futures.add(worker());
    }
    await Future.wait(futures);

    results.sort((a, b) => b.size.compareTo(a.size));
    _items = results;
    int sum = 0;
    for (final e in results) {
      sum += e.size;
    }
    _totalSize = sum;
    _scanning = false;
    _progress = 1.0;

    final isRoot = path.toUpperCase().startsWith('C:') &&
        (path.length <= 3);
    String extra = '';
    if (isRoot && _diskTotal > 0) {
      final realUsed = diskUsed;
      final diff = realUsed - _totalSize;
      if (diff > 1024 * 1024 * 1024) {
        extra =
            '  ⚠️ 系统实际已用 ${DiskUtils.formatSize(realUsed)}，差额 ${DiskUtils.formatSize(diff)}（受保护目录/无权限）';
      }
    }
    _status = _stopRequested
        ? '已停止！本次已用 ${DiskUtils.formatSize(_totalSize)}'
        : '分析完成！本次共 ${DiskUtils.formatSize(_totalSize)}（单击展开 / 双击进入 / 右键菜单）$extra';
    notifyListeners();
  }

  Future<void> toggleExpand(AnalysisItem item) async {
    if (item.expanded) {
      item.expanded = false;
      notifyListeners();
      return;
    }
    item.expanded = true;
    if (item.loaded) {
      notifyListeners();
      return;
    }
    item.loading = true;
    notifyListeners();

    final subs = <AnalysisItem>[];
    try {
      final entries = Directory(item.path).listSync(followLinks: false);
      const maxConcurrent = 4;
      final dirs = entries.whereType<Directory>().toList();
      int next = 0;
      Future<void> worker() async {
        while (true) {
          final idx = next++;
          if (idx >= dirs.length) return;
          final d = dirs[idx];
          final name = d.path.split(Platform.pathSeparator).last;
          int sz = 0;
          try {
            sz = await DiskUtils.getDirSizeFast(d.path,
                maxDepth: 99, timeoutSeconds: 60);
          } catch (_) {}
          if (sz > 0) {
            subs.add(AnalysisItem(
              name: name,
              path: d.path,
              size: sz,
              category: getCategoryByName(name),
            ));
          }
        }
      }

      final futures = <Future<void>>[];
      for (int i = 0; i < maxConcurrent; i++) {
        futures.add(worker());
      }
      await Future.wait(futures);

      try {
        final files = entries.whereType<File>().toList();
        for (final f in files) {
          try {
            final sz = f.lengthSync();
            if (sz > 0) {
              final name = f.path.split(Platform.pathSeparator).last;
              subs.add(AnalysisItem(
                name: name,
                path: f.path,
                size: sz,
                category: getCategoryByName(name),
              ));
            }
          } catch (_) {}
        }
      } catch (_) {}
    } catch (_) {}

    subs.sort((a, b) => b.size.compareTo(a.size));
    item.children = subs;
    item.loaded = true;
    item.loading = false;
    notifyListeners();
  }

  Future<void> _loadDiskInfo() async {
    final info = await DiskUtils.getDiskInfo();
    final regex = RegExp(r'C:\s+(\d+\.?\d*)GB FREE / (\d+\.?\d*)GB TOTAL');
    final m = regex.firstMatch(info);
    if (m != null) {
      final free = double.tryParse(m.group(1) ?? '0') ?? 0;
      final tot = double.tryParse(m.group(2) ?? '0') ?? 0;
      _diskTotal = (tot * 1024 * 1024 * 1024).toInt();
      _diskFree = (free * 1024 * 1024 * 1024).toInt();
    }
  }

  Future<bool> deleteItem(AnalysisItem item) async {
    try {
      final dir = Directory(item.path);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      } else {
        final file = File(item.path);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      _items.remove(item);
      _removeFromChildren(_items, item);
      int sum = 0;
      for (final e in _items) {
        sum += e.size;
      }
      _totalSize = sum;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _removeFromChildren(List<AnalysisItem> list, AnalysisItem target) {
    for (final i in list) {
      if (i.children.remove(target)) {
        return;
      }
      _removeFromChildren(i.children, target);
    }
  }

  Future<void> openInExplorer(String path) async {
    try {
      await Process.run(
        'explorer',
        ['/select,', path],
        runInShell: false,
      );
    } catch (_) {
      try {
        await Process.run('explorer', [path], runInShell: false);
      } catch (_) {}
    }
  }

  List<AnalysisItem> get topItemsForChart {
    if (_items.isEmpty) return [];
    if (_items.length <= 10) return List<AnalysisItem>.from(_items);
    final top = List<AnalysisItem>.from(_items.sublist(0, 10));
    int otherSize = 0;
    for (final e in _items.sublist(10)) {
      otherSize += e.size;
    }
    if (otherSize > 0) {
      top.add(AnalysisItem(
        name: '其他',
        path: '',
        size: otherSize,
        category: '其他',
      ));
    }
    return top;
  }
}
