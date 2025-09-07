import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../controllers/project_controller.dart';
import '../entity/entity.dart';
import '../config.dart';
import '../dialogs.dart';
import 'widgets/common_widgets.dart';
import 'dialogs/file_status_dialog.dart';

class ProjectSectionView extends StatelessWidget {
  final ProjectController controller;
  
  const ProjectSectionView({
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
            _buildProjectHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildProjectTable(context)),
                  const SizedBox(width: 8),
                  _buildProjectActionButtons(context),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildOutputPathSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context) {
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

  Widget _buildProjectTable(BuildContext context) {
    // 核心改动：用 DropTarget 包裹起来
    return DropTarget(
      onDragDone: (detail) async {
        // 调用一个新的 Controller 方法来处理这个特殊的拖拽创建逻辑
        await controller.handleProjectDropAndCreate(detail.files);
      },
      child: Container( // 原本的 Container 成为 DropTarget 的子组件
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            _buildProjectTableHeader(context),
            Expanded(child: _buildProjectTableBody(context)),
          ],
        ),
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
              CommonWidgets.buildHeaderCell(context, '操作', 120),
              CommonWidgets.buildHeaderCell(context, '项目名称', 150),
              CommonWidgets.buildHeaderCell(context, '创建时间', 165),
              CommonWidgets.buildHeaderCell(context, '更新时间', 165),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectTableBody(BuildContext context) {
    return Obx(() {
      final filteredProjects = controller.filteredProjects;
      return filteredProjects.isEmpty
          ? _buildEmptyProjectState(context)
          : ListView.builder(
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) {
                final project = filteredProjects[index];
                return _buildProjectRow(context, project, index);
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

  Widget _buildProjectRow(BuildContext context, Project project, int index) {
    return Obx(() {
      final isSelected = controller.selectedProject.value == project;
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey.shade200
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
                      _buildProjectActionCell(context, project),
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

  Widget _buildProjectActionCell(BuildContext context, Project project) {
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
          CommonWidgets.formatDateTime(dateTime),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: AppConfig.secondaryFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectActionButtons(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildGenerateButton(context),
          const SizedBox(height: 8),
          _buildCreateButton(context),
          const SizedBox(height: 4),
          _buildSettingsButton(context), // 新增设置按钮
          const SizedBox(height: 4),
          _buildDeleteProjectButton(context),
          const SizedBox(height: 4),
          _buildMoveUpProjectButton(context),
          const SizedBox(height: 4),
          _buildMoveDownProjectButton(context),
          const SizedBox(height: 4),
          _buildStatusButton(context),
          const SizedBox(height: 4),
          _buildLogButton(context),
        ],
      ),
    );
  }

  // 新增：后缀设置按钮
  Widget _buildSettingsButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.settings,
      label: 'Settings',
      onPressed: controller.selectedProject.value != null
          ? () {
              controller.openExtensionSettings();
            }
          : null,
      color: Colors.orange,
    ));
  }

  Widget _buildGenerateButton(BuildContext context) {
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

  Widget _buildCreateButton(BuildContext context) {
    return CommonWidgets.buildActionButton(
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

  Widget _buildDeleteProjectButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
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

  Widget _buildMoveUpProjectButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
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

  Widget _buildMoveDownProjectButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
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

  Widget _buildStatusButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.info_outline,
      label: 'Status',
      onPressed: controller.lastGenerateStatus.value != null
          ? () {
              _showGenerateStatus(context);
            }
          : null,
      color: AppConfig.statusButtonColor,
    ));
  }

  Widget _buildLogButton(BuildContext context) {
    return Obx(() => CommonWidgets.buildActionButton(
      icon: Icons.article,
      label: 'Log',
      onPressed: controller.lastGenerateLog.value.isNotEmpty
          ? () {
              _showLastGenerateLog(context);
            }
          : null,
      color: AppConfig.logButtonColor,
    ));
  }

  Widget _buildOutputPathSection(BuildContext context) {
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

  void _showLastGenerateLog(BuildContext context) {
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
            child: SelectableText(
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

  void _showGenerateStatus(BuildContext context) {
    final status = controller.lastGenerateStatus.value;
    if (status == null) return;

    Get.dialog(
      const SortableFileStatusDialog(),
      arguments: status,
    );
  }
}