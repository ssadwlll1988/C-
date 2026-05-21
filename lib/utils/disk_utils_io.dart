import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

Future<String> getDiskInfoImpl() async {
  try {
    const drive = 'C:\\';
    final freeBytesAvailable = calloc<Uint64>();
    final totalNumberOfBytes = calloc<Uint64>();
    final totalNumberOfFreeBytes = calloc<Uint64>();

    final result = GetDiskFreeSpaceEx(
      drive.toNativeUtf16(),
      freeBytesAvailable,
      totalNumberOfBytes,
      totalNumberOfFreeBytes,
    );

    if (result != 0) {
      final totalGB = totalNumberOfBytes.value / (1024 * 1024 * 1024);
      final freeGB = freeBytesAvailable.value / (1024 * 1024 * 1024);
      final usedGB = totalGB - freeGB;
      final pct = totalGB > 0 ? (usedGB / totalGB * 100) : 0;

      malloc.free(freeBytesAvailable);
      malloc.free(totalNumberOfBytes);
      malloc.free(totalNumberOfFreeBytes);

      return 'C: ${freeGB.toStringAsFixed(1)}GB FREE / ${totalGB.toStringAsFixed(1)}GB TOTAL (${pct.toStringAsFixed(0)}%)';
    } else {
      malloc.free(freeBytesAvailable);
      malloc.free(totalNumberOfBytes);
      malloc.free(totalNumberOfFreeBytes);
      return 'C: info N/A';
    }
  } catch (e) {
    return 'C: info N/A';
  }
}

Future<int> getDirSizeImpl(String path) async {
  try {
    return await Isolate.run<int>(() {
      int totalSize = 0;
      try {
        final directory = Directory(path);
        if (directory.existsSync()) {
          for (final entity
              in directory.listSync(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                totalSize += entity.lengthSync();
              } catch (_) {}
            }
          }
        } else {
          final file = File(path);
          if (file.existsSync()) {
            try {
              totalSize += file.lengthSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
      return totalSize;
    });
  } catch (_) {
    return 0;
  }
}

Future<int> getDirSizeFastImpl(
    String path, int maxDepth, int timeoutSeconds) async {
  try {
    return await Isolate.run<int>(() {
      int total = 0;
      final start = DateTime.now();
      void walk(String p, int depth) {
        if (depth > maxDepth) return;
        if (DateTime.now().difference(start).inSeconds > timeoutSeconds) {
          return;
        }
        try {
          final dir = Directory(p);
          if (!dir.existsSync()) return;
          final entries = dir.listSync(followLinks: false);
          for (final e in entries) {
            if (DateTime.now().difference(start).inSeconds >
                timeoutSeconds) {
              return;
            }
            try {
              if (e is File) {
                total += e.lengthSync();
              } else if (e is Directory) {
                walk(e.path, depth + 1);
              }
            } catch (_) {}
          }
        } catch (_) {}
      }

      walk(path, 0);
      return total;
    });
  } catch (_) {
    return 0;
  }
}

Future<bool> removeDirectoryImpl(String path) async {
  try {
    final directory = Directory(path);
    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
        return true;
      } catch (_) {
        try {
          for (final e in directory.listSync(followLinks: false)) {
            try {
              if (e is File) {
                await e.delete();
              } else if (e is Directory) {
                await removeDirectoryImpl(e.path);
              }
            } catch (_) {}
          }
          try {
            await directory.delete();
          } catch (_) {}
          return true;
        } catch (_) {}
      }
    }
  } catch (_) {}
  return false;
}

Future<bool> removeFileImpl(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
  } catch (_) {}
  return false;
}

List<String> getAvailableDrivesImpl() {
  final List<String> drives = [];
  for (int i = 68; i <= 90; i++) {
    final driveLetter = String.fromCharCode(i);
    final drivePath = '$driveLetter:\\';
    if (Directory(drivePath).existsSync()) {
      try {
        final freeBytesAvailable = calloc<Uint64>();
        final totalNumberOfBytes = calloc<Uint64>();
        final totalNumberOfFreeBytes = calloc<Uint64>();
        final ret = GetDiskFreeSpaceEx(
          drivePath.toNativeUtf16(),
          freeBytesAvailable,
          totalNumberOfBytes,
          totalNumberOfFreeBytes,
        );
        if (ret != 0 && freeBytesAvailable.value > 1024 * 1024 * 1024) {
          final freeGB = freeBytesAvailable.value / (1024 * 1024 * 1024);
          drives.add('$driveLetter: (${freeGB.toStringAsFixed(0)}GB)');
        }
        malloc.free(freeBytesAvailable);
        malloc.free(totalNumberOfBytes);
        malloc.free(totalNumberOfFreeBytes);
      } catch (_) {}
    }
  }
  return drives;
}
