import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';

class ProjectController extends GetxController {
  // 响应式变量
  final RxList<Project> projects = <Project>[].obs;
  final Rx<Project?> selectedProject = Rx<Project?>(null);
  final RxList<ProjectItem> currentItems = <ProjectItem>[].obs;
  final Rx<ProjectItem?> selectedItem = Rx<ProjectItem?>(null);
  final RxString filterText = ''.obs;
  final RxString outputPath = ''.obs;

  // 过滤后的项目列表
  List<Project> get filteredProjects {
    List<Project> result;
    if (filterText.value.isEmpty) {
      result = projects.toList();
    } else {
      result = projects.where((project) => 
        project.name?.toLowerCase().contains(filterText.value.toLowerCase()) ?? false
      ).toList();
    }
    // 按sortOrder排序
    result.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  // 加载项目数据
  Future<void> loadProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/projects.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        projects.value = jsonList.map((json) => Project.fromJson(json)).toList();
      } else {
        // 如果文件不存在，创建示例数据
        _createSampleData();
      }
    } catch (e) {
      Get.snackbar('错误', '加载项目失败: $e');
      _createSampleData();
    }
  }

  // 保存项目数据
  Future<void> saveProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/projects.json');
      
      final jsonList = projects.map((project) => project.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      Get.snackbar('错误', '保存项目失败: $e');
    }
  }

  // 创建示例数据
  void _createSampleData() {
    projects.value = [
      Project(
        name: '示例项目1',
        outputPath: '/path/to/output1',
        sortOrder: 0,
        createTime: DateTime.now().subtract(const Duration(days: 2)),
        updateTime: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          ProjectItem(
            name: 'file1.txt',
            path: '/path/to/file1.txt',
            enabled: true,
            sortOrder: 0,
          ),
          ProjectItem(
            name: 'file2.cpp',
            path: '/path/to/file2.cpp',
            enabled: false,
            sortOrder: 1,
          ),
        ],
      ),
      Project(
        name: '示例项目2',
        outputPath: '/path/to/output2',
        sortOrder: 1,
        createTime: DateTime.now().subtract(const Duration(days: 1)),
        updateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          ProjectItem(
            name: 'document.md',
            path: '/path/to/document.md',
            enabled: true,
            sortOrder: 0,
          ),
        ],
      ),
    ];
  }

  // 选择项目
  void selectProject(Project project) {
    selectedProject.value = project;
    final items = project.items ?? [];
    // 按sortOrder排序
    items.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    currentItems.value = items;
    selectedItem.value = null;
    outputPath.value = project.outputPath ?? '';
  }

  // 创建项目
  Future<void> createProject(String name) async {
    final newProject = Project(
      name: name,
      outputPath: '',
      sortOrder: projects.length,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      items: [],
    );
    
    projects.add(newProject);
    await saveProjects();
    selectProject(newProject);
    
    Get.snackbar('成功', '项目 "$name" 创建成功');
  }

  // 删除项目
  Future<void> deleteProject(Project project) async {
    projects.remove(project);
    
    // 重新排序
    for (int i = 0; i < projects.length; i++) {
      projects[i].sortOrder = i;
    }
    
    if (selectedProject.value == project) {
      selectedProject.value = null;
      currentItems.clear();
      selectedItem.value = null;
      outputPath.value = '';
    }
    
    await saveProjects();
    Get.snackbar('成功', '项目已删除');
  }

  // 向上移动项目
  Future<void> moveProjectUp(Project project) async {
    final index = projects.indexOf(project);
    if (index > 0) {
      projects.removeAt(index);
      projects.insert(index - 1, project);
      
      // 重新排序
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  // 向下移动项目
  Future<void> moveProjectDown(Project project) async {
    final index = projects.indexOf(project);
    if (index < projects.length - 1) {
      projects.removeAt(index);
      projects.insert(index + 1, project);
      
      // 重新排序
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  // 选择输出路径
  Future<void> selectOutputPath() async {
    if (selectedProject.value == null) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      selectedProject.value!.outputPath = selectedDirectory;
      outputPath.value = selectedDirectory;
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 添加文件到项目
  Future<void> addFilesToProject(FilePickerResult result) async {
    if (selectedProject.value == null) return;
    
    int addedCount = 0;
    for (var file in result.files) {
      if (file.path != null) {
        final fileName = file.name;
        final filePath = file.path!;
        
        // 检查是否已存在
        final exists = currentItems.any((item) => item.path == filePath);
        if (!exists) {
          final newItem = ProjectItem(
            name: fileName,
            path: filePath,
            enabled: true,
            sortOrder: currentItems.length,
          );
          
          currentItems.add(newItem);
          selectedProject.value!.items = currentItems.toList();
          selectedProject.value!.updateTime = DateTime.now();
          addedCount++;
        }
      }
    }
    
    await saveProjects();
    if (addedCount > 0) {
      Get.snackbar('成功', '已添加 $addedCount 个文件');
    } else {
      Get.snackbar('提示', '所选文件已存在于项目中');
    }
  }

  // 选择项目项
  void selectItem(ProjectItem item) {
    selectedItem.value = item;
  }

  // 切换项目项启用状态
  Future<void> toggleItemEnabled(ProjectItem item) async {
    item.enabled = !(item.enabled ?? false);
    selectedProject.value!.updateTime = DateTime.now();
    await saveProjects();
  }

  // 删除项目项
  Future<void> deleteItem(ProjectItem item) async {
    currentItems.remove(item);
    selectedProject.value!.items = currentItems.toList();
    
    // 重新排序
    for (int i = 0; i < currentItems.length; i++) {
      currentItems[i].sortOrder = i;
    }
    
    if (selectedItem.value == item) {
      selectedItem.value = null;
    }
    
    selectedProject.value!.updateTime = DateTime.now();
    await saveProjects();
    Get.snackbar('成功', '文件已删除');
  }

  // 向上移动项目项
  Future<void> moveItemUp(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index > 0) {
      currentItems.removeAt(index);
      currentItems.insert(index - 1, item);
      
      // 重新排序
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      selectedProject.value!.items = currentItems.toList();
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 向下移动项目项
  Future<void> moveItemDown(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index < currentItems.length - 1) {
      currentItems.removeAt(index);
      currentItems.insert(index + 1, item);
      
      // 重新排序
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      selectedProject.value!.items = currentItems.toList();
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 设置过滤文本
  void setFilterText(String text) {
    filterText.value = text;
  }

  // 获取启用的项目项数量
  int get enabledItemsCount {
    return currentItems.where((item) => item.enabled == true).length;
  }

  // 处理拖拽文件
  Future<void> handleDroppedFiles(List<XFile> files) async {
    if (selectedProject.value == null) {
      Get.snackbar('提示', '请先选择一个项目');
      return;
    }
    
    int addedCount = 0;
    for (var file in files) {
      final fileName = file.name;
      final filePath = file.path;
      
      // 检查是否已存在
      final exists = currentItems.any((item) => item.path == filePath);
      if (!exists) {
        final newItem = ProjectItem(
          name: fileName,
          path: filePath,
          enabled: true,
          sortOrder: currentItems.length,
        );
        
        currentItems.add(newItem);
        selectedProject.value!.items = currentItems.toList();
        selectedProject.value!.updateTime = DateTime.now();
        addedCount++;
      }
    }
    
    await saveProjects();
    if (addedCount > 0) {
      Get.snackbar('成功', '已添加 $addedCount 个文件');
    } else {
      Get.snackbar('提示', '所选文件已存在于项目中');
    }
  }

  // 生成项目合并文件
  Future<void> generateProject() async {
    if (selectedProject.value == null) {
      Get.snackbar('错误', '请先选择一个项目');
      return;
    }

    final project = selectedProject.value!;
    if (project.outputPath == null || project.outputPath!.isEmpty) {
      Get.snackbar('错误', '请先设置输出路径');
      return;
    }

    final enabledItems = currentItems.where((item) => item.enabled == true).toList();
    if (enabledItems.isEmpty) {
      Get.snackbar('错误', '没有启用的文件');
      return;
    }

    try {
      // 显示开始生成的提示
      Get.snackbar('提示', '开始生成文件，共 ${enabledItems.length} 个文件...');
      
      // 创建输出文件路径
      final outputDir = Directory(project.outputPath!);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final outputFile = File('${project.outputPath}/${project.name}.xml');
      
      // 使用 XmlMerger 生成 XML 内容
      final xmlContent = await XmlMerger.mergeXml(project);
      
      // 写入文件
      await outputFile.writeAsString(xmlContent, encoding: utf8);
      
      // 更新项目时间并保存
      project.updateTime = DateTime.now();
      await saveProjects();
      
      Get.snackbar(
        '成功', 
        '文件生成成功!\n路径: ${outputFile.path}\n大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('错误', '生成文件失败: $e');
    }
  }


} 