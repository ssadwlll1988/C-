import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../config/analysis_config.dart';
import '../utils/disk_utils.dart';

const List<Color> ANALYSIS_COLORS = [
  Color(0xFFE94560), Color(0xFF0F3460), Color(0xFFE6A817),
  Color(0xFF16C79A), Color(0xFFFF6B6B), Color(0xFF48DBFB),
  Color(0xFFFECA57), Color(0xFFFF9FF3), Color(0xFF54A0FF),
  Color(0xFF5F27CD), Color(0xFF01A3A4), Color(0xFFF368E0),
  Color(0xFF2ED573), Color(0xFFFF4757), Color(0xFFC44569),
];

class AnalysisTab extends StatelessWidget {
  const AnalysisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (ctx, p, _) {
        return Container(
          color: const Color(0xFFF5F7FA),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Toolbar(p: p),
              const SizedBox(height: 16),
              _ProgressBar(p: p),
              const SizedBox(height: 6),
              _Breadcrumb(p: p),
              const SizedBox(height: 8),
              if (p.items.isEmpty && !p.scanning)
                Expanded(child: _buildEmpty())
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ChartCard(p: p),
                        const SizedBox(height: 10),
                        _TreeCard(p: p),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pie_chart_outline, size: 70, color: Color(0xFFB2BEC3)),
          SizedBox(height: 10),
          Text('暂无分析数据',
              style: TextStyle(fontSize: 15, color: Color(0xFF636E72))),
          SizedBox(height: 4),
          Text('点击"开始分析"按钮，扫描 C 盘空间占用',
              style: TextStyle(fontSize: 12, color: Color(0xFFB2BEC3))),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AnalysisProvider p;
  const _Toolbar({required this.p});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: p.scanning ? null : () => p.startAnalyze(),
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('开始分析'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
        const SizedBox(width: 8),
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
        const Spacer(),
        if (p.totalSize > 0)
          Text(
            '当前已用：${DiskUtils.formatSize(p.totalSize)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B894)),
          ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AnalysisProvider p;
  const _ProgressBar({required this.p});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p.progress,
            backgroundColor: const Color(0xFFE0E6ED),
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4A6CF7)),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(p.status,
            style: const TextStyle(fontSize: 11, color: Color(0xFF636E72))),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final AnalysisProvider p;
  const _Breadcrumb({required this.p});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.folder_open, size: 14, color: Color(0xFF636E72)),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < p.breadcrumb.length; i++) ...[
                  if (i > 0)
                    const Text(' › ',
                        style: TextStyle(
                            color: Color(0xFF636E72), fontSize: 11)),
                  InkWell(
                    onTap: p.scanning
                        ? null
                        : () => p.goToBreadcrumb(i),
                    child: Text(
                      i == 0
                          ? 'C:\\'
                          : p.breadcrumb[i]
                              .split(Platform.pathSeparator)
                              .where((s) => s.isNotEmpty)
                              .last,
                      style: TextStyle(
                          fontSize: 11,
                          color: i == p.breadcrumb.length - 1
                              ? const Color(0xFF4A6CF7)
                              : const Color(0xFF74B9FF),
                          fontWeight: i == p.breadcrumb.length - 1
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (p.breadcrumb.length > 1)
          InkWell(
            onTap: p.scanning ? null : () => p.goToBreadcrumb(0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('⬆ 返回 C 盘',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00B894),
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final AnalysisProvider p;
  const _ChartCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final top = p.topItemsForChart;
    final total = p.totalSize;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final isWide = c.maxWidth > 600;
          final pie = SizedBox(
            width: 280,
            height: 280,
            child: GestureDetector(
              onTapUp: (d) {
                final idx = _hitTestPie(
                    d.localPosition, const Size(280, 280), top, total);
                if (idx == null) return;
                final item = top[idx];
                if (item.name == '其他' || item.path.isEmpty) return;
                p.drillInto(item.path);
              },
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _PiePainter(items: top, total: total),
              ),
            ),
          );
          final legend = _Legend(items: top, total: total, provider: p);
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                pie,
                const SizedBox(width: 16),
                Expanded(child: legend),
              ],
            );
          } else {
            return Column(
              children: [pie, const SizedBox(height: 12), legend],
            );
          }
        },
      ),
    );
  }

  int? _hitTestPie(Offset pos, Size size, List<AnalysisItem> items, int total) {
    if (total == 0 || items.isEmpty) return null;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 24;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > r) return null;
    double ang = math.atan2(dy, dx) * 180 / math.pi;
    if (ang < 0) ang += 360;
    double start = 0;
    for (int i = 0; i < items.length; i++) {
      final ext = items[i].size / total * 360;
      if (ang >= start && ang < start + ext) return i;
      start += ext;
    }
    return null;
  }
}

