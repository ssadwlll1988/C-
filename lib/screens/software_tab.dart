import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/software_provider.dart';
import '../utils/disk_utils.dart';

class SoftwareTab extends StatelessWidget {
  const SoftwareTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SoftwareProvider>(
      builder: (context, p, _) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildToolbar(context, p),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: p.progress,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  p.migrating
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFF4A6CF7),
                ),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(p.status,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF636E72))),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildTable(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext ctx, SoftwareProvider p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: p.scanning || p.migrating ? null : () => p.startScan(),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('扫描已装软件'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: p.scanning || p.migrating
              ? null
              : () async {
                  final selected = p.apps.where((a) => a.selected).toList();
                  if (selected.isEmpty) return;
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('确认搬迁'),
                      content: Text(
                          '将 ${selected.length} 个软件搬迁到 ${p.targetDrive}\\MigratedApps\\\n\n'
                          '提示：本操作需要管理员权限，原目录将被替换为符号链接，软件仍能从原路径运行。'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('取消')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('确定搬迁')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await p.migrateSelected();
                  }
                },
          icon: const Icon(Icons.drive_file_move, size: 16),
          label: const Text('搬迁选中软件'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: p.scanning || p.migrating
              ? null
              : () async {
                  final selected = p.apps
                      .where((a) => a.selected && a.isJunction)
                      .toList();
                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('请勾选带「已搬迁」标记的软件')),
                    );
                    return;
                  }
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('确认还原'),
                      content: Text(
                          '将 ${selected.length} 个软件从目标盘还原回 C 盘原位置？\n\n'
                          '注意：会占用 C 盘空间。'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('取消')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('确定还原')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await p.restoreSelected();
                  }
                },
          icon: const Icon(Icons.restore, size: 16),
          label: const Text('还原选中'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: p.scanning || p.migrating
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('清理冗余副本'),
                      content: Text(
                          '将删除 ${p.targetDrive}\\MigratedApps\\ 下未被任何 Junction 引用的目录。\n\n'
                          '常见场景：反复点击搬迁产生的 xxx_时间戳 目录。'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('取消')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('确定清理')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final n = await p.cleanRedundantCopies();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('已删除 $n 个冗余副本')));
                    }
                  }
                },
          icon: const Icon(Icons.cleaning_services, size: 16),
          label: const Text('清理冗余副本'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39C12),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('目标盘：', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            DropdownButton<String>(
              value: p.availableDrives.contains(p.targetDrive)
                  ? p.targetDrive
                  : p.availableDrives.first,
              isDense: true,
              items: p.availableDrives
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: p.scanning || p.migrating
                  ? null
                  : (v) {
                      if (v != null) p.setTargetDrive(v);
                    },
            ),
          ],
        ),
        Text(
          '共 ${p.apps.length} 个软件',
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00B894),
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTable(SoftwareProvider p) {
    if (p.apps.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E6ED)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.apps_outlined,
                  size: 60, color: Color(0xFFB2BEC3)),
              SizedBox(height: 8),
              Text('暂未扫描已安装软件',
                  style: TextStyle(color: Color(0xFF636E72))),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E6ED)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF0F2F5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: const [
                SizedBox(width: 32),
                Expanded(
                    flex: 4,
                    child: Text('软件名称',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('发行商',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 100,
                    child: Text('版本',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 100,
                    child: Text('占用空间',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 5,
                    child: Text('安装位置',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: p.apps.length,
              itemBuilder: (c, i) {
                final app = p.apps[i];
                return InkWell(
                  onTap: () => p.toggle(i, !app.selected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: app.selected
                        ? const Color(0xFFE3F2FD)
                        : (i.isOdd ? const Color(0xFFFAFAFA) : null),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Checkbox(
                            value: app.selected,
                            onChanged: (v) => p.toggle(i, v ?? false),
                          ),
                        ),
                        Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(app.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                                if (app.isJunction) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00B894),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('已搬迁',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            )),
                        Expanded(
                            flex: 3,
                            child: Text(app.publisher,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11))),
                        SizedBox(
                            width: 100,
                            child: Text(app.version,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11))),
                        SizedBox(
                            width: 100,
                            child: Text(
                                app.actualSize > 0
                                    ? DiskUtils.formatSize(app.actualSize)
                                    : '-',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF00B894),
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 5,
                            child: Tooltip(
                              message: app.isJunction
                                  ? '${app.location}\n  ↳ ${app.junctionTarget}'
                                  : app.location,
                              child: Text(
                                  app.isJunction
                                      ? '${app.location}  →  ${app.junctionTarget}'
                                      : app.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: app.isJunction
                                          ? const Color(0xFF00B894)
                                          : Colors.grey)),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
