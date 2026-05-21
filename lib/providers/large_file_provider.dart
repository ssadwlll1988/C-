import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/disk_utils.dart';
import '../config/skip_rules.dart';

class LargeFileInfo {
  final String path;
  final int size;
  final String fileType;
  final DateTime modified;
  LargeFileInfo({
    required this.path,
    required this.size,
    required this.fileType,
    required this.modified,
  });

  String get name => path.split(Platform.pathSeparator).last;
  String get dir {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i > 0 ? path.substring(0, i) : '';
  }
}

class LargeFileProvider with ChangeNotifier {
  final List<LargeFileInfo> _files = [];
  final Set<String> _selected = {};
  bool _scanning = false;
  bool _paused = false;
  bool _stopRequested = false;
  double _progress = 0.0;
  String _status = '准备就绪 - 点击"扫描大文件"开始';
  int _thresholdMB = 100;

  List<LargeFileInfo> get files => _files;
  Set<String> get selected => _selected;
  bool get scanning => _scanning;
  bool get paused => _paused;
  double get progress => _progress;
  String get status => _status;
  int get thresholdMB => _thresholdMB;

  int get totalSize {
    int t = 0;
    for (final f in _files) {
      t += f.size;
    }
    return t;
  }

  void setThreshold(int mb) {
    _thresholdMB = mb;
    notifyListeners();
  }

  void toggleSelect(String path) {
    if (_selected.contains(path)) {
      _selected.remove(path);
    } else {
      _selected.add(path);
    }
    notifyListeners();
  }

  void selectAll() {
    _selected.clear();
    for (final f in _files) {
      _selected.add(f.path);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;
    _paused = false;
    _stopRequested = false;
    _files.clear();
    _selected.clear();
    _progress = 0.0;
    _status = '准备扫描...';
    notifyListeners();

    final threshold = _thresholdMB * 1024 * 1024;
    final topDirs = <String>[];
    try {
      for (final ent in Directory('C:\\').listSync(followLinks: false)) {
        if (ent is! Directory) continue;
        final name = ent.path.split(Platform.pathSeparator).last;
        if (LARGE_FILE_SKIP_DIRS.contains(name)) continue;
        if (name.startsWith('.') || name.startsWith(r'$')) continue;
        topDirs.add(ent.path);
      }
    } catch (_) {}

    int processed = 0;
    final total = topDirs.length == 0 ? 1 : topDirs.length;

    Future<void> walkDir(String start) async {
      if (_stopRequested) return;
      final stack = <String>[start];
      while (stack.isNotEmpty) {
        if (_stopRequested) return;
        while (_paused && !_stopRequested) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        final cur = stack.removeLast();
        List<FileSystemEntity> entries;
        try {
          entries = Directory(cur).listSync(followLinks: false);
        } catch (_) {
          continue;
        }
        for (final ent in entries) {
          if (_stopRequested) return;
          try {
            if (ent is Directory) {
              final name = ent.path.split(Platform.pathSeparator).last;
              if (LARGE_FILE_SKIP_DIRS.contains(name)) continue;
              if (LARGE_FILE_FAST_SKIP_DIRS.contains(name)) continue;
              if (name.startsWith('.') || name.startsWith(r'$')) continue;
              stack.add(ent.path);
            } else if (ent is File) {
              try {
                final sz = await ent.length();
                if (sz >= threshold) {
                  DateTime mtime;
                  try {
                    mtime = ent.statSync().modified;
                  } catch (_) {
                    mtime = DateTime.fromMillisecondsSinceEpoch(0);
                  }
                  _files.add(LargeFileInfo(
                    path: ent.path,
                    size: sz,
                    fileType: DiskUtils.getFileType(ent.path),
                    modified: mtime,
                  ));
                  if (_files.length % 5 == 0) {
                    _status = '已发现 ${_files.length} 个文件... ${ent.path}';
                    notifyListeners();
                  }
                }
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    }

    const maxConc = 4;
    int next = 0;
    Future<void> worker() async {
      while (!_stopRequested) {
        final idx = next++;
        if (idx >= topDirs.length) return;
        await walkDir(topDirs[idx]);
        processed++;
        _progress = processed / total;
        _status = '已扫描 $processed/$total 个目录，发现 ${_files.length} 个文件';
        notifyListeners();
      }
    }

    final futures = <Future<void>>[];
    for (int i = 0; i < maxConc; i++) {
      futures.add(worker());
    }
    await Future.wait(futures);

    _files.sort((a, b) => b.size.compareTo(a.size));
    _scanning = false;
    _progress = 1.0;
    _status =
        '${_stopRequested ? "已停止" : "扫描完成"}！共发现 ${_files.length} 个大文件，总计 ${DiskUtils.formatSize(totalSize)}';
    notifyListeners();
  }

  void pauseResume() {
    if (!_scanning) return;
    _paused = !_paused;
    _status = _paused ? '已暂停...' : '继续扫描...';
    notifyListeners();
  }

  void stop() {
    if (!_scanning) return;
    _stopRequested = true;
    _paused = false;
    _status = '正在停止...';
    notifyListeners();
  }

  Future<int> deleteSelected() async {
    if (_selected.isEmpty) return 0;
    int freed = 0;
    final removed = <String>[];
    for (final p in _selected.toList()) {
      try {
        final f = File(p);
        if (await f.exists()) {
          final s = await f.length();
          await f.delete();
          freed += s;
          removed.add(p);
        }
      } catch (_) {}
    }
    _files.removeWhere((f) => removed.contains(f.path));
    _selected.clear();
    notifyListeners();
    return freed;
  }
}