class _PiePainter extends CustomPainter {
  final List<AnalysisItem> items;
  final int total;
  _PiePainter({required this.items, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 24;

    if (total == 0 || items.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
            text: '无数据',
            style: TextStyle(color: Color(0xFF636E72), fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      return;
    }

    double startAngle = -math.pi / 2;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < items.length; i++) {
      final sweep = items[i].size / total * 2 * math.pi;
      final fill = Paint()
        ..color = ANALYSIS_COLORS[i % ANALYSIS_COLORS.length]
        ..style = PaintingStyle.fill;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, startAngle, sweep, true, fill);
      canvas.drawArc(rect, startAngle, sweep, true, stroke);

      final pct = items[i].size / total;
      if (pct > 0.04) {
        final mid = startAngle + sweep / 2;
        final lr = r * 0.65;
        final lx = cx + lr * math.cos(mid);
        final ly = cy + lr * math.sin(mid);
        final tp = TextPainter(
          text: TextSpan(
            text: '${(pct * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.items != items || old.total != total;
}

class _Legend extends StatelessWidget {
  final List<AnalysisItem> items;
  final int total;
  final AnalysisProvider provider;
  const _Legend(
      {required this.items, required this.total, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || total == 0) {
      return const Center(child: Text('暂无数据'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('📋 图例（点击进入分析）',
              style: TextStyle(
                  color: Color(0xFF4A6CF7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < items.length; i++)
              SizedBox(
                width: 200,
                child: InkWell(
                  onTap: items[i].name == '其他' || items[i].path.isEmpty
                      ? null
                      : () => provider.drillInto(items[i].path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE0E6ED)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: ANALYSIS_COLORS[
                                  i % ANALYSIS_COLORS.length],
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            items[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2D3436),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          DiskUtils.formatSize(items[i].size),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF636E72),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TreeCard extends StatelessWidget {
  final AnalysisProvider p;
  const _TreeCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF4A6CF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Icon(Icons.folder_special, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text('一级目录详情（单击展开，双击进入分析）',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                    width: 100,
                    child: Text('占用大小',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                SizedBox(
                    width: 60,
                    child: Text('占比',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 90,
                    child: Text('分类',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          for (final item in p.items) _TreeRow(item: item, depth: 0, p: p),
        ],
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  final AnalysisItem item;
  final int depth;
  final AnalysisProvider p;
  const _TreeRow({required this.item, required this.depth, required this.p});

  Future<void> _showContextMenu(BuildContext context, Offset pos) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      items: const [
        PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 16, color: Color(0xFF4A6CF7)),
              SizedBox(width: 8),
              Text('打开资源管理器'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'drill',
          child: Row(
            children: [
              Icon(Icons.zoom_in, size: 16, color: Color(0xFF00B894)),
              SizedBox(width: 8),
              Text('深入分析此目录'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 16, color: Color(0xFFE74C3C)),
              SizedBox(width: 8),
              Text('删除目录',
                  style: TextStyle(color: Color(0xFFE74C3C))),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (result) {
      case 'open':
        await p.openInExplorer(item.path);
        break;
      case 'drill':
        if (item.path.isNotEmpty) await p.drillInto(item.path);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('⚠️ 确认删除'),
            content: Text(
                '将永久删除：\n\n${item.path}\n\n大小：${DiskUtils.formatSize(item.size)}\n\n该操作不可恢复，是否继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE74C3C)),
                child: const Text('确定删除'),
              ),
            ],
          ),
        );
        if (ok == true) {
          final success = await p.deleteItem(item);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '已删除' : '删除失败（可能权限不足）'),
                backgroundColor: success
                    ? const Color(0xFF00B894)
                    : const Color(0xFFE74C3C),
              ),
            );
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = p.totalSize > 0 ? item.size / p.totalSize * 100 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (d) =>
              _showContextMenu(context, d.globalPosition),
          child: InkWell(
            onTap: () => p.toggleExpand(item),
            onDoubleTap: () {
              if (item.path.isNotEmpty) {
                p.drillInto(item.path);
              }
            },
          child: Container(
            padding: EdgeInsets.only(
                left: 14.0 + depth * 18,
                right: 14,
                top: 8,
                bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: item.loading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A6CF7))))
                      : Icon(
                          item.expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFF636E72),
                          size: 16,
                        ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.folder,
                    color: getCategoryColor(item.category), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2D3436),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(DiskUtils.formatSize(item.size),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B894))),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text('${pct.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF636E72))),
                ),
                SizedBox(
                  width: 90,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: getCategoryColor(item.category),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(item.category,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        if (item.expanded && item.loaded)
          for (final c in item.children)
            _TreeRow(item: c, depth: depth + 1, p: p),
        if (item.expanded && item.loading)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14.0 + (depth + 1) * 18),
            color: const Color(0xFFFAFBFC),
            child: Row(
              children: const [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF39C12)))),
                SizedBox(width: 8),
                Text('正在扫描子目录...',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFF39C12))),
              ],
            ),
          ),
      ],
    );
  }
}



