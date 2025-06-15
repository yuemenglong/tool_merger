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
      appBar: AppBar(
        title: Obx(() => Text('后缀设置: ${controller.selectedProject.value?.name ?? ""}')),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('重置为默认'),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('确认重置'),
                  content: const Text('确定要将后缀列表重置为系统默认值吗？此操作不可撤销。'),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
                    ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('确认')),
                  ],
                ),
              );
              if (confirm == true) {
                await controller.resetExtensionsToDefault();
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
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
                  onPressed: () async {
                    await controller.addExtension(addExtController.text);
                    addExtController.clear();
                  },
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: Obx(() {
                final extensions = controller.selectedProject.value?.targetExt ?? [];
                if (extensions.isEmpty) {
                  return const Center(child: Text('没有可配置的后缀'));
                }
                return ListView.builder(
                  itemCount: extensions.length,
                  itemBuilder: (context, index) {
                    final TargetExtension ext = extensions[index];
                    return CheckboxListTile(
                      title: Text(ext.ext),
                      value: ext.enabled,
                      onChanged: (bool? value) async {
                        await controller.toggleExtension(ext);
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await controller.deleteExtension(ext);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}