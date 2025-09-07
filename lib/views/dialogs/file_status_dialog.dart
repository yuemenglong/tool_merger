import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../entity/entity.dart';
import '../../controllers/project_controller.dart';
import '../../utils/path_utils.dart';
import '../../utils/file_explorer_utils.dart';
import '../widgets/common_widgets.dart';

/// 可排序的文件状态对话框
class SortableFileStatusDialog extends StatefulWidget {
  const SortableFileStatusDialog({super.key});

  @override
  State<SortableFileStatusDialog> createState() => _SortableFileStatusDialogState();
}

class _SortableFileStatusDialogState extends State<SortableFileStatusDialog> {
  // 排序状态
  int _sortColumnIndex = 0; // 0: 路径, 1: 后缀, 2: 行数, 3: 文件大小
  bool _sortAscending = true;
  
  @override
  Widget build(BuildContext context) {
    final status = Get.arguments as GenerateStatus;
    
    // 获取屏幕大小
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.9;

    // 计算公共父目录
    final allPaths = status.fileStatuses?.map((fs) => fs.fullPath ?? '').where((path) => path.isNotEmpty).toList() ?? [];
    final commonParent = PathUtils.findCommonParentPath(allPaths);

    // 排序文件状态列表
    final sortedFileStatuses = _getSortedFileStatuses(status.fileStatuses ?? [], commonParent);

    return AlertDialog(
      title: Row(
        children: [
          const Text('文件状态信息'),
          if (commonParent != null) ...[
            const Spacer(),
            Tooltip(
              message: '公共父目录: $commonParent',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '基于: ${commonParent.split(RegExp(r'[/\\]')).last}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '生成时间: ${_formatDateTime(status.generateTime)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('项目名称: ${status.projectName ?? "未知"}', style: const TextStyle(fontSize: 14)),
                  Text('文件总数: ${status.fileStatuses?.length ?? 0}', style: const TextStyle(fontSize: 14)),
                  if (commonParent != null)
                    Text('公共目录: $commonParent', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 文件列表表格
            Row(
              children: [
                const Text(
                  '文件详情:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  '点击列标题可排序',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    // 表头
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildSortableHeader('文件路径', 0, flex: 5),
                          _buildSortableHeader('后缀', 1, flex: 1),
                          _buildSortableHeader('行数', 2, flex: 1),
                          _buildSortableHeader('文件大小', 3, flex: 1),
                          // 新增操作列的表头
                          Expanded(
                            flex: 2, // 分配2个弹性空间
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                '操作',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 表格内容
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedFileStatuses.length,
                        itemBuilder: (context, index) {
                          final fileStatus = sortedFileStatuses[index];
                          final displayPath = PathUtils.getDisplayPath(fileStatus.fullPath ?? '', commonParent);
                          
                          return Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Tooltip(
                                      message: fileStatus.fullPath ?? '',
                                      child: Text(
                                        displayPath,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      fileStatus.extension ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${fileStatus.lineCount ?? 0}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      CommonWidgets.formatFileSize(fileStatus.fileSize ?? 0),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                // 新增：操作按钮列
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 按钮1: 在文件夹中打开
                                      IconButton(
                                        icon: const Icon(Icons.folder_open),
                                        iconSize: 18.0,
                                        color: Colors.blue.shade700,
                                        tooltip: '在文件夹中显示',
                                        onPressed: () {
                                          FileExplorerUtils.openInExplorer(fileStatus.fullPath);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      // 按钮2: 添加到当前项目
                                      IconButton(
                                        icon: const Icon(Icons.add_to_photos),
                                        iconSize: 18.0,
                                        color: Colors.green.shade700,
                                        tooltip: '添加到当前项目',
                                        onPressed: () {
                                          // 获取Controller实例并调用新方法
                                          final controller = Get.find<ProjectController>();
                                          controller.addItemFromFileStatus(fileStatus);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 构建可排序的表头
  Widget _buildSortableHeader(String title, int columnIndex, {required int flex}) {
    final isCurrentSort = _sortColumnIndex == columnIndex;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumnIndex == columnIndex) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumnIndex = columnIndex;
              _sortAscending = true;
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCurrentSort ? Colors.blue.shade700 : null,
                ),
              ),
              const SizedBox(width: 4),
              if (isCurrentSort)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.blue.shade700,
                )
              else
                Icon(
                  Icons.unfold_more,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取排序后的文件状态列表
  List<FileStatusInfo> _getSortedFileStatuses(List<FileStatusInfo> fileStatuses, String? commonParent) {
    final sortedList = List<FileStatusInfo>.from(fileStatuses);
    
    sortedList.sort((a, b) {
      int comparison = 0;
      
      switch (_sortColumnIndex) {
        case 0: // 文件路径
          final pathA = PathUtils.getDisplayPath(a.fullPath ?? '', commonParent);
          final pathB = PathUtils.getDisplayPath(b.fullPath ?? '', commonParent);
          comparison = pathA.compareTo(pathB);
          break;
        case 1: // 后缀
          final extA = a.extension ?? '';
          final extB = b.extension ?? '';
          comparison = extA.compareTo(extB);
          break;
        case 2: // 行数
          final lineA = a.lineCount ?? 0;
          final lineB = b.lineCount ?? 0;
          comparison = lineA.compareTo(lineB);
          break;
        case 3: // 文件大小
          final sizeA = a.fileSize ?? 0;
          final sizeB = b.fileSize ?? 0;
          comparison = sizeA.compareTo(sizeB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedList;
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知时间';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}