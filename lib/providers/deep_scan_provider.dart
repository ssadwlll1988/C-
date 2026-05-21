import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/disk_utils.dart';
import '../config/software_db.dart';
import '../config/skip_rules.dart';

class DeepScanItem {
  final String id;
  final String name;
  final String desc;
  final String icon;
  final String category;
  final bool safe;
  int size;
  List<String> paths;

  DeepScanItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.category,
    required this.safe,
    this.size = 0,
    List<String>? paths,
  }) : paths = paths ?? <String>[];
}

class DeepScanProvider with ChangeNotifier {
  final Map<String, DeepScanItem> _results = {};
  final Map<String, bool> _selected = {};
  bool _scanning = false;
  bool _cleaning = false;
  double _progress = 0.0;
  String _status = '准备就绪 - 点击"深度扫描"开始';

  Map<String, DeepScanItem> get results => _results;
  Map<String, bool> get selected => _selected;
  bool get scanning => _scanning;
  bool get cleaning => _cleaning;
  double get progress => _progress;
  String get status => _status;

  int get totalSelectedSize {
    int t = 0;
    _selected.forEach((id, sel) {
      if (sel && _results.containsKey(id)) t += _results[id]!.size;
    });
    return t;
  }

  int get totalScannedSize {
    int t = 0;
    for (final v in _results.values) {
      t += v.size;
    }
    return t;
  }

  void toggle(String id, bool v) {
    _selected[id] = v;
    notifyListeners();
  }

  void selectAllSafe(bool v) {
    _results.forEach((id, item) {
      if (item.safe) _selected[id] = v;
    });
    notifyListeners();
  }

  void _add(DeepScanItem item) {
    _results[item.id] = item;
    _selected[item.id] = item.safe;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_scanning || _cleaning) return;
    _scanning = true;
    _results.clear();
    _selected.clear();
    _progress = 0.0;
    _status = '正在深度扫描...';
    notifyListeners();

    await _scanSystemCategories();
    await _scanAppDataSoftware();

