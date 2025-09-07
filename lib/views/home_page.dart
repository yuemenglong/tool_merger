import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/project_controller.dart';
import '../config.dart';
import 'project_section_view.dart';
import 'item_section_view.dart';

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
              child: ProjectSectionView(controller: controller),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: ItemSectionView(controller: controller),
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
}