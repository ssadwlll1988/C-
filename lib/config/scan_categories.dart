import 'dart:io';

class ScanCategory {
  final String id;
  final String name;
  final String desc;
  final List<String> paths;
  final bool safe;
  final String icon;
  final String category;
  final String? scanType;

  ScanCategory({
    required this.id,
    required this.name,
    required this.desc,
    required this.paths,
    required this.safe,
    required this.icon,
    required this.category,
    this.scanType,
  });
}

// 基础清理类别
final List<ScanCategory> SCAN_CATEGORIES = _getScanCategories();

List<ScanCategory> _getScanCategories() {
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
  final appData = Platform.environment['APPDATA'] ?? '';
  final temp = Platform.environment['TEMP'] ?? '';

  return [
    // 系统临时
    ScanCategory(
      id: 'temp_user',
      name: '用户临时文件',
      desc: 'Temp目录下的临时文件',
      paths: [
        '$userProfile\\AppData\\Local\\Temp',
      ],
      safe: true,
      icon: '📄',
      category: '系统临时',
    ),
    ScanCategory(
      id: 'temp_windows',
      name: 'Windows临时文件',
      desc: 'C:\\Windows\\Temp 下的临时文件',
      paths: ['C:\\Windows\\Temp'],
      safe: true,
      icon: '📄',
      category: '系统临时',
    ),
    ScanCategory(
      id: 'crash_dumps',
      name: '崩溃转储文件',
      desc: '应用程序崩溃产生的dump文件',
      paths: [
        '$localAppData\\CrashDumps',
        'C:\\Windows\\Minidump',
        'C:\\Windows\\MEMORY.DMP',
        '$localAppData\\Microsoft\\Windows\\WER',
        'C:\\ProgramData\\Microsoft\\Windows\\WER',
      ],
      safe: true,
      icon: '💥',
      category: '系统临时',
    ),
    // 系统缓存
    ScanCategory(
      id: 'windows_update',
      name: 'Windows更新缓存',
      desc: '已下载的Windows更新安装包',
      paths: ['C:\\Windows\\SoftwareDistribution\\Download'],
      safe: true,
      icon: '🔄',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_logs',
      name: 'Windows日志文件',
      desc: '系统日志和安装日志',
      paths: [
        'C:\\Windows\\Logs',
        'C:\\Windows\\Panther',
        'C:\\Windows\\Debug',
        'C:\\Windows\\System32\\LogFiles',
        'C:\\Windows\\Performance\\WinSAT',
      ],
      safe: true,
      icon: '📋',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'recycle_bin',
      name: '回收站',
      desc: '已删除但未清空的文件',
      paths: ['C:\\\$Recycle.Bin'],
      safe: true,
      icon: '🗑️',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'thumbnail_cache',
      name: '缩略图缓存',
      desc: '资源管理器图片缩略图缓存',
      paths: ['$localAppData\\Microsoft\\Windows\\Explorer'],
      safe: true,
      icon: '🖼️',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'icon_cache',
      name: '图标缓存',
      desc: '系统图标缓存文件，清理后自动重建',
      paths: [
        '$localAppData\\IconCache.db',
        '$localAppData\\Microsoft\\Windows\\Explorer\\iconcache_*.db',
      ],
      safe: true,
      icon: '🔤',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_prefetch',
      name: 'Windows预读取文件',
      desc: '系统启动加速缓存，清理后首次启动稍慢',
      paths: ['C:\\Windows\\Prefetch'],
      safe: true,
      icon: '⚡',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_wer',
      name: 'Windows错误报告',
      desc: '应用程序崩溃产生的错误报告',
      paths: [
        '$localAppData\\Microsoft\\Windows\\WER',
        'C:\\ProgramData\\Microsoft\\Windows\\WER',
        '$localAppData\\Microsoft\\Windows\\INetCache',
      ],
      safe: true,
      icon: '',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_old',
      name: '旧Windows安装文件',
      desc: '系统升级后保留的旧版本文件',
      paths: ['C:\\Windows.old'],
      safe: true,
      icon: '📁',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'delivery_optimization',
      name: 'Windows传递优化',
      desc: '系统更新分发缓存文件',
      paths: ['C:\\Windows\\SoftwareDistribution\\DeliveryOptimization'],
      safe: true,
      icon: '📡',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'font_cache',
      name: '字体缓存',
      desc: '系统字体缓存文件，清理后自动重建',
      paths: ['$localAppData\\Microsoft\\Windows\\Fonts'],
      safe: true,
      icon: '🔤',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_update_cleanup',
      name: 'Windows更新清理',
      desc: '系统更新后残留的安装文件',
      paths: [
        'C:\\Windows\\Temp',
        'C:\\Windows\\SoftwareDistribution\\Download',
        'C:\\Windows\\WinSxS\\Temp',
      ],
      safe: true,
      icon: '🔧',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'system_junk',
      name: '系统冗余组件',
      desc: '系统无用的冗余文件',
      paths: [
        'C:\\Windows\\Help',
        'C:\\Windows\\Media',
        'C:\\Windows\\Resources\\Themes',
      ],
      safe: false,
      icon: '🗑️',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_installer_cache',
      name: 'Windows Installer缓存',
      desc: '系统安装程序缓存文件',
      paths: ['C:\\Windows\\Installer'],
      safe: false,
      icon: '📦',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'driver_store',
      name: '驱动程序包缓存',
      desc: '系统驱动存储区中的旧驱动包',
      paths: ['C:\\Windows\\System32\\DriverStore\\FileRepository'],
      safe: false,
      icon: '🔌',
      category: '驱动缓存',
    ),
    // 浏览器
    ScanCategory(
      id: 'inet_cache',
      name: 'IE/Edge网络缓存',
      desc: 'Internet Explorer和Edge网络缓存（不含Cookie）',
      paths: [
        '$localAppData\\Microsoft\\Windows\\INetCache',
        '$localAppData\\Microsoft\\Windows\\WebCache',
      ],
      safe: true,
      icon: '🌐',
      category: '浏览器',
    ),
    ScanCategory(
      id: 'inet_cookies',
      name: 'IE/Edge Cookie（谨慎清理）',
      desc: '删除后需重新登录网站',
      paths: ['$localAppData\\Microsoft\\Windows\\INetCookies'],
      safe: false,
      icon: '🍪',
      category: '浏览器',
    ),
    ScanCategory(
      id: 'browser_cache_chrome',
      name: 'Chrome浏览器缓存',
      desc: 'Google Chrome缓存数据',
      paths: ['$localAppData\\Google\\Chrome\\User Data\\Default\\Cache'],
      safe: true,
      icon: '🌐',
      category: '浏览器',
    ),
    ScanCategory(
      id: 'browser_cache_edge',
      name: 'Edge浏览器缓存',
      desc: 'Microsoft Edge缓存数据',
      paths: ['$localAppData\\Microsoft\\Edge\\User Data\\Default\\Cache'],
      safe: true,
      icon: '🌐',
      category: '浏览器',
    ),
    // 办公软件
    ScanCategory(
      id: 'ms_office_cache',
      name: 'MS Office缓存',
      desc: 'Microsoft Office缓存文件',
      paths: [
        '$localAppData\\Microsoft\\Office',
        '$appData\\Microsoft\\Office',
        '$localAppData\\Microsoft\\Office\\16.0\\OfficeFileCache',
        '$localAppData\\Microsoft\\Office\\16.0\\WebServiceCache',
      ],
      safe: true,
      icon: '📊',
      category: '办公软件',
    ),
    // 驱动缓存
    ScanCategory(
      id: 'amd_driver_cache',
      name: 'AMD显卡缓存',
      desc: 'AMD显卡驱动安装缓存',
      paths: [
        '$localAppData\\AMD',
        '$temp\\AMD',
      ],
      safe: true,
      icon: '🎮',
      category: '驱动缓存',
    ),
    ScanCategory(
      id: 'nvidia_driver_cache',
      name: 'NVIDIA显卡缓存',
      desc: 'NVIDIA显卡驱动安装缓存',
      paths: [
        '$localAppData\\NVIDIA',
        '$temp\\NVIDIA',
        '$localAppData\\NVIDIA Corporation',
      ],
      safe: true,
      icon: '🟢',
      category: '驱动缓存',
    ),
    // 系统备份
    ScanCategory(
      id: 'ios_backup',
      name: 'iOS设备备份',
      desc: 'iTunes/Finder手机备份数据（谨慎清理）',
      paths: [
        '$appData\\Apple Computer\\MobileSync\\Backup',
        '$userProfile\\Apple\\MobileSync\\Backup',
      ],
      safe: false,
      icon: '📱',
      category: '系统备份',
    ),
    // 其他系统缓存
    ScanCategory(
      id: 'windows_search_index',
      name: 'Windows搜索索引缓存',
      desc: '搜索索引数据库（清理后自动重建）',
      paths: ['C:\\ProgramData\\Microsoft\\Search\\Data'],
      safe: false,
      icon: '🔍',
      category: '系统缓存',
    ),
    ScanCategory(
      id: 'windows_defender_cache',
      name: 'Windows Defender缓存',
      desc: 'Defender扫描缓存和隔离文件',
      paths: [
        'C:\\ProgramData\\Microsoft\\Windows Defender',
        'C:\\ProgramData\\Microsoft\\Windows Defender\\Scans',
      ],
      safe: false,
      icon: '🛡️',
      category: '系统缓存',
    ),
  ];
}

