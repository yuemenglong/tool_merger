import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'entity/entity.dart';
import 'dialogs.dart';
import 'controllers/project_controller.dart';
import 'config.dart';
import 'utils/path_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tool Merger',
      theme: _buildAppTheme(),
      home: const ToolMergerHomePage(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
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
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildProjectSection(context, controller),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildItemSection(context, controller),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, controller),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Tool Merger',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      elevation: 0,
      toolbarHeight: 48,
    );
  }

  Widget _buildProjectSection(BuildContext context, ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(context, controller),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildProjectTable(context, controller)),
                  const SizedBox(width: 8),
                  _buildProjectActionButtons(context, controller),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildOutputPathSection(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context, ProjectController controller) {
    return SizedBox(
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
    );
  }

  Widget _buildProjectTable(BuildContext context, ProjectController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          _buildProjectTableHeader(context),
          Expanded(child: _buildProjectTableBody(context, controller)),
        ],
      ),
    );
  }

  Widget _buildProjectTableHeader(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
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
              _buildHeaderCell(context, '操作', 120),
              _buildHeaderCell(context, '项目名称', 150),
              _buildHeaderCell(context, '创建时间', 165),
              _buildHeaderCell(context, '更新时间', 165),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppConfig.secondaryFontSize,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectTableBody(BuildContext context, ProjectController controller) {
    return Obx(() {
      final filteredProjects = controller.filteredProjects;
      return filteredProjects.isEmpty
          ? _buildEmptyProjectState(context)
          : ListView.builder(
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) {
                final project = filteredProjects[index];
                return _buildProjectRow(context, controller, project, index);
              },
            );
    });
  }

  Widget _buildEmptyProjectState(BuildContext context) {
    return Center(
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
              fontSize: AppConfig.statusFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, ProjectController controller, Project project, int index) {
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _buildProjectActionCell(context, controller, project),
                      _buildProjectNameCell(context, project, isSelected),
                      _buildProjectDateCell(context, project.createTime, 165),
                      _buildProjectDateCell(context, project.updateTime, 165),
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

  Widget _buildProjectActionCell(BuildContext context, ProjectController controller, Project project) {
    return SizedBox(
      width: 120,
      child: Center(
        child: SizedBox(
          height: 24,
          child: Obx(() => ElevatedButton.icon(
            onPressed: !controller.isGenerating.value ? () async {
              await controller.generateProject(project);
            } : null,
            icon: const Icon(Icons.build, size: 12),
            label: Text('Gen', style: TextStyle(fontSize: AppConfig.buttonFontSize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.generateButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: const Size(0, 24),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildProjectNameCell(BuildContext context, Project project, bool isSelected) {
    return SizedBox(
      width: 150,
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
                fontSize: AppConfig.primaryFontSize,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDateCell(BuildContext context, DateTime? dateTime, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          _formatDateTime(dateTime),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: AppConfig.secondaryFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectActionButtons(BuildContext context, ProjectController controller) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildGenerateButton(context, controller),
          const SizedBox(height: 8),
          _buildCreateButton(context, controller),
          const SizedBox(height: 4),
          _buildDeleteProjectButton(context, controller),
          const SizedBox(height: 4),
          _buildMoveUpProjectButton(context, controller),
          const SizedBox(height: 4),
          _buildMoveDownProjectButton(context, controller),
          const SizedBox(height: 4),
          _buildStatusButton(context, controller),
          const SizedBox(height: 4),
          _buildLogButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, ProjectController controller) {
    return Obx(() {
      final hasSelectedProject = controller.selectedProject.value != null;
      final hasOutputPath = controller.outputPath.value.isNotEmpty;
      final hasEnabledItems = controller.enabledItemsCount > 0;
      final canGenerate = hasSelectedProject && hasOutputPath && hasEnabledItems;
      
      return SizedBox(
        width: double.infinity,
        height: 84, // 普通按钮高度的3倍
        child: ElevatedButton(
          onPressed: canGenerate && !controller.isGenerating.value
              ? () async {
                  await controller.generateProject();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canGenerate && !controller.isGenerating.value 
                ? Colors.green 
                : Colors.grey.shade300,
            foregroundColor: canGenerate && !controller.isGenerating.value 
                ? Colors.white 
                : Colors.grey.shade600,
            elevation: canGenerate && !controller.isGenerating.value ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: controller.isGenerating.value
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generating...',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GEN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildCreateButton(BuildContext context, ProjectController controller) {
    return _buildActionButton(
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
      color: AppConfig.createButtonColor,
    );
  }

  Widget _buildDeleteProjectButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
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
      color: AppConfig.deleteButtonColor,
    ));
  }

  Widget _buildMoveUpProjectButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
      icon: Icons.keyboard_arrow_up,
      label: 'Up',
      onPressed: controller.selectedProject.value != null
          ? () async {
              await controller.moveProjectUp(controller.selectedProject.value!);
            }
          : null,
      color: AppConfig.moveButtonColor,
    ));
  }

  Widget _buildMoveDownProjectButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
      icon: Icons.keyboard_arrow_down,
      label: 'Down',
      onPressed: controller.selectedProject.value != null
          ? () async {
              await controller.moveProjectDown(controller.selectedProject.value!);
            }
          : null,
      color: AppConfig.moveButtonColor,
    ));
  }

  Widget _buildStatusButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
      icon: Icons.info_outline,
      label: 'Status',
      onPressed: controller.lastGenerateStatus.value != null
          ? () {
              _showGenerateStatus(context, controller);
            }
          : null,
      color: AppConfig.statusButtonColor,
    ));
  }

  Widget _buildLogButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
      icon: Icons.article,
      label: 'Log',
      onPressed: controller.lastGenerateLog.value.isNotEmpty
          ? () {
              _showLastGenerateLog(context, controller);
            }
          : null,
      color: AppConfig.logButtonColor,
    ));
  }

  Widget _buildOutputPathSection(BuildContext context, ProjectController controller) {
    return Container(
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
              fontSize: AppConfig.secondaryFontSize,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 28,
              child: Obx(() => TextField(
                controller: TextEditingController(text: controller.outputPath.value),
                style: TextStyle(fontSize: AppConfig.inputFontSize),
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
              label: Text('Select', style: TextStyle(fontSize: AppConfig.buttonFontSize)),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSection(BuildContext context, ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(context, controller),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildItemTable(context, controller)),
                  const SizedBox(width: 8),
                  _buildItemActionButtons(context, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(BuildContext context, ProjectController controller) {
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
          _buildItemHeaderStats(context, controller),
        ],
      ),
    );
  }

  Widget _buildItemHeaderStats(BuildContext context, ProjectController controller) {
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

  Widget _buildItemTable(BuildContext context, ProjectController controller) {
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
            Expanded(child: _buildItemTableBody(context, controller)),
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
              _buildItemHeaderCell(context, '状态', 80),
              _buildItemHeaderCell(context, '启用', 80),
              _buildItemHeaderCell(context, '目录名', 160),
              _buildItemHeaderCell(context, '目录路径', 280),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemHeaderCell(BuildContext context, String title, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppConfig.secondaryFontSize,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildItemTableBody(BuildContext context, ProjectController controller) {
    return Obx(() {
      return controller.currentItems.isEmpty
          ? _buildEmptyItemState(context, controller)
          : ListView.builder(
              itemCount: controller.currentItems.length,
              itemBuilder: (context, index) {
                final item = controller.currentItems[index];
                return _buildItemRow(context, controller, item, index);
              },
            );
    });
  }

  Widget _buildEmptyItemState(BuildContext context, ProjectController controller) {
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

  Widget _buildItemRow(BuildContext context, ProjectController controller, ProjectItem item, int index) {
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
            onTap: () async {
              controller.selectItem(item);
              await controller.toggleItemEnabled(item);
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _buildItemStatusCell(context, controller, item),
                      _buildItemEnabledCell(context, controller, item),
                      _buildItemNameCell(context, item, isSelected),
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

  Widget _buildItemStatusCell(BuildContext context, ProjectController controller, ProjectItem item) {
    return SizedBox(
      width: 80,
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

  Widget _buildItemEnabledCell(BuildContext context, ProjectController controller, ProjectItem item) {
    return SizedBox(
      width: 80,
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
      width: 160,
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
                fontSize: AppConfig.primaryFontSize,
                color: isSelected ? Theme.of(context).colorScheme.secondary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPathCell(BuildContext context, ProjectItem item) {
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          item.path ?? '',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: AppConfig.secondaryFontSize,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildItemActionButtons(BuildContext context, ProjectController controller) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildDeleteItemButton(context, controller),
          const SizedBox(height: 4),
          _buildMoveUpItemButton(context, controller),
          const SizedBox(height: 4),
          _buildMoveDownItemButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildDeleteItemButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
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

  Widget _buildMoveUpItemButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
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

  Widget _buildMoveDownItemButton(BuildContext context, ProjectController controller) {
    return Obx(() => _buildActionButton(
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

  Widget _buildBottomNavigationBar(BuildContext context, ProjectController controller) {
    return Obx(() {
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
                      fontSize: AppConfig.statusFontSize,
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
                        fontSize: AppConfig.buttonFontSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppConfig.enabledCountColor.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${controller.enabledItemsCount}',
                      style: TextStyle(
                        color: AppConfig.enabledCountColor.shade600,
                        fontSize: AppConfig.buttonFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox.shrink();
    });
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
        label: Text(label, style: TextStyle(fontSize: AppConfig.buttonFontSize)),
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

  void _showLastGenerateLog(BuildContext context, ProjectController controller) {
    // 获取屏幕大小
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.9;

    Get.dialog(
      AlertDialog(
        title: const Text('生成日志'),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: SingleChildScrollView(
            child: Text(
              controller.lastGenerateLog.value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.lastGenerateLog.value));
              Get.snackbar('复制成功', '日志已复制到剪贴板');
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _showGenerateStatus(BuildContext context, ProjectController controller) {
    final status = controller.lastGenerateStatus.value;
    if (status == null) return;

    // 获取屏幕大小
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.9;

    // 计算公共父目录
    final allPaths = status.fileStatuses?.map((fs) => fs.fullPath ?? '').where((path) => path.isNotEmpty).toList() ?? [];
    final commonParent = PathUtils.findCommonParentPath(allPaths);

    Get.dialog(
      AlertDialog(
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
              const Text(
                '文件详情:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                            Expanded(
                              flex: 5,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  '文件路径',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  '后缀',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  '行数',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  '文件大小',
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
                          itemCount: status.fileStatuses?.length ?? 0,
                          itemBuilder: (context, index) {
                            final fileStatus = status.fileStatuses![index];
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
                                        _formatFileSize(fileStatus.fileSize ?? 0),
                                        style: const TextStyle(fontSize: 13),
                                      ),
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
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
