import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:win32_registry/win32_registry.dart';
import '../utils/disk_utils.dart';
import '../config/skip_rules.dart';

class InstalledApp {
  final String name;
  final String publisher;
  final String version;
  final String location;
  final int regSize;
  int actualSize;
  bool selected;
  bool isJunction;
  String junctionTarget;
  InstalledApp({
    required this.name,
    required this.publisher,
    required this.version,
    required this.location,
    required this.regSize,
    this.actualSize = 0,
    this.selected = false,
    this.isJunction = false,
    this.junctionTarget = '',
  });
}

class SoftwareProvider with ChangeNotifier {
  final List<InstalledApp> _apps = [];
  bool _scanning = false;
  bool _migrating = false;
  double _progress = 0.0;
  String _status = '准备就绪 - 点击"扫描已装软件"开始';
  String _targetDrive = 'D:\\';

  List<InstalledApp> get apps => _apps;
  bool get scanning => _scanning;
  bool get migrating => _migrating;
  double get progress => _progress;
  String get status => _status;
  String get targetDrive => _targetDrive;

  List<String> get availableDrives {
    final raw = DiskUtils.getAvailableDrives();
    if (raw.isEmpty) return ['D:\\'];
    return raw;
  }

  void setTargetDrive(String d) {
    _targetDrive = d;
    notifyListeners();
  }