// 深度扫描类别
final List<ScanCategory> DEEP_SCAN_CATEGORIES = [
  ScanCategory(
    id: 'deep_logs',
    name: '日志文件',
    desc: '全盘扫描.log/.evt/.evtx/.etl等日志文件',
    paths: [],
    safe: true,
    icon: '📋',
    category: '系统垃圾',
    scanType: 'deep_logs',
  ),
  ScanCategory(
    id: 'deep_temp',
    name: '临时文件',
    desc: '深度扫描所有Temp目录和.tmp文件',
    paths: [],
    safe: true,
    icon: '📄',
    category: '系统垃圾',
    scanType: 'deep_temp',
  ),
  ScanCategory(
    id: 'deep_installer',
    name: '安装包残留',
    desc: '深度扫描所有安装包和更新包文件',
    paths: [],
    safe: true,
    icon: '📦',
    category: '系统垃圾',
    scanType: 'deep_installer',
  ),
  ScanCategory(
    id: 'deep_patches',
    name: '系统补丁缓存',
    desc: 'Windows更新补丁、KB补丁残留文件',
    paths: [],
    safe: true,
    icon: '🔧',
    category: '系统垃圾',
    scanType: 'deep_patches',
  ),
  ScanCategory(
    id: 'deep_junk_ext',
    name: '垃圾文件扩展名',
    desc: '扫描.tmp/.bak/.old/.chk等垃圾文件',
    paths: [],
    safe: true,
    icon: '🗑️',
    category: '系统垃圾',
    scanType: 'deep_junk_ext',
  ),
  ScanCategory(
    id: 'deep_system_garbage',
    name: '系统使用垃圾',
    desc: '系统运行产生的日志/报告/转储/备份（谨慎清理）',
    paths: [],
    safe: false,
    icon: '🔧',
    category: '系统垃圾',
    scanType: 'deep_system_garbage',
  ),
  ScanCategory(
    id: 'deep_browser_data',
    name: '所有浏览器缓存（深度扫描）',
    desc: '扫描所有浏览器的Cache/Code Cache/GPUCache',
    paths: [],
    safe: true,
    icon: '🌐',
    category: '浏览器',
    scanType: 'deep_browser_data',
  ),
  ScanCategory(
    id: 'deep_browser_data_caution',
    name: '浏览器登录数据（谨慎清理）',
    desc: 'Session/Local Storage/IndexedDB等，可能包含登录信息',
    paths: [],
    safe: false,
    icon: '⚠️',
    category: '浏览器',
    scanType: 'deep_browser_data_caution',
  ),
  ScanCategory(
    id: 'pycache',
    name: 'Python __pycache__',
    desc: 'Python编译缓存文件（全盘扫描）',
    paths: [],
    safe: true,
    icon: '🐍',
    category: '开发工具',
    scanType: 'pycache',
  ),
  ScanCategory(
    id: 'deep_dev_cache',
    name: '其他开发缓存（自动发现）',
    desc: '自动扫描所有开发工具缓存',
    paths: [],
    safe: true,
    icon: '💻',
    category: '开发工具',
    scanType: 'deep_dev_cache',
  ),
];
