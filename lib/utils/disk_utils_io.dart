import 'dart:io';
import 'package:win32/win32.dart';

Future<String> getDiskInfoImpl() async {
  try {
    final drive = 'C:\\';
    final freeBytesAvailable = calloc<Int64>();
    final totalNumberOfBytes = calloc<Int64>();
    final totalNumberOfFreeBytes = calloc<Int64>();

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

      return 'C盘: ${freeGB.toStringAsFixed(1)}GB 可用 / ${totalGB.toStringAsFixed(1)}GB 总计 (${pct.toStringAsFixed(0)}%已用)';
    } else {
      malloc.free(freeBytesAvailable);
      malloc.free(totalNumberOfBytes);
      malloc.free(totalNumberOfFreeBytes);
      return 'C盘信息获取失败';
    }
  } catch (e) {
    return 'C盘信息获取失败';
  }
}

Future<int> getDirSizeImpl(String path) async {
  int totalSize = 0;
  try {
    final directory = Directory(path);
    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Skip files that can't be accessed
          }
        }
      }
    }
  } catch (e) {
    // Handle permission errors or other issues
  }
  return totalSize;
}

Future<bool> removeDirectoryImpl(String path) async {
  try {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      return true;
    }
  } catch (e) {
    print('Error removing directory: $e');
  }
  return false;
}

Future<bool> removeFileImpl(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
  } catch (e) {
    print('Error removing file: $e');
  }
  return false;
}

List<String> getAvailableDrivesImpl() {
  List<String> drives = [];
  for (int i = 68; i <= 90; i++) { // D to Z
    String driveLetter = String.fromCharCode(i);
    String drivePath = '$driveLetter:\\';
    if (Directory(drivePath).existsSync()) {
      try {
        final dirStat = Directory(drivePath).statSync();
        if (dirStat.type == FileSystemEntityType.directory) {
          drives.add(drivePath);
        }
      } catch (e) {
        // Skip drives that can't be accessed
      }
    }
  }
  return drives;
}
