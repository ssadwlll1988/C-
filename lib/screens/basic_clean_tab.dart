import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';
import '../utils/disk_utils.dart';
import '../config/scan_categories.dart';

class BasicCleanTab extends StatelessWidget {
  const BasicCleanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildToolbar(context, provider),
              const SizedBox(height: 16),
              _buildProgress(provider),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, CleanProvider provider) {
    final busy = provider.isScanning || provider.isCleaning;
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: busy ? null : () => provider.startScan(),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('开始扫描'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6CF7),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: busy ? null : () => provider.startClean(),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('一键清理'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 16),
        Checkbox(
          value: _isAllSelected(provider),
          tristate: true,
          onChanged: busy
              ? null
              : (value) => provider.toggleAll(value ?? false),
        ),
        const Text('全选', style: TextStyle(fontSize: 12)),
        const Spacer(),
        Text(
          '可清理：${DiskUtils.formatSize(provider.totalSelectedSize)}',
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF00B894),
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProgress(CleanProvider provider) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: provider.progress,
          backgroundColor: const Color(0xFFE0E0E0),
          valueColor: AlwaysStoppedAnimation<Color>(
            provider.isCleaning
                ? const Color(0xFFE74C3C)
                : const Color(0xFF4A6CF7),
          ),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(provider.statusText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF636E72))),
        ),
      ],
    );
  }

  Widget _buildGrid(CleanProvider provider) {
    final grouped = <String, List<ScanCategory>>{};
    for (final cat in provider.scanCategories) {
      final size = provider.scanResults[cat.id] ?? 0;
      if (size > 0 || provider.isScanning) {
        grouped.putIfAbsent(cat.category, () => []).add(cat);
      }
    }
    final categoryNames = grouped.keys.toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final catName in categoryNames) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(
                catName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6CF7)),
              ),
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: grouped[catName]!.length,
              itemBuilder: (ctx, idx) {
                final cat = grouped[catName]![idx];
                final size = provider.scanResults[cat.id] ?? 0;
                final selected =
                    provider.selectedItems[cat.id] ?? false;
                return _buildCard(provider, cat, size, selected);
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCard(CleanProvider provider, ScanCategory cat, int size,
      bool selected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected
                ? const Color(0xFF4A6CF7).withOpacity(0.5)
                : const Color(0xFFE0E6ED)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: selected,
                  onChanged: provider.isScanning || provider.isCleaning
                      ? null
                      : (v) => provider.toggleSelection(cat.id, v ?? false),
                ),
              ),
              const SizedBox(width: 4),
              Text(cat.icon, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                size > 0 ? DiskUtils.formatSize(size) : '-',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: size > 0
                      ? const Color(0xFF00B894)
                      : const Color(0xFFB2BEC3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            cat.safe ? cat.name : '${cat.name} *',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            cat.desc,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF636E72)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool? _isAllSelected(CleanProvider provider) {
    if (provider.scanResults.isEmpty) return false;
    final totalItems =
        provider.scanResults.entries.where((e) => e.value > 0).length;
    if (totalItems == 0) return false;
    final selectedItems = provider.selectedItems.entries
        .where((e) =>
            e.value &&
            provider.scanResults.containsKey(e.key) &&
            provider.scanResults[e.key]! > 0)
        .length;
    if (selectedItems == 0) return false;
    if (selectedItems == totalItems) return true;
    return null;
  }
}
