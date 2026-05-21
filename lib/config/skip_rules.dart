const Set<String> LARGE_FILE_SKIP_DIRS = {
  'Windows', r'$Recycle.Bin', 'System Volume Information',
  'PerfLogs', 'Config.Msi', 'Recovery',
  'ProgramData', 'Documents and Settings',
  r'$WinREAgent', r'$SysReset', r'$Windows.~BT', r'$Windows.~WS',
  'Windows.old',
};

const Set<String> LARGE_FILE_FAST_SKIP_DIRS = {
  'node_modules', '.git', '.svn', '.hg', '__pycache__',
  '.vs', '.idea', '.gradle', '.cache', 'Application Data',
};

const Set<String> SOFTWARE_SKIP_NAMES = {
  'Microsoft Visual C++', 'Microsoft .NET', 'Windows SDK',
  'Microsoft Visual Studio', 'DirectX', 'Microsoft Edge',
  'Windows Defender', 'Microsoft Store', 'Windows Terminal',
};

const Set<String> DEEP_SCAN_SKIP_DIRS = {
  r'$Recycle.Bin', 'System Volume Information',
  'PerfLogs', 'Config.Msi', 'Recovery',
  r'$WinREAgent', r'$SysReset', r'$Windows.~BT', r'$Windows.~WS',
  'Windows.old', 'node_modules', '.git', '.svn', '.hg',
  '__pycache__', '.vs', '.idea',
};

const Set<String> DEEP_SCAN_SKIP_DIRS_PLUS_WINDOWS = {
  'Windows', r'$Recycle.Bin', 'System Volume Information',
  'PerfLogs', 'Config.Msi', 'Recovery',
  r'$WinREAgent', r'$SysReset', r'$Windows.~BT', r'$Windows.~WS',
  'Windows.old', 'node_modules', '.git', '.svn', '.hg',
  '__pycache__', '.vs', '.idea',
};

const Set<String> APPDATA_CACHE_KEYWORDS = {
  'cache', 'caches', 'cached', 'temp', 'tmp', 'temporary',
  'log', 'logs', 'logging', 'crash', 'crashdump', 'crashdumps',
  'backup', 'backups', 'update', 'updates', 'download', 'downloads',
  'gpucache', 'code_cache', 'shader_cache', 'blob_storage',
  'thumbnail', 'thumbnails', 'history', 'cookie', 'cookies',
  'session', 'sessions', 'report', 'reports', 'trace', 'tracing',
  'debug', 'debuglog', 'snapshot', 'snapshots', 'quarantine',
};
