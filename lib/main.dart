import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'entity/entity.dart';
import 'dialogs.dart';
import 'controllers/project_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tool Merger',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.grey.shade600,
          primaryContainer: Colors.grey.shade50,
          onPrimaryContainer: Colors.grey.shade600,
          secondary: Colors.grey.shade600,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.grey.shade600,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          isDense: true,
        ),
      ),
      home: const ToolMergerHomePage(),
    );
  }
}

class ToolMergerHomePage extends StatelessWidget {
  const ToolMergerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectController controller = Get.put(ProjectController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Tool Merger',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        toolbarHeight: 48,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 上半部分 - 项目列表区域
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和过滤器行
                      SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '项目列表',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 150,
                              height: 32,
                              child: TextField(
                                onChanged: controller.setFilterText,
                                decoration: const InputDecoration(
                                  hintText: '搜索...',
                                  prefixIcon: Icon(Icons.search, size: 16),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 项目表格
                      Expanded(
                        child: Row(
                          children: [
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
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                '项目名称',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                '创建时间',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                '更新时间',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                '操作',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 项目列表
                                    Expanded(
                                      child: Obx(() {
                                        final filteredProjects = controller.filteredProjects;
                                        return filteredProjects.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.create_new_folder_outlined,
                                                      size: 32,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '暂无项目',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '点击右侧 "Create" 按钮创建',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade500,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: filteredProjects.length,
                                                itemBuilder: (context, index) {
                                                  final project = filteredProjects[index];
                                                  return Obx(() {
                                                    final isSelected = controller.selectedProject.value == project;
                                                    return Container(
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
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
                                                          onTap: () => controller.selectProject(project),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.folder,
                                                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                                                                        size: 14,
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Expanded(
                                                                        child: Text(
                                                                          project.name ?? '',
                                                                          style: TextStyle(
                                                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                            fontSize: 12,
                                                                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                                                          ),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Center(
                                                                    child: Text(
                                                                      _formatDateTime(project.createTime),
                                                                      style: TextStyle(
                                                                        color: Colors.grey.shade700,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Center(
                                                                    child: Text(
                                                                      _formatDateTime(project.updateTime),
                                                                      style: TextStyle(
                                                                        color: Colors.grey.shade700,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Center(
                                                                    child: SizedBox(
                                                                      height: 24,
                                                                      child: Obx(() => ElevatedButton.icon(
                                                                        onPressed: !controller.isGenerating.value ? () async {
                                                                          await controller.generateProject(project);
                                                                        } : null,
                                                                        icon: const Icon(Icons.build, size: 12),
                                                                        label: const Text('Generate', style: TextStyle(fontSize: 10)),
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: Theme.of(context).colorScheme.secondary,
                                                                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          minimumSize: const Size(0, 24),
                                                                        ),
                                                                      )),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  });
                                                },
                                              );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 右侧按钮列
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.add,
                                    label: 'Create',
                                    onPressed: () async {
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (context) => const CreateProjectDialog(),
                                      );
                                      if (result != null) {
                                        await controller.createProject(result);
                                      }
                                    },
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.delete,
                                        label: 'Delete',
                                        onPressed: controller.selectedProject.value != null
                                            ? () async {
                                                final result = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => ConfirmDeleteDialog(
                                                    title: '删除项目',
                                                    content: '确定要删除项目 "${controller.selectedProject.value?.name}" 吗？',
                                                  ),
                                                );
                                                if (result == true && controller.selectedProject.value != null) {
                                                  await controller.deleteProject(controller.selectedProject.value!);
                                                }
                                              }
                                            : null,
                                        color: Colors.red,
                                      )),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.keyboard_arrow_up,
                                        label: 'Up',
                                        onPressed: controller.selectedProject.value != null
                                            ? () async {
                                                await controller.moveProjectUp(controller.selectedProject.value!);
                                              }
                                            : null,
                                        color: Colors.blue,
                                      )),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.keyboard_arrow_down,
                                        label: 'Down',
                                        onPressed: controller.selectedProject.value != null
                                            ? () async {
                                                await controller.moveProjectDown(controller.selectedProject.value!);
                                              }
                                            : null,
                                        color: Colors.blue,
                                      )),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.article,
                                        label: 'Log',
                                        onPressed: controller.lastGenerateLog.value.isNotEmpty
                                            ? () {
                                                _showLastGenerateLog(controller);
                                              }
                                            : null,
                                        color: Colors.orange,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 输出路径行
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '输出路径:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: Obx(() => TextField(
                                      controller: TextEditingController(text: controller.outputPath.value),
                                      style: const TextStyle(fontSize: 11),
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      ),
                                      readOnly: true,
                                    )),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 28,
                              child: Obx(() => ElevatedButton.icon(
                                    onPressed: controller.selectedProject.value != null
                                        ? () async {
                                            await controller.selectOutputPath();
                                          }
                                        : null,
                                    icon: const Icon(Icons.folder_open, size: 12),
                                    label: const Text('Select', style: TextStyle(fontSize: 10)),
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 下半部分 - 项目项列表区域
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      SizedBox(
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
                            Obx(() {
                              if (controller.selectedProject.value != null) {
                                return Row(
                                  children: [
                                    Chip(
                                      avatar: Icon(
                                        Icons.folder_open,
                                        size: 12,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      ),
                                      label: Text('${controller.currentItems.length}', style: const TextStyle(fontSize: 10)),
                                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 4),
                                    Chip(
                                      avatar: Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      label: Text('${controller.enabledItemsCount}', style: const TextStyle(fontSize: 10)),
                                      backgroundColor: Colors.green.shade100,
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
                                        label: const Text('Add Dirs', style: TextStyle(fontSize: 10)),
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
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: DropTarget(
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
                                      // 表头
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondaryContainer,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            topRight: Radius.circular(6),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Text(
                                                  '启用',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  '目录名',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Center(
                                                child: Text(
                                                  '目录路径',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 项目项列表
                                      Expanded(
                                        child: Obx(() {
                                          return controller.currentItems.isEmpty
                                              ? Center(
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
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount: controller.currentItems.length,
                                                  itemBuilder: (context, index) {
                                                    final item = controller.currentItems[index];
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
                                                            onTap: () => controller.selectItem(item),
                                                            child: Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 1,
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
                                                                  ),
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons.folder,
                                                                          size: 14,
                                                                          color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey.shade600,
                                                                        ),
                                                                        const SizedBox(width: 4),
                                                                        Expanded(
                                                                          child: Text(
                                                                            _getFileName(item.path ?? ''),
                                                                            style: TextStyle(
                                                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                              fontSize: 12,
                                                                              color: isSelected ? Theme.of(context).colorScheme.secondary : null,
                                                                            ),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    flex: 4,
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.only(left: 4),
                                                                      child: Text(
                                                                        item.path ?? '',
                                                                        style: TextStyle(
                                                                          color: Colors.grey.shade700,
                                                                          fontSize: 10,
                                                                        ),
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ), // <-- 修正点：闭合第一个Expanded，并用逗号分隔
                            const SizedBox(width: 8),
                            // 右侧按钮列
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Obx(() => _buildActionButton(
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
                                        color: Colors.red,
                                      )),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.keyboard_arrow_up,
                                        label: 'Up',
                                        onPressed: controller.selectedProject.value != null && controller.selectedItem.value != null
                                            ? () async {
                                                await controller.moveItemUp(controller.selectedItem.value!);
                                              }
                                            : null,
                                        color: Colors.blue,
                                      )),
                                  const SizedBox(height: 4),
                                  Obx(() => _buildActionButton(
                                        icon: Icons.keyboard_arrow_down,
                                        label: 'Down',
                                        onPressed: controller.selectedProject.value != null && controller.selectedItem.value != null
                                            ? () async {
                                                await controller.moveItemDown(controller.selectedItem.value!);
                                              }
                                            : null,
                                        color: Colors.blue,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        return controller.selectedProject.value != null
            ? Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '当前: ${controller.selectedProject.value?.name}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (controller.currentItems.isNotEmpty) ...[
                      Icon(
                        Icons.folder,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${controller.currentItems.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${controller.enabledItemsCount}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : const SizedBox.shrink();
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: onPressed != null ? Colors.white : Colors.grey.shade600,
          elevation: onPressed != null ? 1 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }

  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'txt':
      case 'md':
        return Icons.description;
      case 'cpp':
      case 'c':
      case 'h':
        return Icons.code;
      case 'xml':
      case 'html':
        return Icons.web;
      case 'json':
        return Icons.data_object;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String path) {
    if (path.isEmpty) return '';
    return path.split('/').last.split('\\').last;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// 显示最后一次生成的日志
void _showLastGenerateLog(ProjectController controller) {
  if (controller.lastGenerateLog.value.isEmpty) {
    Get.snackbar('提示', '还没有生成日志');
    return;
  }
  
  Get.dialog(
    Dialog(
      child: Container(
        width: MediaQuery.of(Get.context!).size.width * 0.9,
        height: MediaQuery.of(Get.context!).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text(
                  '最后一次生成日志',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Obx(() => Text(
                    controller.lastGenerateLog.value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  )),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: controller.lastGenerateLog.value));
                    Get.snackbar(
                      '成功',
                      '日志已复制到剪切板',
                      duration: const Duration(seconds: 2),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
