import 'package:get/get.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';
import '../views/extension_settings_page.dart';
import 'project_data_controller.dart';

class ProjectExtensionController extends GetxController {
  ProjectDataController get _dataController => Get.find<ProjectDataController>(tag: 'projectData');

  void openExtensionSettings() {
    if (_dataController.selectedProject.value != null) {
      Get.to(() => const ExtensionSettingsPage());
    }
  }

  Future<void> toggleExtension(TargetExtension ext) async {
    if (_dataController.selectedProject.value == null) return;
    
    ext.enabled = !ext.enabled;
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    _dataController.selectedProject.refresh();
    _dataController.projects.refresh();
    await _dataController.saveProjects();
  }

  Future<void> addExtension(String newExt) async {
    if (_dataController.selectedProject.value == null || newExt.trim().isEmpty) return;

    String processedExt = newExt.trim().toLowerCase();
    if (!processedExt.startsWith('.')) {
      processedExt = '.$processedExt';
    }

    final exists = _dataController.selectedProject.value!.targetExt?.any((e) => e.ext == processedExt) ?? false;
    if (exists) {
      Get.snackbar('错误', '后缀 "$processedExt" 已存在', duration: const Duration(seconds: 1));
      return;
    }

    _dataController.selectedProject.value!.targetExt?.add(TargetExtension(ext: processedExt, enabled: true));
    _dataController.selectedProject.value!.targetExt?.sort((a, b) => a.ext.compareTo(b.ext));
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    _dataController.selectedProject.refresh();
    _dataController.projects.refresh();
    await _dataController.saveProjects();
    Get.snackbar('成功', '已添加后缀 "$processedExt"', duration: const Duration(seconds: 1));
  }

  Future<void> deleteExtension(TargetExtension ext) async {
    if (_dataController.selectedProject.value == null) return;
    
    _dataController.selectedProject.value!.targetExt?.remove(ext);
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    _dataController.selectedProject.refresh();
    _dataController.projects.refresh();
    await _dataController.saveProjects();
  }

  Future<void> resetExtensionsToDefault() async {
    if (_dataController.selectedProject.value == null) return;
    
    _populateDefaultExtensions(_dataController.selectedProject.value!);
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    _dataController.selectedProject.refresh();
    _dataController.projects.refresh();
    await _dataController.saveProjects();
    Get.snackbar('成功', '已重置为默认后缀列表', duration: const Duration(seconds: 1));
  }

  void _populateDefaultExtensions(Project project) {
    project.targetExt = XmlMerger.targetExt
        .map((ext) => TargetExtension(ext: ext, enabled: true))
        .toList();
    project.targetExt?.sort((a, b) => a.ext.compareTo(b.ext));
  }
}