import 'dart:io';
import 'package:flutter/foundation.dart';

// 平台条件导入
import 'disk_utils_io.dart' if (dart.library.html) 'disk_utils_web.dart';

class DiskUtils {
  static String formatSize(int sizeBytes) {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  static Future<String> getDiskInfo() async {
    return getDiskInfoImpl();
  }

  static Future<int> getDirSize(String path) async {
    return getDirSizeImpl(path);
  }

  static Future<bool> removeDirectory(String path) async {
    return removeDirectoryImpl(path);
  }

  static Future<bool> removeFile(String path) async {
    return removeFileImpl(path);
  }

  static List<String> getAvailableDrives() {
    return getAvailableDrivesImpl();
  }
}