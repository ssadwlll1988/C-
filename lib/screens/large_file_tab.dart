import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/large_file_provider.dart';
import '../utils/disk_utils.dart';

class LargeFileTab extends StatelessWidget {
  const LargeFileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LargeFileProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildToolbar(context, provider),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4A6CF7)),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(provider.status,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF636E72))),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildList(context, provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext ctx, LargeFileProvider p) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: p.scanning ? null : () => p.startScan(),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('扫描大文件'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: !p.scanning ? null : () => p.pauseResume(),
          icon: Icon(p.paused ? Icons.play_arrow : Icons.pause, size: 16),
          label: Text(p.paused ? '继续' : '暂停'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39C12),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: !p.scanning ? null : () => p.stop(),
          icon: const Icon(Icons.stop, size: 16),
          label: const Text('停止'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        ElevatedButton.icon(
          onPressed: p.selected.isEmpty
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('确认删除'),
                      content: Text(
                          '将永久删除 ${p.selected.length} 个文件，且无法恢复，是否继续？'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('取消')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('确定删除')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final freed = await p.deleteSelected();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(
                              '已释放 ${DiskUtils.formatSize(freed)}')));
                    }
                  }
                },
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('删除选中'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('阈值：', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            DropdownButton<int>(
              value: p.thresholdMB,
              isDense: true,
              items: const [50, 100, 200, 500, 1000]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text('$e MB')))
                  .toList(),
              onChanged: p.scanning
                  ? null
                  : (v) {
                      if (v != null) p.setThreshold(v);
                    },
            ),
          ],
        ),
        Text(
          '共找到：${p.files.length} 个文件 | ${DiskUtils.formatSize(p.totalSize)}',
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00B894),
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext ctx, LargeFileProvider p) {
    if (p.files.isEmpty) {
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
              Icon(Icons.folder_open_outlined,
                  size: 60, color: Color(0xFFB2BEC3)),
              SizedBox(height: 8),
              Text('暂未扫描到大文件',
                  style: TextStyle(color: Color(0xFF636E72))),
            ],
          ),
        ),
      );
    }
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
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
                    flex: 3,
                    child: Text('文件名',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 4,
                    child: Text('所在目录',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 90,
                    child: Text('大小',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 60,
                    child: Text('类型',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 130,
                    child: Text('修改时间',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: p.files.length,
              itemBuilder: (c, i) {
                final f = p.files[i];
                final sel = p.selected.contains(f.path);
                return InkWell(
                  onTap: () => p.toggleSelect(f.path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: sel
                        ? const Color(0xFFE3F2FD)
                        : (i.isOdd ? const Color(0xFFFAFAFA) : null),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Checkbox(
                            value: sel,
                            onChanged: (_) => p.toggleSelect(f.path),
                          ),
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(f.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))),
                        Expanded(
                            flex: 4,
                            child: Text(f.dir,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey))),
                        SizedBox(
                            width: 90,
                            child: Text(DiskUtils.formatSize(f.size),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00B894)))),
                        SizedBox(
                            width: 60,
                            child: Text(f.fileType,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11))),
                        SizedBox(
                            width: 130,
                            child: Text(
                              f.modified.millisecondsSinceEpoch == 0
                                  ? '-'
                                  : fmt.format(f.modified),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
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
