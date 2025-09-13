import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../controllers/project_controller.dart';
import '../entity/entity.dart';
import '../config.dart';
import '../dialogs.dart';
import '../utils/file_explorer_utils.dart';
import '../explorer/uni_file.dart';
import 'widgets/common_widgets.dart';

class ItemSectionView extends StatelessWidget {
  final ProjectController controller;
  
  const ItemSectionView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildItemTable(context)),
                  const SizedBox(width: 8),
                  _buildItemActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Icon(
            Icons.list_alt,
            color: Theme.of(context).colorScheme.secondary,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '项目文件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const Spacer(),
          _buildItemHeaderStats(context),
        ],
      ),
    );
  }

  Widget _buildItemHeaderStats(BuildContext context) {
    return Obx(() {
      if (controller.selectedProject.value != null) {
        return Row(
          children: [
            Chip(
              avatar: Icon(
                Icons.folder_open,
                size: 12,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              label: Text('${controller.currentItems.length}', style: TextStyle(fontSize: AppConfig.buttonFontSize)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Chip(
              avatar: Icon(
                Icons.check_circle,
                size: 12,
                color: AppConfig.enabledCountColor.shade700,
              ),
              label: Text('${controller.enabledItemsCount}', style: TextStyle(fontSize: AppConfig.buttonFontSize)),
              backgroundColor: AppConfig.enabledCountColor.shade100,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await controller.addDirectoriesToProject();
                },
                icon: const Icon(Icons.folder_open, size: 12),
                label: Text('Add Dirs', style: TextStyle(fontSize: AppConfig.buttonFontSize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildItemTable(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        await controller.handleDroppedFiles(detail.files);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            _buildItemTableHeader(context),
            Expanded(child: _buildItemTableBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTableHeader(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600),
          child: Row(
            children: [
              CommonWidgets.buildItemHeaderCell(context, '状态', 60),
              CommonWidgets.buildItemHeaderCell(context, '启用', 60),
              CommonWidgets.buildItemHeaderCell(context, '名称', 240),
              CommonWidgets.buildItemHeaderCell(context, '打开', 60),
              CommonWidgets.buildItemHeaderCell(context, '路径', 180),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTableBody(BuildContext context) {
    return Obx(() {
      return controller.currentItems.isEmpty
          ? _buildEmptyItemState(context)
          : ListView.builder(
              itemCount: controller.currentItems.length,
              itemBuilder: (context, index) {
                final item = controller.currentItems[index];
                return _buildItemRow(context, item, index);
              },
            );
    });
  }

  Widget _buildEmptyItemState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.selectedProject.value == null ? Icons.folder_outlined : Icons.note_add_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            controller.selectedProject.value == null ? '请先选择项目' : '暂无目录',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.selectedProject.value == null ? '从上方选择一个项目' : '点击 "Add Dirs" 或拖拽目录到此处',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: AppConfig.statusFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, ProjectItem item, int index) {
    return Obx(() {
      final isSelected = controller.selectedItem.value == item;
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)
              : index % 2 == 0
                  ? Colors.grey.shade50
                  : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              controller.selectItem(item);
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _buildItemStatusCell(context, item),
                      _buildItemEnabledCell(context, item),
                      _buildItemNameCell(context, item, isSelected),
                      _buildItemOpenCell(context, item),
                      _buildItemPathCell(context, item),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildItemStatusCell(BuildContext context, ProjectItem item) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Transform.scale(
          scale: 0.7,
          child: Switch(
            value: !(item.isExclude ?? false),
            onChanged: (value) async {
              await controller.toggleItemExclude(item);
            },
            activeColor: AppConfig.excludeSwitchActiveColor,
            inactiveThumbColor: AppConfig.excludeSwitchInactiveColor,
            inactiveTrackColor: AppConfig.excludeSwitchInactiveColor.withOpacity(0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildItemEnabledCell(BuildContext context, ProjectItem item) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: item.enabled ?? false,
            onChanged: (value) async {
              await controller.toggleItemEnabled(item);
            },
            activeColor: Theme.of(context).colorScheme.secondary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildItemNameCell(BuildContext context, ProjectItem item, bool isSelected) {
    return SizedBox(
      width: 240,
      child: FutureBuilder<bool>(
        future: _isItemDirectory(item.path),
        builder: (context, snapshot) {
          final bool isDirectory = snapshot.data ?? false;
          return Row(
            children: [
              // 文件/目录类型图标
              Icon(
                isDirectory ? Icons.folder_open : Icons.insert_drive_file_outlined,
                size: 14,
                color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey.shade600,
              ),
              const SizedBox(width: 2),
              // 文件来源类型指示器
              if (item.fileType == ProjectFileType.sftp) ...[
                Icon(
                  Icons.cloud,
                  size: 12,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 2),
              ] else ...[
                Icon(
                  Icons.storage,
                  size: 12,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  item.name ?? '',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: AppConfig.primaryFontSize,
                    color: isSelected ? Theme.of(context).colorScheme.secondary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _isItemDirectory(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final uniFile = LocalFile.create(path);
      return await uniFile.isDir();
    } catch (e) {
      return false;
    }
  }

  Widget _buildItemOpenCell(BuildContext context, ProjectItem item) {
    return SizedBox(
      width: 60,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.open_in_new_outlined),
          iconSize: 18.0,
          color: Colors.blue.shade700,
          tooltip: item.fileType == ProjectFileType.sftp ? '在SFTP浏览器中打开' : '在文件夹中显示',
          onPressed: () async {
            // 传递ProjectItem对象以支持SFTP路径
            await FileExplorerUtils.openInExplorer(item.path, projectItem: item);
          },
        ),
      ),
    );
  }

  Widget _buildItemPathCell(BuildContext context, ProjectItem item) {
    return SizedBox(
      width: 180,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(
          message: item.path ?? '',
          waitDuration: const Duration(milliseconds: 500),
          child: Text(
            item.path ?? '',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: AppConfig.secondaryFontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildItemActionButtons(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildDeleteItemButton(context),
          const SizedBox(height: 4),
          _buildMoveUpItemButton(context),
          const SizedBox(height: 4),
          _buildMoveDownItemButton(context),
        ],
      ),
    );
  }

  Widget _buildDeleteItemButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.delete,
      label: 'Delete',
      onPressed: controller.selectedProject.value != null && controller.selectedItem.value != null
          ? () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => ConfirmDeleteDialog(
                  title: '删除项目项',
                  content: '确定要删除项目项 "${controller.selectedItem.value?.name}" 吗？',
                ),
              );
              if (result == true && controller.selectedItem.value != null) {
                await controller.deleteItem(controller.selectedItem.value!);
              }
            }
          : null,
      color: AppConfig.deleteButtonColor,
    ));
  }

  Widget _buildMoveUpItemButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.keyboard_arrow_up,
      label: 'Up',
      onPressed: controller.selectedProject.value != null && controller.selectedItem.value != null
          ? () async {
              await controller.moveItemUp(controller.selectedItem.value!);
            }
          : null,
      color: AppConfig.moveButtonColor,
    ));
  }

  Widget _buildMoveDownItemButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.keyboard_arrow_down,
      label: 'Down',
      onPressed: controller.selectedProject.value != null && controller.selectedItem.value != null
          ? () async {
              await controller.moveItemDown(controller.selectedItem.value!);
            }
          : null,
      color: AppConfig.moveButtonColor,
    ));
  }
}