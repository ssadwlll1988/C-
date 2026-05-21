Future<String> getDiskInfoImpl() async {
  return 'Web N/A';
}

Future<int> getDirSizeImpl(String path) async => 0;

Future<int> getDirSizeFastImpl(
    String path, int maxDepth, int timeoutSeconds) async => 0;

Future<bool> removeDirectoryImpl(String path) async => false;

Future<bool> removeFileImpl(String path) async => false;

List<String> getAvailableDrivesImpl() => [];
