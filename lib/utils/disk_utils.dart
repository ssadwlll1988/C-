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

  static String getFileType(String filepath) {
    final lower = filepath.toLowerCase();
    final dotIdx = lower.lastIndexOf('.');
    if (dotIdx == -1) return 'OTHER';
    final ext = lower.substring(dotIdx);
    const Map<String, String> typeMap = {
      '.zip': 'ZIP', '.rar': 'ZIP', '.7z': 'ZIP', '.tar': 'ZIP', '.gz': 'ZIP',
      '.mp4': 'VIDEO', '.avi': 'VIDEO', '.mkv': 'VIDEO', '.mov': 'VIDEO',
      '.wmv': 'VIDEO', '.flv': 'VIDEO',
      '.iso': 'ISO', '.img': 'ISO', '.vhd': 'ISO', '.vhdx': 'ISO',
      '.exe': 'EXE', '.msi': 'MSI',
      '.dmp': 'DUMP', '.cab': 'CAB',
      '.log': 'LOG', '.tmp': 'TMP',
      '.mp3': 'AUDIO', '.wav': 'AUDIO', '.flac': 'AUDIO',
      '.pdf': 'PDF', '.doc': 'DOC', '.docx': 'DOC',
      '.jpg': 'IMG', '.png': 'IMG', '.bmp': 'IMG', '.psd': 'IMG',
      '.dll': 'SYS', '.sys': 'SYS',
      '.db': 'DB', '.sqlite': 'DB',
    };
    return typeMap[ext] ?? 'OTHER';
  }

  static Future<String> getDiskInfo() async => getDiskInfoImpl();

  static Future<int> getDirSize(String path) async => getDirSizeImpl(path);

  static Future<int> getDirSizeFast(String path,
      {int maxDepth = 3, int timeoutSeconds = 10}) async {
    return getDirSizeFastImpl(path, maxDepth, timeoutSeconds);
  }

  static Future<bool> removeDirectory(String path) async =>
      removeDirectoryImpl(path);

  static Future<bool> removeFile(String path) async => removeFileImpl(path);

  static List<String> getAvailableDrives() => getAvailableDrivesImpl();
}