  void toggle(int idx, bool v) {
    if (idx < 0 || idx >= _apps.length) return;
    _apps[idx].selected = v;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;
    _apps.clear();
    _progress = 0.0;
    _status = '正在读取注册表...';
    notifyListeners();

    final all = <InstalledApp>[];
    final seen = <String>{};

    final hives = [
      RegistryHive.localMachine,
      RegistryHive.currentUser,
    ];

    for (int hi = 0; hi < hives.length; hi++) {
      _progress = hi / hives.length * 0.5;
      _status = '正在读取注册表 ${hi + 1}/${hives.length}...';
      notifyListeners();
      _readUninstallKeys(hives[hi], all, seen);
      await Future.delayed(Duration.zero);
    }

    _status = '正在筛选 C 盘软件...';
    _progress = 0.6;
    notifyListeners();

    final cDriveApps = <InstalledApp>[];
    for (final app in all) {
      if (app.name.isEmpty) continue;
      final loc = app.location.toLowerCase();
      if (loc.isEmpty) continue;
      if (!loc.startsWith('c:\\')) continue;
      if (loc.startsWith(r'c:\windows')) continue;

      bool skip = false;
      for (final s in SOFTWARE_SKIP_NAMES) {
        if (app.name.contains(s)) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      cDriveApps.add(app);
    }

    final total = cDriveApps.length;
    for (int i = 0; i < total; i++) {
      final a = cDriveApps[i];

      try {
        if (FileSystemEntity.isLinkSync(a.location)) {
          a.isJunction = true;
          try {
            a.junctionTarget = Link(a.location).resolveSymbolicLinksSync();
          } catch (_) {}
        }
      } catch (_) {}

      if (a.regSize > 0) {
        a.actualSize = a.regSize * 1024;
      } else {
        try {
          if (Directory(a.location).existsSync()) {
            a.actualSize = await DiskUtils.getDirSizeFast(a.location);
          }
        } catch (_) {}
      }
      _progress = 0.6 + (i + 1) / total * 0.4;
      _status = '计算大小：${a.name} (${i + 1}/$total)';
      notifyListeners();
    }

    cDriveApps.sort((x, y) => y.actualSize.compareTo(x.actualSize));
    _apps.addAll(cDriveApps);

    _scanning = false;
    _progress = 1.0;
    _status = '扫描完成！共发现 ${_apps.length} 个 C 盘软件。';
    notifyListeners();
  }

  void _readUninstallKeys(RegistryHive hive,
      List<InstalledApp> out, Set<String> seen) {
    final paths = ['Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall'];
    const access = AccessRights.readOnly;
    for (final p in paths) {
      try {
        final key = Registry.openPath(hive, path: p, desiredAccessRights: access);
        try {
          for (final sub in key.subkeyNames) {
            try {
              final s = Registry.openPath(hive,
                  path: '$p\\$sub', desiredAccessRights: access);
              try {
                String name = '';
                String pub = '';
                String ver = '';
                String loc = '';
                int sz = 0;
                try {
                  name = s.getValueAsString('DisplayName') ?? '';
                } catch (_) {}
                if (name.isEmpty) continue;
                if (seen.contains(name)) continue;
                seen.add(name);
                try {
                  pub = s.getValueAsString('Publisher') ?? '';
                } catch (_) {}
                try {
                  ver = s.getValueAsString('DisplayVersion') ?? '';
                } catch (_) {}
                try {
                  loc = s.getValueAsString('InstallLocation') ?? '';
                } catch (_) {}
                if (loc.isEmpty) {
                  try {
                    loc = s.getValueAsString('InstallDir') ?? '';
                  } catch (_) {}
                }
                try {
                  sz = s.getValueAsInt('EstimatedSize') ?? 0;
                } catch (_) {}
                out.add(InstalledApp(
                  name: name,
                  publisher: pub,
                  version: ver,
                  location: loc,
                  regSize: sz,
                ));
              } finally {
                s.close();
              }
            } catch (_) {}
          }
        } finally {
          key.close();
        }
      } catch (_) {}
    }
  }

  Future<void> migrateSelected() async {
    if (_migrating) return;
    final selected = _apps.where((a) => a.selected).toList();
    if (selected.isEmpty) {
      _status = '请先勾选要搬迁的软件。';
      notifyListeners();
      return;
    }

    final adminOk = await _isAdmin();
    if (!adminOk) {
      _status = '⚠️ 当前未以管理员身份运行，无法搬迁系统受保护目录。请右键以管理员身份重启本程序。';
      notifyListeners();
      return;
    }

    _migrating = true;
    _progress = 0.0;
    notifyListeners();

    final targetLetter = _targetDrive.split(':')[0];
    final targetBase = '$targetLetter:\\MigratedApps';
    try {
      Directory(targetBase).createSync(recursive: true);
    } catch (e) {
      _migrating = false;
      _status = '目标盘创建失败：$e';
      notifyListeners();
      return;
    }

    int ok = 0, fail = 0;
    final total = selected.length;
    for (int i = 0; i < total; i++) {
      final app = selected[i];
      try {
        _status = '正在搬迁：${app.name} (${i + 1}/$total)';
        _progress = (i + 1) / total;
        notifyListeners();

        final src = app.location.trim();
        if (src.isEmpty) {
          fail++;
          _status = '${app.name}：安装位置为空';
          notifyListeners();
          continue;
        }

        bool alreadyJunction = false;
        try {
          alreadyJunction = FileSystemEntity.isLinkSync(src);
        } catch (_) {}
        if (alreadyJunction || app.isJunction) {
          fail++;
          _status = '⏭️ ${app.name} 已搬迁，跳过（如需还原请用「还原选中」）';
          notifyListeners();
          continue;
        }

        final folderName = _basename(src);
        if (folderName.isEmpty) {
          fail++;
          continue;
        }
        final dst = '$targetBase\\$folderName';
        if (Directory(dst).existsSync()) {
          fail++;
          _status = '${app.name}：目标目录已存在（$dst），请先手动清理';
          notifyListeners();
          continue;
        }

        if (!Directory(src).existsSync()) {
          fail++;
          _status = '${app.name}：源目录不存在';
          notifyListeners();
          continue;
        }

        _status = '正在复制：${app.name}（可能需要数分钟，请勿关闭）';
        notifyListeners();

        final copyOk = await _robocopyDir(src, dst);
        if (!copyOk) {
          fail++;
          _status = '${app.name}：复制失败（可能文件被占用或权限不足）';
          notifyListeners();
          await _tryRemoveDir(dst);
          continue;
        }

        _status = '正在删除源目录：${app.name}';
        notifyListeners();
        final delOk = await _tryRemoveDir(src);
        if (!delOk) {
          fail++;
          _status = '${app.name}：无法删除源目录（请先退出该软件）';
          notifyListeners();
          continue;
        }

        _status = '正在创建链接：${app.name}';
        notifyListeners();
        final linkOk = await _createJunction(src, dst);
        if (!linkOk) {
          await _robocopyDir(dst, src);
          await _tryRemoveDir(dst);
          fail++;
          _status = '${app.name}：创建符号链接失败，已回滚';
          notifyListeners();
        } else {
          ok++;
          app.isJunction = true;
          app.junctionTarget = dst;
          _status = '✅ ${app.name} 已搬迁到：$dst';
          notifyListeners();
        }
      } catch (e, st) {
        fail++;
        _status = '搬迁 ${app.name} 异常：$e';
        notifyListeners();
        if (kDebugMode) {
          debugPrint('迁移异常: $e\n$st');
        }
      }
    }

    _migrating = false;
    _status = '搬迁完成。成功 $ok 个，失败 $fail 个。目标位置：$targetBase\\';
    notifyListeners();
  }

  Future<int> cleanRedundantCopies() async {
    if (_migrating || _scanning) return 0;
    _migrating = true;
    _status = '正在扫描冗余副本...';
    notifyListeners();

    int removed = 0;
    final base = '${_targetDrive.split(':')[0]}:\\MigratedApps';
    final baseDir = Directory(base);
    if (!baseDir.existsSync()) {
      _migrating = false;
      _status = '目标盘下没有 MigratedApps 目录';
      notifyListeners();
      return 0;
    }

    final inUseTargets = <String>{};
    for (final app in _apps) {
      if (app.isJunction && app.junctionTarget.isNotEmpty) {
        inUseTargets.add(app.junctionTarget.toLowerCase());
      }
    }

    try {
      for (final ent in baseDir.listSync(followLinks: false)) {
        if (ent is! Directory) continue;
        final pathLower = ent.path.toLowerCase();
        if (inUseTargets.contains(pathLower)) continue;
        try {
          final ok = await _tryRemoveDir(ent.path);
          if (ok) {
            removed++;
            _status = '已删除冗余副本：${ent.path}';
            notifyListeners();
          }
        } catch (_) {}
      }
    } catch (_) {}

    _migrating = false;
    _status = '清理完成。已删除 $removed 个冗余副本。';
    notifyListeners();
    return removed;
  }

  Future<void> restoreSelected() async {
    if (_migrating) return;
    final selected = _apps.where((a) => a.selected && a.isJunction).toList();
    if (selected.isEmpty) {
      _status = '请勾选已搬迁的软件（带「已搬迁」标记）。';
      notifyListeners();
      return;
    }

    final adminOk = await _isAdmin();
    if (!adminOk) {
      _status = '⚠️ 请以管理员身份运行本程序才能还原。';
      notifyListeners();
      return;
    }

    _migrating = true;
    _progress = 0.0;
    notifyListeners();

    int ok = 0, fail = 0;
    final total = selected.length;
    for (int i = 0; i < total; i++) {
      final app = selected[i];
      try {
        _status = '正在还原：${app.name} (${i + 1}/$total)';
        _progress = (i + 1) / total;
        notifyListeners();

        final link = app.location;
        final realDir = app.junctionTarget;
        if (realDir.isEmpty || !Directory(realDir).existsSync()) {
          fail++;
          continue;
        }

        try {
          await Process.run('cmd', ['/c', 'rmdir', link], runInShell: true);
        } catch (_) {}

        final copyOk = await _robocopyDir(realDir, link);
        if (!copyOk) {
          fail++;
          await _createJunction(link, realDir);
          continue;
        }
        await _tryRemoveDir(realDir);
        app.isJunction = false;
        app.junctionTarget = '';
        ok++;
      } catch (e) {
        fail++;
        _status = '还原 ${app.name} 失败：$e';
        notifyListeners();
      }
    }

    _migrating = false;
    _status = '还原完成。成功 $ok 个，失败 $fail 个。';
    notifyListeners();
  }

  Future<bool> _isAdmin() async {
    try {
      final r = await Process.run('net', ['session'], runInShell: true);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _robocopyDir(String src, String dst) async {
    try {
      final r = await Process.run(
        'robocopy',
        [src, dst, '/E', '/COPY:DAT', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NC', '/NS', '/NP'],
        runInShell: true,
      );
      return r.exitCode < 8;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryRemoveDir(String path) async {
    try {
      final d = Directory(path);
      if (!d.existsSync()) return true;
      try {
        d.deleteSync(recursive: true);
        return true;
      } catch (_) {}
      final r = await Process.run(
        'cmd',
        ['/c', 'rmdir', '/S', '/Q', path],
        runInShell: true,
      );
      return r.exitCode == 0 && !Directory(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  String _basename(String path) {
    var p = path;
    while (p.endsWith('\\') || p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    final idx1 = p.lastIndexOf('\\');
    final idx2 = p.lastIndexOf('/');
    final idx = idx1 > idx2 ? idx1 : idx2;
    if (idx < 0) return p;
    return p.substring(idx + 1);
  }

  Future<bool> _safeMoveDirectory(String src, String dst) async {
    try {
      await Directory(src).rename(dst);
      return true;
    } catch (_) {}
    final copyOk = await _robocopyDir(src, dst);
    if (!copyOk) return false;
    return await _tryRemoveDir(src);
  }

  Future<bool> _createJunction(String linkPath, String target) async {
    try {
      final result = await Process.run(
        'cmd',
        ['/c', 'mklink', '/J', linkPath, target],
        runInShell: true,
      );
      if (result.exitCode == 0) return true;
    } catch (_) {}
    return false;
  }
}
