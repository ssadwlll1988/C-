import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deep_scan_provider.dart';
import '../utils/disk_utils.dart';

class DeepScanTab extends StatelessWidget {
  const DeepScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeepScanProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildToolbar(provider),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  provider.cleaning
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF4A6CF7),
                ),
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
              Expanded(child: _buildGrid(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(DeepScanProvider provider) {
    final busy = provider.scanning || provider.cleaning;
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: busy ? null : () => provider.startScan(),
          icon: const Icon(Icons.travel_explore, size: 16),
          label: const Text('深度扫描'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6CF7),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: busy ? null : () => provider.startClean(),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('清理选中'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        Checkbox(
          value: false,
          onChanged: busy ? null : (v) => provider.selectAllSafe(v ?? false),
        ),
        const Text('全选安全项', style: TextStyle(fontSize: 12)),
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

  Widget _buildGrid(DeepScanProvider provider) {
    final grouped = <String, List<DeepScanItem>>{};
    provider.results.forEach((id, item) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    });
    final names = grouped.keys.toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in names) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(n,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6CF7))),
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 4.2,
              ),
              itemCount: grouped[n]!.length,
              itemBuilder: (ctx, idx) {
                final it = grouped[n]![idx];
                final sel = provider.selected[it.id] ?? false;
                return _buildCard(provider, it, sel);
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCard(
      DeepScanProvider provider, DeepScanItem it, bool selected) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: selected,
              onChanged: provider.scanning || provider.cleaning
                  ? null
                  : (v) => provider.toggle(it.id, v ?? false),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E6ED)),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                it.icon,
                style: const TextStyle(fontSize: 22, height: 1.0),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        it.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!it.safe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAA7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('谨慎',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFFD63031),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(it.desc,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF636E72)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            it.size > 0 ? DiskUtils.formatSize(it.size) : '-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: it.size > 0
                  ? const Color(0xFF00B894)
                  : const Color(0xFFB2BEC3),
            ),
          ),
        ],
      ),
    );
  }
}
