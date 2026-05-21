import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';
import '../utils/disk_utils.dart';

class BasicCleanTab extends StatelessWidget {
  const BasicCleanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Toolbar
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: provider.isScanning || provider.isCleaning 
                        ? null 
                        : () => provider.startScan(),
                    icon: const Icon(Icons.search),
                    label: const Text('🔍 扫描垃圾文件'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: provider.isScanning || provider.isCleaning 
                        ? null 
                        : () => provider.startClean(),
                    icon: const Icon(Icons.delete),
                    label: const Text('🗑️ 清理选中项'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '可清理: ${_getSelectedSize(provider)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Progress bar
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  provider.isCleaning ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                provider.statusText,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              
              // Results list
              Expanded(
                child: ListView.builder(
                  itemCount: provider.scanCategories.length,
                  itemBuilder: (context, index) {
                    final category = provider.scanCategories[index];
                    final size = provider.scanResults[category.id] ?? 0;
                    final isSelected = provider.selectedItems[category.id] ?? false;
                    
                    if (size == 0 && !provider.isScanning) {
                      return const SizedBox.shrink();
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: provider.isScanning || provider.isCleaning
                              ? null
                              : (value) => provider.toggleSelection(category.id, value ?? false),
                        ),
                        title: Text(
                          '${category.icon} ${category.name}${!category.safe ? ' ⚠️' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(category.desc),
                        trailing: Text(
                          size > 0 ? DiskUtils.formatSize(size) : '-',
                          style: TextStyle(
                            color: size > 0 ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSelectedSize(CleanProvider provider) {
    int total = 0;
    for (final entry in provider.selectedItems.entries) {
      if (entry.value && provider.scanResults.containsKey(entry.key)) {
        total += provider.scanResults[entry.key]!;
      }
    }
    return DiskUtils.formatSize(total);
  }
}