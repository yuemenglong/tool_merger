import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/project_controller.dart';
import '../entity/entity.dart';

class ExtensionSettingsPage extends StatelessWidget {
  const ExtensionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectController controller = Get.find();
    final TextEditingController addExtController = TextEditingController();

    return Scaffold(
      appBar: _buildAppBar(controller),
      body: _buildBody(controller, addExtController),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar(ProjectController controller) {
    return AppBar(
      title: Obx(() => Text('后缀设置: ${controller.selectedProject.value?.name ?? ""}')),
      actions: [
        _buildResetButton(controller),
      ],
    );
  }

  /// 构建重置按钮
  Widget _buildResetButton(ProjectController controller) {
    return TextButton.icon(
      icon: const Icon(Icons.sync),
      label: const Text('重置为默认'),
      onPressed: () => _handleResetToDefault(controller),
    );
  }

  /// 处理重置为默认值
  Future<void> _handleResetToDefault(ProjectController controller) async {
    final confirm = await _showResetConfirmDialog();
    if (confirm == true) {
      await controller.resetExtensionsToDefault();
    }
  }

  /// 显示重置确认对话框
  Future<bool?> _showResetConfirmDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要将后缀列表重置为系统默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody(ProjectController controller, TextEditingController addExtController) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAddExtensionRow(controller, addExtController),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: _buildExtensionsList(controller),
          ),
        ],
      ),
    );
  }

  /// 构建添加后缀输入行
  Widget _buildAddExtensionRow(ProjectController controller, TextEditingController addExtController) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: addExtController,
            decoration: const InputDecoration(
              labelText: '添加新后缀',
              hintText: '例如: .xml 或 xml',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _handleAddExtension(controller, addExtController),
          child: const Text('添加'),
        ),
      ],
    );
  }

  /// 处理添加后缀
  Future<void> _handleAddExtension(ProjectController controller, TextEditingController addExtController) async {
    await controller.addExtension(addExtController.text);
    addExtController.clear();
  }

  /// 构建后缀列表
  Widget _buildExtensionsList(ProjectController controller) {
    return Obx(() {
      final extensions = controller.selectedProject.value?.targetExt ?? [];
      if (extensions.isEmpty) {
        return const Center(child: Text('没有可配置的后缀'));
      }
      
      return _buildExtensionsGrid(extensions, controller);
    });
  }

  /// 构建后缀网格布局
  Widget _buildExtensionsGrid(List<TargetExtension> extensions, ProjectController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int columns = 4;
        final double itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        final int rows = (extensions.length / columns).ceil();
        
        return SingleChildScrollView(
          child: Column(
            children: List.generate(rows, (rowIndex) {
              return _buildExtensionRow(
                rowIndex,
                columns,
                itemWidth,
                extensions,
                controller,
              );
            }),
          ),
        );
      },
    );
  }

  /// 构建后缀行
  Widget _buildExtensionRow(
    int rowIndex,
    int columns,
    double itemWidth,
    List<TargetExtension> extensions,
    ProjectController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: List.generate(columns, (colIndex) {
          final int index = rowIndex * columns + colIndex;
          if (index >= extensions.length) {
            return SizedBox(width: itemWidth);
          }
          
          final TargetExtension ext = extensions[index];
          return _buildExtensionCard(
            ext,
            itemWidth,
            colIndex,
            columns,
            controller,
          );
        }),
      ),
    );
  }

  /// 构建单个后缀卡片
  Widget _buildExtensionCard(
    TargetExtension ext,
    double itemWidth,
    int colIndex,
    int columns,
    ProjectController controller,
  ) {
    return SizedBox(
      width: itemWidth,
      child: Padding(
        padding: EdgeInsets.only(right: colIndex < columns - 1 ? 8.0 : 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildExtensionCheckbox(ext, controller),
                _buildExtensionText(ext),
                _buildDeleteButton(ext, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建后缀复选框
  Widget _buildExtensionCheckbox(TargetExtension ext, ProjectController controller) {
    return Checkbox(
      value: ext.enabled,
      onChanged: (bool? value) async {
        await controller.toggleExtension(ext);
      },
    );
  }

  /// 构建后缀文本
  Widget _buildExtensionText(TargetExtension ext) {
    return Expanded(
      child: Text(
        ext.ext,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建删除按钮
  Widget _buildDeleteButton(TargetExtension ext, ProjectController controller) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
      onPressed: () async {
        await controller.deleteExtension(ext);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}