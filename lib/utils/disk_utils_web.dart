// Web平台不支持文件系统操作
// 这些是stub实现，在Web环境下返回空值或模拟数据

Future<String> getDiskInfoImpl() async {
  return 'Web环境不支持磁盘信息获取';
}

Future<int> getDirSizeImpl(String path) async {
  return 0;
}

Future<bool> removeDirectoryImpl(String path) async {
  return false;
}

Future<bool> removeFileImpl(String path) async {
  return false;
}

List<String> getAvailableDrivesImpl() {
  return [];
}
