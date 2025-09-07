import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';
import 'project_data_controller.dart';

class ProjectItemController extends GetxController {
  final RxList<ProjectItem> currentItems = <ProjectItem>[].obs;
  final Rx<ProjectItem?> selectedItem = Rx<ProjectItem?>(null);
  
  ProjectDataController get _dataController => Get.find<ProjectDataController>(tag: 'projectData');

  void loadProjectItems() {
    final project = _dataController.selectedProject.value;
    if (project != null) {
      final items = project.items ?? [];
      items.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
      currentItems.value = items;
      selectedItem.value = null;
    } else {
      currentItems.clear();
      selectedItem.value = null;
    }
  }

  int get enabledItemsCount {
    return currentItems.where((item) => item.enabled == true).length;
  }

  Future<void> addDirectoriesToProject() async {
    if (_dataController.selectedProject.value == null) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      final dirName = selectedDirectory.split(RegExp(r'[/\\]')).last;
      
      final exists = currentItems.any((item) => item.path == selectedDirectory);
      if (!exists) {
        final newItem = ProjectItem(
          name: dirName,
          path: selectedDirectory,
          enabled: true,
          sortOrder: currentItems.length,
          fileType: ProjectFileType.local,
        );
        
        currentItems.add(newItem);
        _dataController.selectedProject.value!.items = currentItems.toList();
        _dataController.selectedProject.value!.updateTime = DateTime.now();
        
        await _dataController.saveProjects();
        
        String message = '已添加目录: $dirName';
        if (XmlMerger.shouldIgnorePath(selectedDirectory)) {
          message += '\n提示: 此目录路径可能应该被忽略';
        }
        
        Get.snackbar('成功', message, duration: const Duration(seconds: 3));
      } else {
        Get.snackbar('提示', '所选目录已存在于项目中');
      }
    }
  }

  Future<void> addFilesToProject() async {
    if (_dataController.selectedProject.value == null) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    
    if (result != null) {
      int addedCount = 0;
      
      for (var file in result.files) {
        if (file.path != null) {
          final fileName = file.name;
          final filePath = file.path!;
          
          final exists = currentItems.any((item) => item.path == filePath);
          if (!exists) {
            final newItem = ProjectItem(
              name: fileName,
              path: filePath,
              enabled: true,
              sortOrder: currentItems.length,
              isExclude: false,
              fileType: ProjectFileType.local,
            );
            
            currentItems.add(newItem);
            _dataController.selectedProject.value!.items = currentItems.toList();
            _dataController.selectedProject.value!.updateTime = DateTime.now();
            addedCount++;
          }
        }
      }
      
      await _dataController.saveProjects();
      
      if (addedCount > 0) {
        Get.snackbar('成功', '已添加 $addedCount 个文件', duration: const Duration(seconds: 3));
      } else {
        Get.snackbar('提示', '所选文件已存在于项目中');
      }
    }
  }

  void selectItem(ProjectItem item) {
    selectedItem.value = item;
  }

  Future<void> toggleItemEnabled(ProjectItem item) async {
    item.enabled = !(item.enabled ?? false);
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    
    currentItems.refresh();
    await _dataController.saveProjects();
  }

  Future<void> toggleItemExclude(ProjectItem item) async {
    item.isExclude = !(item.isExclude ?? false);
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    
    currentItems.refresh();
    await _dataController.saveProjects();
  }

  Future<void> deleteItem(ProjectItem item) async {
    currentItems.remove(item);
    _dataController.selectedProject.value!.items = currentItems.toList();
    
    for (int i = 0; i < currentItems.length; i++) {
      currentItems[i].sortOrder = i;
    }
    
    if (selectedItem.value == item) {
      selectedItem.value = null;
    }
    
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    await _dataController.saveProjects();
    Get.snackbar('成功', '文件已删除');
  }

  Future<void> moveItemUp(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index > 0) {
      currentItems.removeAt(index);
      currentItems.insert(index - 1, item);
      
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      _dataController.selectedProject.value!.items = currentItems.toList();
      _dataController.selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();
    }
  }

  Future<void> moveItemDown(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index < currentItems.length - 1) {
      currentItems.removeAt(index);
      currentItems.insert(index + 1, item);
      
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      _dataController.selectedProject.value!.items = currentItems.toList();
      _dataController.selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();
    }
  }

  Future<void> handleDroppedFiles(List<XFile> files) async {
    if (_dataController.selectedProject.value == null) {
      Get.snackbar('提示', '请先选择一个项目');
      return;
    }

    int addedCount = 0;
    int ignoredCount = 0;

    for (var file in files) {
      final fileName = file.name;
      final filePath = file.path;

      final exists = currentItems.any((item) => item.path == filePath);
      if (!exists) {
        final newItem = ProjectItem(
          name: fileName,
          path: filePath,
          enabled: true,
          sortOrder: currentItems.length,
          isExclude: false,
          fileType: ProjectFileType.local,
        );

        currentItems.add(newItem);
        addedCount++;

        if (XmlMerger.shouldIgnorePath(filePath)) {
          ignoredCount++;
        }
      }
    }

    if (addedCount > 0) {
      _dataController.selectedProject.value!.items = currentItems.toList();
      _dataController.selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();

      String message = '已添加 $addedCount 个项目 (文件/目录)';
      if (ignoredCount > 0) {
        message += '\n其中 $ignoredCount 个路径可能应该被忽略';
      }
      Get.snackbar('成功', message, duration: const Duration(seconds: 4));
    } else {
      Get.snackbar('提示', '所选项目均已存在');
    }
  }

  Future<void> addItemFromFileStatus(FileStatusInfo fileStatus) async {
    if (_dataController.selectedProject.value == null) {
      Get.snackbar('操作失败', '请先选择一个项目。');
      return;
    }

    final filePath = fileStatus.fullPath;
    if (filePath == null || filePath.isEmpty) {
      Get.snackbar('错误', '无效的文件路径。');
      return;
    }

    final exists = currentItems.any((item) => item.path == filePath);
    if (exists) {
      Get.snackbar('提示', '该文件已存在于当前项目中。');
      return;
    }

    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final newItem = ProjectItem(
      name: fileName,
      path: filePath,
      enabled: true,
      sortOrder: currentItems.length,
      isExclude: false,
      fileType: ProjectFileType.local,
    );

    currentItems.add(newItem);
    _dataController.selectedProject.value!.items = currentItems.toList();
    _dataController.selectedProject.value!.updateTime = DateTime.now();
    await _dataController.saveProjects();

    Get.snackbar('成功', '文件 "$fileName" 已添加到当前项目。');
  }
}