    _scanning = false;
    _progress = 1.0;
    _status =
        '扫描完成！共 ${_results.length} 项，总计 ${DiskUtils.formatSize(totalScannedSize)}';
    notifyListeners();
  }

  Future<void> _scanSystemCategories() async {
    final env = Platform.environment;
    final localAppData = env['LOCALAPPDATA'] ?? '';
    final appData = env['APPDATA'] ?? '';
    final userProfile = env['USERPROFILE'] ?? '';
    final temp = env['TEMP'] ?? '';

    final categories = <Map<String, dynamic>>[
      {
        'id': 'deep_logs',
        'name': '系统日志文件',
        'desc': 'Windows 日志、事件追踪记录',
        'icon': '📄',
        'category': '系统垃圾',
        'safe': true,
        'paths': [
          r'C:\Windows\Logs',
          r'C:\Windows\Panther',
          r'C:\Windows\Debug',
          r'C:\Windows\System32\LogFiles',
          r'C:\Windows\Performance\WinSAT',
          r'C:\Windows\CbsTemp',
        ],
      },
      {
        'id': 'deep_temp',
        'name': '临时文件',
        'desc': '所有 Temp 目录文件',
        'icon': '🗑️',
        'category': '系统垃圾',
        'safe': true,
        'paths': [
          temp,
          env['TMP'] ?? '',
          r'C:\Windows\Temp',
          '$localAppData\\Temp',
          r'C:\Windows\Prefetch',
        ],
      },
      {
        'id': 'deep_installer',
        'name': '安装残留',
        'desc': 'MSI/cab/exe 安装残留',
        'icon': '📦',
        'category': '系统垃圾',
        'safe': true,
        'paths': [
          r'C:\Windows\Installer',
          r'C:\Windows\SoftwareDistribution\Download',
          r'C:\ProgramData\Package Cache',
        ],
      },
      {
        'id': 'deep_patches',
        'name': '系统补丁缓存',
        'desc': 'Windows 更新补丁备份',
        'icon': '🔧',
        'category': '系统垃圾',
        'safe': true,
        'paths': [
          r'C:\Windows\SoftwareDistribution\Download',
          r'C:\Windows\SoftwareDistribution\DataStore',
          r'C:\Windows\WinSxS\Temp',
          r'C:\Windows\WinSxS\Backup',
          r'C:\Windows\WinSxS\ManifestCache',
          r'C:\Windows\CbsTemp',
          r'C:\Windows\servicing\LCU',
          r'C:\Windows\Logs\CBS',
          r'C:\Windows\Logs\DISM',
          r'C:\Windows\Logs\WindowsUpdate',
        ],
      },
      {
        'id': 'deep_system_garbage',
        'name': '系统运行垃圾',
        'desc': '报告/转储/备份（谨慎清理）',
        'icon': '⚠️',
        'category': '系统垃圾',
        'safe': false,
        'paths': [
          r'C:\Windows\Temp',
          r'C:\Windows\Minidump',
          r'C:\ProgramData\Microsoft\Windows\WER',
          r'C:\ProgramData\Microsoft\Search\Data',
          r'C:\ProgramData\Microsoft\Windows Defender',
        ],
      },
      {
        'id': 'deep_browser_cache',
        'name': '所有浏览器缓存',
        'desc': 'Chrome/Edge/Firefox 缓存',
        'icon': '🌐',
        'category': '浏览器',
        'safe': true,
        'paths': [
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Cache',
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Code Cache',
          '$localAppData\\Google\\Chrome\\User Data\\Default\\GPUCache',
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\Cache',
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\Code Cache',
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\GPUCache',
          '$localAppData\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Cache',
          '$localAppData\\Vivaldi\\User Data\\Default\\Cache',
          '$appData\\Mozilla\\Firefox\\Profiles',
        ],
      },
      {
        'id': 'deep_browser_login',
        'name': '浏览器登录数据（谨慎）',
        'desc': 'Session/IndexedDB 可能含登录信息',
        'icon': '🔒',
        'category': '浏览器',
        'safe': false,
        'paths': [
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Service Worker',
          '$localAppData\\Google\\Chrome\\User Data\\Default\\IndexedDB',
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Local Storage',
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\Service Worker',
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\IndexedDB',
        ],
      },
      {
        'id': 'deep_dev_cache',
        'name': '开发工具缓存（自动）',
        'desc': 'pip/npm/yarn/gradle/maven 等缓存',
        'icon': '💻',
        'category': '开发工具',
        'safe': true,
        'paths': [
          '$localAppData\\pip\\cache',
          '$localAppData\\npm-cache',
          '$appData\\npm',
          '$localAppData\\Yarn\\Cache',
          '$userProfile\\.gradle\\caches',
          '$userProfile\\.m2\\repository',
          '$userProfile\\.nuget\\packages',
          '$userProfile\\.cache',
          '$userProfile\\.pub-cache',
          '$localAppData\\Pub\\Cache',
          '$userProfile\\go\\pkg',
          '$userProfile\\.cargo\\registry',
          '$userProfile\\.conda\\pkgs',
          '$appData\\Code\\Cache',
          '$appData\\Code\\CachedData',
          '$appData\\Code\\logs',
          '$localAppData\\JetBrains\\Toolbox\\apps',
        ],
      },
    ];

    final total = categories.length;
    for (int i = 0; i < total; i++) {
      final cat = categories[i];
      _status = '正在扫描：${cat['name']}...';
      _progress = (i / total) * 0.5;
      notifyListeners();

      int size = 0;
      final found = <String>[];
      for (final p in cat['paths'] as List<String>) {
        if (p.isEmpty) continue;
        try {
          if (Directory(p).existsSync()) {
            final s = await DiskUtils.getDirSizeFast(p);
            if (s > 0) {
              size += s;
              found.add(p);
            }
          } else if (File(p).existsSync()) {
            final s = await File(p).length();
            if (s > 0) {
              size += s;
              found.add(p);
            }
          }
        } catch (_) {}
      }
      if (size > 0) {
        _add(DeepScanItem(
          id: cat['id'] as String,
          name: cat['name'] as String,
          desc: cat['desc'] as String,
          icon: cat['icon'] as String,
          category: cat['category'] as String,
          safe: cat['safe'] as bool,
          size: size,
          paths: found,
        ));
      }
    }
  }

  Future<void> _scanAppDataSoftware() async {
    final env = Platform.environment;
    final localAppData = env['LOCALAPPDATA'] ?? '';
    final appData = env['APPDATA'] ?? '';
    final scannedIds = <String>{};
    final bases = <List<String>>[
      ['Local', localAppData],
      ['Roaming', appData],
    ];

    int countSoFar = 0;

    for (final pair in bases) {
      final baseLabel = pair[0];
      final basePath = pair[1];
      if (basePath.isEmpty || !Directory(basePath).existsSync()) continue;
      List<FileSystemEntity> entries;
      try {
        entries = Directory(basePath).listSync(followLinks: false);
      } catch (_) {
        continue;
      }
      for (final ent in entries) {
        if (ent is! Directory) continue;
        final folderName = ent.path.split(Platform.pathSeparator).last;
        if (folderName.startsWith('.')) continue;
        if (const ['Microsoft', 'Packages', 'Low', 'Temp', 'VirtualStore',
                  'CrashDumps', 'D3DSCache', 'Microsoft Corporation']
            .contains(folderName)) continue;

        final dbEntry = SOFTWARE_CACHE_DB[folderName];
        if (dbEntry == null) continue;

        if (dbEntry.subdirs != null) {
          for (final entry in dbEntry.subdirs!.entries) {
            final subName = entry.key;
            final subInfo = entry.value;
            final subPath = '${ent.path}\\$subName';
            if (!Directory(subPath).existsSync()) continue;

            final itemId = 'sw_${folderName}_$subName';
            if (scannedIds.contains(itemId)) continue;
            scannedIds.add(itemId);

            countSoFar++;
            _status = '正在扫描：${subInfo.name}...';
            _progress = (0.5 + countSoFar * 0.01).clamp(0.5, 0.95);
            notifyListeners();

            int size = 0;
            final found = <String>[];
            if (subInfo.cache.isNotEmpty) {
              for (final cd in subInfo.cache) {
                final cp = '$subPath\\$cd';
                if (Directory(cp).existsSync()) {
                  try {
                    final s = await DiskUtils.getDirSizeFast(cp);
                    if (s > 0) {
                      size += s;
                      found.add(cp);
                    }
                  } catch (_) {}
                }
              }
            } else {
              try {
                final s = await DiskUtils.getDirSizeFast(subPath);
                if (s > 0) {
                  size = s;
                  found.add(subPath);
                }
              } catch (_) {}
            }

            if (size > 0) {
              _add(DeepScanItem(
                id: itemId,
                name: subInfo.name,
                desc: '$baseLabel\\$folderName\\$subName',
                icon: dbEntry.icon,
                category: dbEntry.category,
                safe: false,
                size: size,
                paths: found,
              ));
            }
          }
        } else {
          final itemId = 'sw_${folderName}_$baseLabel';
          if (scannedIds.contains(itemId)) continue;
          scannedIds.add(itemId);

          countSoFar++;
          _status = '正在扫描：${dbEntry.name}...';
          _progress = (0.5 + countSoFar * 0.01).clamp(0.5, 0.95);
          notifyListeners();

          int size = 0;
          final found = <String>[];
          if (dbEntry.cache.isNotEmpty) {
            for (final cd in dbEntry.cache) {
              final cp = '${ent.path}\\$cd';
              if (Directory(cp).existsSync()) {
                try {
                  final s = await DiskUtils.getDirSizeFast(cp);
                  if (s > 0) {
                    size += s;
                    found.add(cp);
                  }
                } catch (_) {}
              }
            }
          } else {
            try {
              final s = await DiskUtils.getDirSizeFast(ent.path);
              if (s > 0) {
                size = s;
                found.add(ent.path);
              }
            } catch (_) {}
          }

          if (size > 0) {
            _add(DeepScanItem(
              id: itemId,
              name: dbEntry.name,
              desc: '$baseLabel\\$folderName',
              icon: dbEntry.icon,
              category: dbEntry.category,
              safe: false,
              size: size,
              paths: found,
            ));
          }
        }
      }
    }

    for (final pair in bases) {
      final baseLabel = pair[0];
      final basePath = pair[1];
      if (basePath.isEmpty || !Directory(basePath).existsSync()) continue;
      List<FileSystemEntity> entries;
      try {
        entries = Directory(basePath).listSync(followLinks: false);
      } catch (_) {
        continue;
      }
      for (final ent in entries) {
        if (ent is! Directory) continue;
        final folderName = ent.path.split(Platform.pathSeparator).last;
        if (folderName.startsWith('.')) continue;
        if (SOFTWARE_CACHE_DB.containsKey(folderName)) continue;
        if (const ['Microsoft', 'Packages', 'Low', 'Temp'].contains(folderName)) continue;

        final itemId = 'sw_unknown_${folderName}_$baseLabel';
        if (scannedIds.contains(itemId)) continue;
        scannedIds.add(itemId);

        int cacheSize = 0;
        final cachePaths = <String>[];
        try {
          for (final sub in ent.listSync(followLinks: false)) {
            if (sub is! Directory) continue;
            final subLower =
                sub.path.split(Platform.pathSeparator).last.toLowerCase();
            if (APPDATA_CACHE_KEYWORDS.any((kw) => subLower.contains(kw))) {
              try {
                final s = await DiskUtils.getDirSizeFast(sub.path);
                if (s > 0) {
                  cacheSize += s;
                  cachePaths.add(sub.path);
                }
              } catch (_) {}
            }
          }
        } catch (_) {}

        if (cacheSize > 0) {
          _add(DeepScanItem(
            id: itemId,
            name: folderName,
            desc: '$baseLabel\\$folderName （自动识别）',
            icon: '\u{1F4E6}',
            category: '其他软件',
            safe: true,
            size: cacheSize,
            paths: cachePaths,
          ));
        }
      }
    }
  }

  Future<void> startClean() async {
    if (_cleaning || _scanning) return;
    final ids = _selected.entries
        .where((e) => e.value && _results.containsKey(e.key))
        .map((e) => e.key)
        .toList();
    if (ids.isEmpty) {
      _status = '请先勾选要清理的项目。';
      notifyListeners();
      return;
    }
    _cleaning = true;
    _progress = 0.0;
    _status = '正在清理 ${ids.length} 个项目...';
    notifyListeners();

    int freed = 0;
    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      final item = _results[id]!;
      _status = '正在清理：${item.name} (${i + 1}/${ids.length})';
      _progress = (i + 1) / ids.length;
      notifyListeners();
      for (final p in item.paths) {
        try {
          if (Directory(p).existsSync()) {
            final s = await DiskUtils.getDirSize(p);
            await DiskUtils.removeDirectory(p);
            freed += s;
          } else if (File(p).existsSync()) {
            final s = await File(p).length();
            await DiskUtils.removeFile(p);
            freed += s;
          }
        } catch (_) {}
      }
      item.size = 0;
    }
    _cleaning = false;
    _status = '清理完成！已释放 ${DiskUtils.formatSize(freed)}';
    notifyListeners();
  }
}

